local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.UNINTERRUPTIBLE_API = UCB.UNINTERRUPTIBLE_API or {}
UCB.STYLE_API = UCB.STYLE_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local UNINTERRUPTIBLE = UCB.UNINTERRUPTIBLE_API


function UNINTERRUPTIBLE:GetKickTimer()
  local spellID = UCB.kickID
  if not spellID then
    return nil
  end

  if C_Spell.GetSpellCooldownDuration then
    local duration = C_Spell.GetSpellCooldownDuration(spellID)
    if not duration then
      return nil
  end

    return spellID, duration
  else
    local info = C_Spell.GetSpellCooldown(spellID)
    if not info then
      return nil
    end

    local endTime = info.startTime + info.duration
    local remaining = math.max(0, endTime - GetTime())
    local isReady = info.startTime == 0 or endTime <= GetTime()

    return spellID, remaining, isReady
  end
end

UNINTERRUPTIBLE.BuildBorderOffsetArgs = UCB.STYLE_API.BuildBorderOffsetArgs
UNINTERRUPTIBLE.BuildBorderOffsetIconArgs = UCB.STYLE_API.BuildBorderOffsetIconArgs

function UNINTERRUPTIBLE:RebuildOffsets(args, cfg, unit, oldThickness, oldThicknessIcon)
    args.uninterruptibleGroup.args.grpBorder.args.borderOffsetGrp.args = self:BuildBorderOffsetArgs(cfg, unit, oldThickness)
    args.uninterruptibleGroup.args.grpBorderIcon.args.iconBorderOptionGrp.args.borderOffsetGrp.args = self:BuildBorderOffsetIconArgs(cfg, unit, oldThickness, oldThicknessIcon)
end