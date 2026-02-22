local _, UCB = ...

UCB.UNINTERRUPTIBLE_API = UCB.UNINTERRUPTIBLE_API or {}
UCB.STYLE_API = UCB.STYLE_API or {}

local UNINTERRUPTIBLE = UCB.UNINTERRUPTIBLE_API

UNINTERRUPTIBLE.BuildBorderOffsetArgs = UCB.STYLE_API.BuildBorderOffsetArgs
UNINTERRUPTIBLE.BuildBorderOffsetIconArgs = UCB.STYLE_API.BuildBorderOffsetIconArgs

function UNINTERRUPTIBLE:RebuildOffsets(args, cfg, unit, oldThickness, oldThicknessIcon)
    args.uninterruptibleGroup.args.unintBorderGrp.args.grpBorder.args.borderOffsetGrp.args = self:BuildBorderOffsetArgs(cfg, unit, oldThickness)
    args.uninterruptibleGroup.args.unintBorderGrp.args.grpBorderIcon.args.iconBorderOptionGrp.args.borderOffsetGrp.args = self:BuildBorderOffsetIconArgs(cfg, unit, oldThickness, oldThicknessIcon)
end