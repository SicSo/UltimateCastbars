
local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.STYLE_API = UCB.STYLE_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local STYLE_API = UCB.STYLE_API

local LSM  = UCB.LSM

function STYLE_API:RebuildOffsets(args, cfg, UIOptions, unit, oldThickness, oldThicknessIcon)
    args.grpBorder.args.borderOffsetGrp.args = self:BuildBorderOffsetArgs(cfg, UIOptions, unit, oldThickness)
    args.grpBorderIcon.args.borderOffsetGrp.args = self:BuildBorderOffsetIconArgs(cfg, UIOptions, unit, oldThickness, oldThicknessIcon)
end


function STYLE_API:BuildBorderOffsetArgs(cfg, UIOptions, unit, oldThickness)
    local thickness = tonumber(cfg.borderThickness) or 0
    local minV = -thickness
    local maxV = UIOptions.borderOffsetMax  -- keep your existing max

    if cfg.borderOffsetTop < minV then 
        cfg.borderOffsetTop = minV
    elseif cfg.borderOffsetTop == -oldThickness then
        cfg.borderOffsetTop = -thickness
    end

    if cfg.borderOffsetBottom < minV then
        cfg.borderOffsetBottom = minV
    elseif cfg.borderOffsetBottom == -oldThickness then
        cfg.borderOffsetBottom = -thickness
    end

    if cfg.borderOffsetLeft < minV then 
        cfg.borderOffsetLeft = minV 
    elseif cfg.borderOffsetLeft == -oldThickness then
        cfg.borderOffsetLeft = -thickness
    end

    if cfg.borderOffsetRight < minV then
        cfg.borderOffsetRight = minV
    elseif cfg.borderOffsetRight == -oldThickness then
        cfg.borderOffsetRight = -thickness
    end

    return {
        borderOffsetTop = {
            type  = "range",
            name  = "Top",
            min   = minV,
            max   = maxV,
            step  = 0.5,
            order = 1,
            get   = function() return cfg.borderOffsetTop end,
            set   = function(_, val)
                cfg.borderOffsetTop = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
        borderOffsetBottom = {
            type  = "range",
            name  = "Bottom",
            min   = minV,
            max   = maxV,
            step  = 0.5,
            order = 2,
            get   = function() return cfg.borderOffsetBottom end,
            set   = function(_, val)
                cfg.borderOffsetBottom = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
        borderOffsetLeft = {
            type  = "range",
            name  = "Left",
            min   = minV,
            max   = maxV,
            step  = 0.5,
            order = 3,
            get   = function() return cfg.borderOffsetLeft end,
            set   = function(_, val)
                cfg.borderOffsetLeft = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
        borderOffsetRight = {
            type  = "range",
            name  = "Right",
            min   = minV,
            max   = maxV,
            step  = 0.5,
            order = 4,
            get   = function() return cfg.borderOffsetRight end,
            set   = function(_, val)
                cfg.borderOffsetRight = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
    }
end

function STYLE_API:BuildBorderOffsetIconArgs(cfg, UIOptions, unit, oldThickness, oldThicknessIcon)
    local thickness = cfg.borderThickness
    local thicknessIcon = cfg.borderThicknessIcon
    local actualOldThicknessIcon = oldThicknessIcon
    if cfg.syncBorderIcon then
        thicknessIcon = thickness
        actualOldThicknessIcon = oldThickness
    end
    local minV = -thicknessIcon
    local maxV = UIOptions.borderOffsetMax

    if cfg.borderOffsetTopIcon < minV then 
        cfg.borderOffsetTopIcon = minV 
    elseif cfg.borderOffsetTopIcon == -actualOldThicknessIcon then
        cfg.borderOffsetTopIcon = -thicknessIcon
    end

    if cfg.borderOffsetBottomIcon < minV then
         cfg.borderOffsetBottomIcon = minV 
    elseif cfg.borderOffsetBottomIcon == -actualOldThicknessIcon then
        cfg.borderOffsetBottomIcon = -thicknessIcon
    end

    if cfg.borderOffsetLeftIcon < minV then 
        cfg.borderOffsetLeftIcon = minV 
    elseif cfg.borderOffsetLeftIcon == -actualOldThicknessIcon then
        cfg.borderOffsetLeftIcon = -thicknessIcon
    end

    if cfg.borderOffsetRightIcon < minV then 
        cfg.borderOffsetRightIcon = minV 
    elseif cfg.borderOffsetRightIcon == -actualOldThicknessIcon then
        cfg.borderOffsetRightIcon = -thicknessIcon
    end

    return {
        borderOffsetTopIcon = {
            type  = "range",
            name  = "Top",
            min   = minV,
            max   = maxV,
            step  = 0.5,
            order = 1,
            get   = function() return cfg.borderOffsetTopIcon end,
            set   = function(_, val)
                cfg.borderOffsetTopIcon = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
        borderOffsetBottomIcon = {
            type  = "range",
            name  = "Bottom",
            min   = minV,
            max   = maxV,
            step  = 0.5,
            order = 2,
            get   = function() return cfg.borderOffsetBottomIcon end,
            set   = function(_, val)
                cfg.borderOffsetBottomIcon = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
        borderOffsetLeftIcon = {
            type  = "range",
            name  = "Left",
            min   = minV,
            max   = maxV,
            step  = 0.5,
            order = 3,
            get   = function() return cfg.borderOffsetLeftIcon end,
            set   = function(_, val)
                cfg.borderOffsetLeftIcon = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
        borderOffsetRightIcon = {
            type  = "range",
            name  = "Right",
            min   = minV,
            max   = maxV,
            step  = 0.5,
            order = 4,
            get   = function() return cfg.borderOffsetRightIcon end,
            set   = function(_, val)
                cfg.borderOffsetRightIcon = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
    }
end
