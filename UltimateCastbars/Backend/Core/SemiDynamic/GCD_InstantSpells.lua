local ADDON_NAME, UCB = ...

UCB.GCD = UCB.GCD or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.tags     = UCB.tags     or {}
UCB.GeneralCore_Helpers = UCB.GeneralCore_Helpers or {}
UCB.Latency = UCB.Latency or {}

local CASTBAR_API = UCB.CASTBAR_API
local tags = UCB.tags
local GeneralHelpers = UCB.GeneralCore_Helpers
local Latency = UCB.Latency
local GCD = UCB.GCD


---------------------------------------------------------------------------------------
GCD.pendingGCD = nil
GCD.activeGCDSpellID = nil
GCD.instant = false

local function IsGlobalGCDActive()
  local ok, info = pcall(C_Spell.GetSpellCooldown, UCB.GCDSpellID)
  if not ok or not info then
    return false
  end

  local remain = info.timeUntilEndOfStartRecovery
  return type(remain) == "number" and remain > 0
end

function GCD:SetPendingGCDSpell(spellID, instant)
  if type(spellID) == "number" and spellID > 0 then
    self.pendingGCD = spellID
    self.instant = instant or false
  end
end

local function ClearPendingGCDSpell(spellID)
  if GCD.pendingGCD == spellID then
    GCD.pendingGCD = nil
  end
end

function GCD:TryActivatePendingGCD()
  if not self.pendingGCD then
    return nil
  end
  if not IsGlobalGCDActive() then
    return nil
  end

  self.activeGCDSpellID = self.pendingGCD
  self.pendingGCD = nil
  return self.activeGCDSpellID
end

local function GetDisplayedGCDDurationObjectForSpell(spellID)
  if spellID ~= GCD.activeGCDSpellID then
    return nil
  end

  local ok, durObj = pcall(C_Spell.GetSpellCooldownDuration, UCB.GCDSpellID)
  if ok and durObj then
    return durObj
  end

  return nil
end

function GCD:OnSpellCastSuccess(unitTarget, castGUID, spellID, castBarID)
   local current_spellID = UCB.castBar and UCB.castBar.player and UCB.castBar.player.current_spellID
   local current_castGUID = UCB.castBar and UCB.castBar.player and UCB.castBar.player.current_castGUID
   -- Normal casts
   if current_castGUID then
      if current_castGUID ~= castGUID then
          self:SetPendingGCDSpell(spellID, true)
      end
    -- Channel and Empowerred casts
    else
      if current_spellID == nil or (current_spellID and current_spellID ~= spellID) then
          self:SetPendingGCDSpell(spellID, true)
      end
    end
end


function GCD:OnSpellUpdateCooldown(spellID, baseSpellID, category, startRecoveryCategory)
    local activatedSpellID = self:TryActivatePendingGCD()
    local gcdDurObj = GetDisplayedGCDDurationObjectForSpell(activatedSpellID)
    if gcdDurObj and not self.instant then
      local bar = UCB.castBar and UCB.castBar.player
      if bar and bar.cfg_style and bar.cfg_style.effects and bar.cfg_style.effects.gcd and bar.cfg_style.effects.gcd.enable then
        bar.iconSwipe:SetCooldownFromDurationObject(gcdDurObj, true)
      end
  end
end


