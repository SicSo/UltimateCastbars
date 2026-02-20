local ADDON_NAME, UCB = ...

UCB.GeneralCore_Helpers = UCB.GeneralCore_Helpers or {}
local GeneralHelpers = UCB.GeneralCore_Helpers

function GeneralHelpers:KickAlpha(notInterruptibleSecretBool, kickReadySecretBool, whenKickReady, alpha)
  local kickReadyVal, kickNotReadyVal
  if whenKickReady then
    kickReadyVal = 1
    kickNotReadyVal = alpha or 0
  else
    kickReadyVal = 0
    kickNotReadyVal = 1
  end
  local kickMatchesWhen = C_CurveUtil.EvaluateColorValueFromBoolean(
        kickReadySecretBool,
        kickReadyVal,
        kickNotReadyVal
    )
  return C_CurveUtil.EvaluateColorValueFromBoolean(notInterruptibleSecretBool, 0, kickMatchesWhen)
end

function GeneralHelpers:GetKickTimer()
  local spellID = UCB.kickID
  if not spellID then
    return nil, nil
  end

  if C_Spell.GetSpellCooldownDuration then
    local duration = C_Spell.GetSpellCooldownDuration(spellID)
    if not duration then
      return nil, nil
    end

    return spellID, duration
  else
    local info = C_Spell.GetSpellCooldown(spellID)
    if not info then
      return nil, nil
    end

    local endTime = info.startTime + info.duration
    local remaining = math.max(0, endTime - GetTime())
    local isReady = info.startTime == 0 or endTime <= GetTime()

    return spellID, remaining, isReady
  end
end

function GeneralHelpers:NotSecretTo0_1(val)
    return C_CurveUtil.EvaluateColorValueFromBoolean(val, 0, 1)
end