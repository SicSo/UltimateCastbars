local ADDON_NAME, UCB = ...

_G.UCB = UCB

-- Created APIs
UCB.CFG_API = UCB.CFG_API or {}
UCB.tags = UCB.tags or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.DefBlizzCast = UCB.DefBlizzCast or {}
UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}
UCB.Preview_API = UCB.Preview_API or {}
UCB.Text_API = UCB.Text_API or {}
UCB.CLASS_API = UCB.CLASS_API or {}
UCB.STYLE_API = UCB.STYLE_API or {}
UCB.SimpleFramePicker = UCB.SimpleFramePicker or {}
UCB.Options = UCB.Options or {}
UCB.Default_DB = UCB.Default_DB or {}
UCB.Profiles = UCB.Profiles or {}
UCB.Debug = UCB.Debug or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.UI = UCB.UI or {}
UCB.GUI = UCB.GUI or {}
UCB.GeneralCore_Helpers = UCB.GeneralCore_Helpers or {}
UCB.Copy = UCB.Copy or {}
UCB.Normiliser = UCB.Normiliser or {}
UCB.UIStructures = UCB.UIStructures or {}
UCB.Migration = UCB.Migration or {}
UCB.Latency = UCB.Latency or {}
UCB.UITextures = UCB.UITextures or {}
UCB.Theme = UCB.Theme or {}

-- Sub APIs
UCB.CLASS_API.Evoker = UCB.CLASS_API.Evoker or {}
UCB.Options.ClassExtraBuilders = UCB.Options.ClassExtraBuilders or {}

UCB.CASTBAR_API.CreateCastbar = UCB.CASTBAR_API.UpdateCastbar -- for backward compatibility


local function IsPetUsingVehicleUnit(unit)
    return unit == "pet"
        and UnitExists("vehicle")
        and UnitHasVehicleUI("player")
end

function UCB:EnsureSpellcastEventFrame()
  if UCB.eventFrame.spellcast and UCB.eventFrame.swap then return end

  if not UCB.eventFrame.spellcast then
    local events = UCB.events
    local f1 = CreateFrame("Frame")
    for eventName in pairs(events) do
      f1:RegisterEvent(eventName)
    end

    f1:SetScript("OnEvent", function(_, event, unit, castGUID, spellID, castBarID)
      if unit == "pet" then
        if not UCB.trackedUnits.player or not IsPetUsingVehicleUnit(unit) then
          return
        end
        unit = "player"
        UCB.usePetForPlayer = true
      else
        if not UCB.trackedUnits[unit] then
          return
        end
      end
      --if not UCB.trackedUnits[unit] then return end
      local resumeCast = false

      local method = events[event]
      local api = UCB.CASTBAR_API
      if method and api and api[method] then
        api[method](api, unit, castGUID, spellID, castBarID, resumeCast)
      end
    end)

    UCB.eventFrame.spellcast = f1

  end

  if not UCB.eventFrame.swap then 
    local swapEvents = UCB.swapEvents
    local f2 = CreateFrame("Frame")
    for eventName in pairs(swapEvents) do
      f2:RegisterEvent(eventName)
    end

    f2:SetScript("OnEvent", function(_, event)
      local eventInfo = swapEvents[event]
      local method = eventInfo and eventInfo[1]
      local unit = eventInfo and eventInfo[2]
      local api = UCB.CASTBAR_API
      if method and api and api[method] then
        api[method](api, unit)
      end

    end)

    UCB.eventFrame.swap = f2
  end

  if not UCB.eventFrame.interrupted then
    local f3 = CreateFrame("Frame")
    for eventName in pairs(UCB.interruptEvents) do
      f3:RegisterEvent(eventName)
    end

    f3:SetScript("OnEvent", function(_, event, unit, ...)
      if unit == "pet" then
        if not UCB.trackedUnits.player or  not IsPetUsingVehicleUnit(unit) then
          return
        end
        unit = "player"
      else
        if not UCB.trackedUnits[unit] then
          return
        end
      end
      
      local method = UCB.interruptEvents[event]
      local api = UCB.CASTBAR_API
      if method and api and api[method] then
        api[method](api, unit, ...)
      end
    end)

    UCB.eventFrame.interrupted = f3
  end

  if not UCB.eventFrame.latency then
    local f4 = CreateFrame("Frame")
    for eventName in pairs(UCB.latencyEvents) do
      f4:RegisterEvent(eventName)
    end

    f4:SetScript("OnEvent", function(_, event, unit, ...)
      local method = UCB.latencyEvents[event]
      local api = UCB.Latency
      if method and api and api[method] then
        api[method](api, unit, ...)
      end
    end)

    UCB.eventFrame.latency = f4
  end
  
end


function UCB:SaveDefaultCastbarFrames()
  for unit, tracked in pairs(self.trackedUnits) do
    if tracked then
      self.DefBlizzCast:ApplyDefaultBlizzCastbar(unit, false)
    end
  end
end

function UCB:UpdateCastbarTrackedUnits()
  for unit, tracked in pairs(self.trackedUnits) do
    if tracked then
      self.CASTBAR_API:UpdateCastbar(unit)
    end
  end
end

function UCB:TrackUnit(unit)
  self:EnsureSpellcastEventFrame()
  self.trackedUnits[unit] = true
end

function UCB:UntrackUnit(unit)
  if self.trackedUnits then
    self.trackedUnits[unit] = nil
  end
end

function UCB:SetUpTrackedUnit()
  local cfg = UCB.GetValueConfig()
  if not cfg then return end
  for unit, shown in pairs(self.menuUnits) do
    local shouldTrack = cfg[unit] and cfg[unit].enabled
    if shouldTrack and shown then
      self:TrackUnit(unit)
    else
      self:UntrackUnit(unit)
    end
  end
end

function UCB:SetUpConfig()
    UCB.cfg = UCB.db.profile
end

local function createPicker()
    UCB.SimpleFramePickerObj = UCB.SimpleFramePicker:New()
end


local function SetUpPlayerInfo()
    local _, class = UnitClass("player")
    UCB.className = class
    UCB.charColour = UCB.UIOptions.classColoursList[class]
    UCB.unitColours.player = UCB.charColour.RGBA
    UCB.unitNames.player = UnitName("player")
    UCB.specID = PlayerUtil.GetCurrentSpecID()
end


local function GetSpellType(spellID)
    if spellID and spellID ~= 0 then
        local tooltip = C_TooltipInfo.GetSpellByID(spellID)
        local castText = tooltip and tooltip.lines and tooltip.lines[3] and tooltip.lines[3].leftText

        if not castText then
          return nil
        end

        if castText:lower():find("cast") then
            return "normal"
        elseif castText:lower():find("channeled") then
            return "channel"
        elseif castText:lower():find("empower") then
            return "empowered"
        elseif castText:lower():find("instant") then
            return "instant"
        elseif castText:lower():find("passive") then
            return "passive"
        else
            return "unknown"
        end
    end
    return nil
end

local function SetUpSpellTypes()
  local out = { normal = {}, channel = {}, empowered = {} }
  local seen = { normal = {}, channel = {}, empowered = {} }

  local function add(bucket, spellID)
    if spellID and spellID ~= 0 and not seen[bucket][spellID] then
      seen[bucket][spellID] = true
      out[bucket][#out[bucket] + 1] = spellID
    end
  end

  if not (C_SpellBook
      and C_SpellBook.GetNumSpellBookSkillLines
      and C_SpellBook.GetSpellBookSkillLineInfo
      and C_SpellBook.GetSpellBookItemType
      and Enum and Enum.SpellBookSpellBank) then
    return out
  end

  local bank = Enum.SpellBookSpellBank.Player

  for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
    local info = C_SpellBook.GetSpellBookSkillLineInfo(i)
    if info and info.itemIndexOffset and info.numSpellBookItems then
      local first = info.itemIndexOffset + 1
      local last  = info.itemIndexOffset + info.numSpellBookItems

      for slot = first, last do
        local itemType, actionID, spellID = C_SpellBook.GetSpellBookItemType(slot, bank)
        local isPassive = C_SpellBook.IsSpellBookItemPassive(slot, bank)

        if not isPassive then
          local spellType = GetSpellType(spellID)
          if spellType == "normal" or spellType == "channel" or spellType == "empowered" then
            add(spellType, spellID)
          end
        end
      end
    end
  end

  UCB.allSpellTypes = out

  return out
end

local function ResolveFrames()
  for unit, use in pairs(UCB.menuUnits) do
    if use then
      local cfg = UCB.GetValueConfig(unit, "general")
      local delayAcnhor = cfg.anchorDelay
      local delaySync = cfg.syncDelay
      if not UCB.firstBuild then
        delayAcnhor = 0
        delaySync = 0
      end

      UCB.GeneralSettings_API:ResolveFramesOnLogin(unit, {
        anchorTries = cfg.anchorFrameTries,
        anchorInterval = cfg.anchorFrameInterval,
        syncTries = cfg.syncFrameTries,
        syncInterval = cfg.syncFrameInterval,
        syncDelay = delaySync,
        anchorDelay = delayAcnhor,
      })
    end
  end
end

local function GetKickID()
    local class = UCB.className
    local kickList = UCB.specs[class].kick
    for _, s in ipairs(kickList) do
      if C_SpellBook.IsSpellKnownOrInSpellBook(s) or C_SpellBook.IsSpellKnownOrInSpellBook(s, Enum.SpellBookSpellBank.Pet) then
        UCB.kickID = s
        return
      end
    end
end

function UCB:EnableSpecSwapListener()
  if self.eventFrame and self.eventFrame.specSwap then return end

  self.eventFrame = self.eventFrame or {}

  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED") -- main spec swap event (retail)
  f:RegisterEvent("TRAIT_CONFIG_UPDATED")          -- fallback for some talent/trait flows
  --f:RegisterEvent("PLAYER_LOGIN")                  -- initialize on login just in case

  local function UpdateSpec()
    -- PlayerUtil.GetCurrentSpecID() returns 0/nil sometimes during loading; guard it.
    local specID = PlayerUtil and PlayerUtil.GetCurrentSpecID and PlayerUtil.GetCurrentSpecID()
    if specID and specID ~= 0 and specID ~= UCB.specID then
      UCB.specID = specID
      UCB:UpdateAllCastBars()
    end
  end

  f:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_SPECIALIZATION_CHANGED" and not UCB:IsPlayer(unit, true) then return end
    UpdateSpec()
    C_Timer.After(0.1, function()
        SetUpSpellTypes()
    end)
  end)

  self.eventFrame.specSwap = f

  -- Prime the value right away
  UpdateSpec()
end

local function GatherInfo()
    SetUpPlayerInfo()

    -- delay spell scanning until the world is ready
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        f:UnregisterAllEvents()
        f:SetScript("OnEvent", nil)
        ResolveFrames()

        -- small delay helps tooltip/spellbook settle on first load
        C_Timer.After(0.3, function()
            SetUpSpellTypes()
        end)
    end)

    local f2 = CreateFrame("Frame")
    f2:RegisterEvent("PLAYER_LOGIN")
    f2:RegisterEvent("SPELLS_CHANGED")
    f2:SetScript("OnEvent", function()
        GetKickID()
    end)
end


local function HideCurrentBars()
  for unit, bar in pairs(UCB.castBar) do
    if UCB.menuUnits[unit] and bar then
      UCB.CASTBAR_API:StopPrevCast(unit, bar, nil, nil, nil)
    end
  end
end

local function RegisterGUIPathCommands(cmds, path)
    if type(cmds) ~= "table" or #cmds == 0 then return end

    -- Build a unique SlashCmdList key from the first command + path
    local key = "UCB_GUI_" .. tostring(cmds[1]):gsub("[^%w]", "")

    -- Register the slashes
    for i, slash in ipairs(cmds) do
        _G["SLASH_" .. key .. i] = slash
    end

    -- Handler: ONLY OpenGUI with the path
    SlashCmdList[key] = function()
        UCB.GUI:OpenGUI(path)
    end
end

local function RegisterDebug(slashStart, funcStart, slashStop, funcStop)
    if slashStart and funcStart then
        SLASH_UCBDEBUGSTART1 = slashStart
        SlashCmdList["UCBDEBUGSTART"] = funcStart
    end

    if slashStop and funcStop then
        SLASH_UCBDEBUGSTOP1 = slashStop
        SlashCmdList["UCBDEBUGSTOP"] = funcStop
    end
end

local function SetupSlashCommands()
  --Last tab
   RegisterGUIPathCommands(
        { "/ucb" , "/ultimatecastbars", "/uc" },
       nil
    )

    -- Player tab
    RegisterGUIPathCommands(
        { "/pcb" },
        { "player", "general" }
    )

    -- Target tab
    RegisterGUIPathCommands(
        { "/tcb" },
        { "target", "general" }
    )

    -- Focus tab
    RegisterGUIPathCommands(
        { "/fcb" },
        { "focus", "general" }
    )

    -- Profiles tab
    RegisterGUIPathCommands(
        { "/ucbprof" },
        { "profiles", "management" }
    )

    -- Debug
    RegisterDebug("/ucbdebug", function() UCB.Debug:StartDebug() end,
                "/ucbdebugstop", function() UCB.Debug:StopDebug() end)
    -- reload command
    SLASH_UCBRELOAD1 = "/rl"
    SlashCmdList["UCBRELOAD"] = function() C_UI.Reload() end
end



function UCB:InitSequence()
  UCB.firstBuild = true
  self:EnableSpecSwapListener()
  self:SetUpConfig()
  self:SetUpTrackedUnit() -- See which units should be tracked and track them (also ensures event frame is created)
  self:EnsureSpellcastEventFrame() -- Ensure the spellcast event frame exists
  self:SaveDefaultCastbarFrames() -- Save the default blizz castbar frames for tracked units
  self:UpdateCastbarTrackedUnits() -- Create cast bars for tracked units
  UCB.GUI:RegisterRootOptions() -- Create UI
  self.UCB_RegisterLandingPanel() -- Attach Blizzard Landing
  UCB.firstBuild = false
end

function UCB:UpdateAllCastBars()
  HideCurrentBars() -- Stop all current bars first to avoid issues with event handling and bars being active when they shouldn't be
  self:SetUpConfig()
  self:UpdateCastbarTrackedUnits() -- Upadate cast bars for tracked units
  UCB.GUI:OnProfileSwapRefreshUI() -- Refresh UI elements for CFG
  ResolveFrames() -- Resolve frame acnhors for all units
end


function UCB:Init()
  SetupSlashCommands()
  GatherInfo()
  createPicker()
  -- do the once-only setup and initial paint
  self:InitSequence()
end