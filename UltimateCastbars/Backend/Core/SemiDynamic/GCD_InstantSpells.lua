local ADDON_NAME, UCB = ...

UCB.GCD = UCB.GCD or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.tags     = UCB.tags     or {}
UCB.GeneralCore_Helpers = UCB.GeneralCore_Helpers or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.Latency = UCB.Latency or {}

local CASTBAR_API = UCB.CASTBAR_API
local tags = UCB.tags
local GeneralHelpers = UCB.GeneralCore_Helpers
local Latency = UCB.Latency
local GCD = UCB.GCD
local BarUpdate_API = UCB.BarUpdate_API

GCD.pendingSent = nil       -- from UNIT_SPELLCAST_SENT
GCD.pendingReal = nil       -- from START / CHANNEL_START / EMPOWER_START
GCD.lastStarted = nil       -- last real cast started
GCD.active = nil            -- currently active GCD owner
GCD.activeEmpower = nil
GCD.pendingEmpowerGCD = nil
GCD.activeGCDSpellID = nil
GCD.activeGCDKind = nil
GCD.instant = false
GCD.pendingSucceeded = nil  -- instant/proc fallback candidate from SUCCEEDED


------------------------------------------------------------------------------------------
local function ApplyStyleInstant(bar, unit, cfg, spellID, castType, bar_status)
    local styleCFG = cfg.styleCastType.general
    local otherCFG = cfg.otherFeatures
    local instantGCDFCFG = otherCFG and otherCFG.instantGCD
    local styleCastTypeCFG = cfg.styleCastType
    local updateKey = "general"

    -- Base style priority:
    -- 1. General, or preConfigureStyle if general-only mode is off
    -- 2. Instant GCD custom style
    -- 3. Per-spell instant style
    if styleCastTypeCFG and not styleCastTypeCFG.useGeneralStyle then
        local preKey = instantGCDFCFG and instantGCDFCFG.preConfigureStyle or "general"
        styleCFG = styleCastTypeCFG[preKey] or styleCastTypeCFG.general
        updateKey = preKey
    else
        styleCFG = styleCastTypeCFG.general
        updateKey = "general"
    end

    if instantGCDFCFG and instantGCDFCFG.useCustomStyle and instantGCDFCFG.customStyle then
        styleCFG = instantGCDFCFG.customStyle
        updateKey = "instantGCD"
    end

    if UCB:IsPlayer(unit) then
        local classCFG = cfg.CLASSES[UCB.className]
        local spellStyling = classCFG and classCFG.spellStyling

        if spellStyling and spellStyling.useStyleSpell then
            if spellStyling._customInstantSpellStyles and spellStyling._customInstantSpellStyles[spellID] then
                styleCFG = spellStyling._customInstantSpellStyles[spellID]
                updateKey = "instant_" .. spellID
            end
        end
    end

    BarUpdate_API:RefreshBarStyleOnly(unit, styleCFG)
    BarUpdate_API:UpdateStyle(unit, true, updateKey, styleCFG)

    if styleCFG.effects.spark.enable then
        local spark = bar.effects.spark
        local driver = bar.effects.sparkDriver

        bar.effects.spark:Show()
        spark:ClearAllPoints()

        if otherCFG.mirrorBar[castType] then
            driver:Show()
            driver:SetMinMaxValues(bar_status:GetMinMaxValues())
            driver:SetValue(bar_status:GetValue())
            spark:SetPoint("CENTER", driver:GetStatusBarTexture(), "RIGHT", 0, 0)
        else
            driver:Hide()
            spark:SetPoint("CENTER", bar_status:GetStatusBarTexture(), "RIGHT", 0, 0)
        end
    end

    bar.cfg_style = styleCFG
end

local function GCDBarOnUpdate(bar, elapsed)
  local vars = bar._ucbVars
  if not vars or not vars.gcdDurObj then
    bar:SetScript("OnUpdate", nil)
    return
  end

  local remain = vars.gcdDurObj:GetRemainingDuration() or 0
  if remain <= 0 then
    CASTBAR_API:StopPrevCast("player", bar, nil, nil, nil)
    bar.group:Hide()
    bar:SetScript("OnUpdate", nil)
    bar.flags.gcdActive = false
    bar.flags.prevType = nil
    bar.current_spellID = nil
    bar._ucbUnit, bar._ucbCfg, bar._ucbCastType, bar._ucbVars, bar._ucbSpellID = nil, nil, nil, nil, nil
    GCD.activeGCDSpellID = nil
    GCD.activeGCDKind = nil
    GCD.active = nil
    GCD.instant = false

    return
  end

  -- Feed the normal updater with GCD-backed timestamps
  local now = GetTime()
  vars.startTime = now - ((vars.dTime or 0) - remain)
  vars.endTime = now + remain

  UCB.CASTBAR_API:CastBar_OnUpdate(bar, elapsed, bar._ucbUnit, bar._ucbCfg, "gcd", bar._ucbCastType, vars)
end

function GCD:InstantSpellGCDBar(spellID, gcdDurObj)
  if not spellID or not gcdDurObj then
    return
  end

  local unit = "player"
  local bar = UCB.castBar and UCB.castBar[unit]
  if not bar then
    return
  end

  local mainCFG = UCB.GetValueConfig()
  local cfg = mainCFG and mainCFG[unit]
  if not cfg then
    return
  end

  -- Resolve GCD duration
  local gcdDuration = 0
  if gcdDurObj.GetRemainingDuration then
    gcdDuration = gcdDurObj:GetRemainingDuration() or 0
  end

  if gcdDuration <= 0 then
    return
  end

  -- Kill any previous temp cast state
  CASTBAR_API:StopPrevCast(unit, bar, nil, nil, nil)
  CASTBAR_API:StopFrameTimer(bar, "cancelled")
  CASTBAR_API:StopFrameTimer(bar, "interrupted")
  CASTBAR_API:HideChannelTicks(bar, cfg.otherFeatures)
  CASTBAR_API:HideStages(bar)

  bar.current_spellID = spellID

  -- Minimal vars table shaped like a cast vars object
  local vars = tags.var and tags.var[unit] or {}
  tags.var[unit] = vars

  vars.spellID = spellID
  vars.castType = "normal"
  vars.dTime = gcdDuration
  vars.startTime = GetTime()
  vars.endTime = vars.startTime + gcdDuration
  vars.nIntr = false
  vars.notInterruptible = false
  vars.gcdDurObj = gcdDurObj

  local iconTexture = C_Spell.GetSpellTexture(spellID)
  if type(iconTexture) == "table" then
    iconTexture = iconTexture.fileID or iconTexture.iconFileID
  end
  bar.icon:SetTexture(iconTexture)

  -- Optional: update text/tags if your tag system expects preview-style vars
  if tags.updateVarsPreview then
    pcall(tags.updateVarsPreview, tags, unit, cfg, "normal", spellID, gcdDuration, false, nil, 0)
    vars = tags.var[unit] or vars
    vars.gcdDurObj = gcdDurObj
    vars.dTime = gcdDuration
    vars.castType = "normal"
  end

  if tags.setTextSameState then
    pcall(tags.setTextSameState, tags, bar, "gcd", "semiDynamic", unit, "any", false)
    pcall(tags.setTextSameState, tags, bar, "gcd", "dynamic", unit, "any", true)
  end

  local bar_status = bar.status
  bar_status:SetMinMaxValues(0, vars.dTime)

  CASTBAR_API:MirrorBar(cfg, bar, "normal")
  CASTBAR_API:InitCastbarVal(bar_status, "normal", false, vars, cfg.otherFeatures)

  CASTBAR_API:AssignQueueWindow(unit, cfg, "gcd")
  local latencyOverlay = bar.latencyOverlay
  if latencyOverlay then latencyOverlay:Hide() end

  -- Reuse your normal cast styling
  ApplyStyleInstant(bar, unit, cfg, spellID, "normal", bar_status)
  CASTBAR_API:UninterruptibleCast(bar, bar_status, vars)
  CASTBAR_API:InterruptibleTick(bar, unit, bar_status, vars, cfg, "normal")
  CASTBAR_API:SemiColourUpdate(unit, bar)

  -- Optional: show GCD swipe if your style supports it
  if bar.iconSwipe and cfg.cfg_style and cfg.cfg_style.effects and cfg.cfg_style.effects.gcd and cfg.cfg_style.effects.gcd.enable then
    pcall(function()
      bar.iconSwipe:SetCooldownFromDurationObject(gcdDurObj, true)
    end)
  end

  bar.gate_effects:SetAlpha(1)
  bar.group:SetAlpha(1)
  bar:SetAlpha(1)

  bar.group:Show()
  bar.flags.prevType = "normal"
  bar.flags.gcdActive = true

  bar._ucbUnit = unit
  bar._ucbCfg = cfg
  bar._ucbCastType = "normal"
  bar._ucbVars = vars
  bar._ucbSpellID = spellID

  bar:SetScript("OnUpdate", GCDBarOnUpdate)

  CASTBAR_API:HideCastbar(bar, unit, vars, cfg)
end


function GCD:HandleInstantGCD(spellID, gcdDurObj, record)
  self.active = record
  self.activeGCDSpellID = spellID
  self.activeGCDKind = "instant"
  self.instant = true

  local bar = UCB.castBar and UCB.castBar.player
  if bar and bar.cfg and bar.cfg.otherFeatures.instantGCD.enable then
    GCD:InstantSpellGCDBar(spellID, gcdDurObj)
  else
    GCD.activeGCDSpellID = nil
    GCD.activeGCDKind = nil
    GCD.active = nil
    GCD.instant = false
  end

  if type(self.InstantGCDCallback) == "function" then
    pcall(self.InstantGCDCallback, self, spellID, gcdDurObj, record)
  end
end


---------------------------------------------------------------------------------------
local function GetGCDDuration()
  local ok, durObj = pcall(C_Spell.GetSpellCooldownDuration, UCB.GCDSpellID)
  if ok and durObj then
    return durObj
  end

  return nil
end

local function IsGlobalGCDActive()
  local ok, info = pcall(C_Spell.GetSpellCooldown, UCB.GCDSpellID)
  if not ok or not info then
    return false
  end

  local remain = info.timeUntilEndOfStartRecovery
  return type(remain) == "number" and remain > 0
end

local function IsSpellOnBaseGCD(spellID)
  if not spellID then
    return false
  end

  local ok, baseCDMS, gcdMS = pcall(GetSpellBaseCooldown, spellID)
  if not ok then
    return false
  end

  return (gcdMS or 0) > 0
end

local function IsRecent(at, window)
  return type(at) == "number" and (GetTime() - at) >= 0 and (GetTime() - at) <= window
end

local function SameCast(rec, castGUID, spellID)
  if not rec then
    return false
  end

  if castGUID and rec.castGUID and rec.castGUID == castGUID then
    return true
  end

  if spellID and rec.spellID and rec.spellID == tonumber(spellID) then
    return true
  end

  return false
end

local function IsPlayerCastingLike()
  if UnitCastingInfo and UnitCastingInfo("player") then
    return true
  end

  if UnitChannelInfo and UnitChannelInfo("player") then
    return true
  end

  if GCD.activeEmpower then
    return true
  end

  return false
end

function GCD:OnSpellCastSent(unit, target, castGUID, spellID)
  --print("GCD:OnSpellCastSent", spellID)
  self.pendingSent = {
    spellID = tonumber(spellID),
    castGUID = castGUID,
    at = GetTime(),
  }
end

function GCD:OnCastStart(castGUID, spellID)
  self.pendingSent = nil
  self.pendingReal = {
    spellID = tonumber(spellID),
    castGUID = castGUID,
    kind = "cast",
    at = GetTime(),
  }
  self.lastStarted = self.pendingReal
end

function GCD:OnChannelStart(castGUID, spellID)
  self.pendingSent = nil
  self.pendingReal = {
    spellID = tonumber(spellID),
    castGUID = castGUID,
    kind = "channel",
    at = GetTime(),
  }
  self.lastStarted = self.pendingReal
end

function GCD:OnEmpowerStart(castGUID, spellID, castBarID)
  self.pendingSent = nil
  self.activeEmpower = {
    spellID = tonumber(spellID),
    castGUID = castGUID,
    castBarID = castBarID,
    at = GetTime(),
    kind = "empower",
  }
  self.lastStarted = self.activeEmpower
end


function GCD:OnEmpowerStop(castGUID, spellID, complete, interruptedBy, castBarID)
  local rec = self.activeEmpower
  if not rec then return end
  if rec.castGUID ~= castGUID and rec.spellID ~= tonumber(spellID) then
    return
  end

  self.pendingEmpowerGCD = {
    spellID = tonumber(spellID),
    castGUID = castGUID,
    castBarID = castBarID,
    kind = "empower",
    complete = complete,
    interruptedBy = interruptedBy,
    at = GetTime(),
  }

  self.activeEmpower = nil
end

function GCD:OnSpellCastSucceeded(castGUID, spellID)
  if SameCast(self.lastStarted, castGUID, spellID) then
    self.lastStarted = nil
    return
  end

  if SameCast(self.pendingSent, castGUID, spellID) then
    self.pendingSucceeded = {
      spellID = tonumber(spellID),
      castGUID = castGUID,
      at = GetTime(),
      kind = "instant",
    }
    self.pendingSent = nil
  end
end

function GCD:OnSpellCastFailed(castGUID, spellID)
  if SameCast(self.pendingSent, castGUID, spellID) then
    self.pendingSent = nil
  end

  if SameCast(self.pendingSucceeded, castGUID, spellID) then
    self.pendingSucceeded = nil
  end

  if SameCast(self.pendingReal, castGUID, spellID) then
    self.pendingReal = nil
  end

  if SameCast(self.activeEmpower, castGUID, spellID) then
    self.activeEmpower = nil
  end

  if SameCast(self.pendingEmpowerGCD, castGUID, spellID) then
    self.pendingEmpowerGCD = nil
  end

  if SameCast(self.lastStarted, castGUID, spellID) then
    self.lastStarted = nil
  end
end

function GCD:OnSpellCastInterrupted(castGUID, spellID)
  self:OnSpellCastFailed(castGUID, spellID)
end

function GCD:OnCastStop(castGUID, spellID)
  if SameCast(self.pendingReal, castGUID, spellID) then
    self.pendingReal = nil
  end

  if SameCast(self.lastStarted, castGUID, spellID) then
    self.lastStarted = nil
  end
end

function GCD:OnChannelStop(castGUID, spellID)
  if SameCast(self.pendingReal, castGUID, spellID) then
    self.pendingReal = nil
  end

  if SameCast(self.lastStarted, castGUID, spellID) then
    self.lastStarted = nil
  end
end


function GCD:HandleNonInstantGCD(spellID, kind, gcdDurObj, record)
  self.active = record
  self.activeGCDSpellID = spellID
  self.activeGCDKind = kind
  self.instant = false

  local bar = UCB.castBar and UCB.castBar.player
  if bar and bar.iconSwipe and bar.cfg_style and bar.cfg_style.effects and bar.cfg_style.effects.gcd and bar.cfg_style.effects.gcd.enable then
    pcall(function()
      bar.iconSwipe:SetCooldownFromDurationObject(gcdDurObj, true)
    end)
  end

  if type(self.NonInstantGCDCallback) == "function" then
    pcall(self.NonInstantGCDCallback, self, spellID, kind, gcdDurObj, record)
  end
end

function GCD:OnSpellUpdateCooldown(spellID, baseSpellID, category, startRecoveryCategory)
  if not IsGlobalGCDActive() then
    return
  end

  local gcdDurObj = GetGCDDuration()
  if not gcdDurObj then
    return
  end

  -- Empower claims GCD only after stop
  local emp = self.pendingEmpowerGCD
  if emp then
    if IsRecent(emp.at, 0.6) then
      self.pendingEmpowerGCD = nil
      self.active = emp
      self:HandleNonInstantGCD(emp.spellID, "empower", gcdDurObj, emp)
      return
    end
    self.pendingEmpowerGCD = nil
  end

  -- Then normal cast/channel pending, but only if fresh
  local rec = self.pendingReal
  if rec then
    if IsRecent(rec.at, 0.6) then
      self.pendingReal = nil
      self.active = rec
      self:HandleNonInstantGCD(rec.spellID, rec.kind, gcdDurObj, rec)
      return
    end
    self.pendingReal = nil
  end

  -- Instant/proc fallback:
  -- If we have a fresh SENT/SUCCEEDED spell, no real cast/channel/empower claimed the GCD,
  -- and the player is not currently casting-like, assume this spell owns the active GCD.
  -- Instant/proc fallback:
  local sent = self.pendingSent
  if sent and IsRecent(sent.at, 1.0) and not IsPlayerCastingLike() then
    -- Prevent off-GCD spells from hijacking an already displayed instant-owned GCD bar.
    if self.instant and self.activeGCDKind == "instant" and self.activeGCDSpellID then
      return
    end

    local ownerSpellID = sent.spellID

    -- If SENT spell isn't on GCD, try the cooldown update spell instead.
    if not IsSpellOnBaseGCD(ownerSpellID) and spellID and spellID ~= ownerSpellID then
      ownerSpellID = spellID
    end

    -- Final check: if chosen owner still isn't on GCD, skip.
    if not IsSpellOnBaseGCD(ownerSpellID) then
      return
    end

    self.pendingSent = nil
    self.active = {
      spellID = ownerSpellID,
      castGUID = sent.castGUID,
      kind = "instant",
      at = sent.at,
    }

    self:HandleInstantGCD(ownerSpellID, gcdDurObj, self.active)
    return
  end

  if sent and not IsRecent(sent.at, 1.0) then
    self.pendingSent = nil
  end
end