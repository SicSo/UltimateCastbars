
local _, UCB = ...
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.STYLE_API = UCB.STYLE_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local UIOptions = UCB.UIOptions
local STYLE_API = UCB.STYLE_API

STYLE_API.spellStyleListArgs = STYLE_API.spellStyleListArgs or {}


function STYLE_API:DeepCopy(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            self:DeepCopy(dst[k], v)
        else
            dst[k] = v
        end
    end
end

function STYLE_API:RebuildOffsets(args, cfg, unit, oldThickness, oldThicknessIcon)
    args.grpBorder.args.borderOffsetGrp.args = self:BuildBorderOffsetArgs(cfg, unit, oldThickness)
    args.grpBorderIcon.args.borderOffsetGrp.args = self:BuildBorderOffsetIconArgs(cfg, unit, oldThickness, oldThicknessIcon)
end

function STYLE_API:BuildBorderOffsetArgs(cfg, unit, oldThickness)
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

function STYLE_API:BuildBorderOffsetIconArgs(cfg, unit, oldThickness, oldThicknessIcon)
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

local function createSpellListStyle(cfg)
    local classCFG = cfg.CLASSES[UCB.className]
    local spellStyling = classCFG and classCFG.spellStyling
    local values = {}
    for index, spellInfo in ipairs(spellStyling.styleSpells or {}) do
        if spellInfo and spellInfo.name then
            values[index] = spellInfo.name .. " - " .. spellInfo.id
        else
            values[index] = "Unknown spell - " .. spellInfo.id
        end
    end
    return values
end

function STYLE_API:createCopySettingsSpells(unit, cfg, base, bigCFG)
    if unit ~= "player" then return nil end
    local spellStyling = bigCFG.CLASSES[UCB.className].spellStyling
    local values_list = createSpellListStyle(bigCFG)
    local castIndex = 1
    local copyStyleSettingsGrp = {
        type = "group",
        name = "Spell style",
        order = 3,
        hidden = function() return #spellStyling.styleSpells == 0 end,
        args = {
            selectSource = {
                type = "select",
                name = "Copy from spell",
                desc = "Select the spell you want to copy the style settings from.",
                order = 1,
                width = 1.2,
                values = values_list,
                get = function() return castIndex end,
                set = function(_, value)
                    castIndex = value
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
            gap1 = {
                type = "description",
                name = "",
                order = 1.5,
                width = 0.1,
            },
            copyFromSource = {
                type = "execute",
                name = function() return "Copy from "..UIOptions.ColorText(UIOptions.turquoise, UIOptions.MakeTitle(values_list[castIndex])) end,
                desc = "Copy the current spell style settings to the other spells.",
                order = 2,
                width = 1.2,
                func = function()
                    STYLE_API:DeepCopy(cfg[base], spellStyling.styleSpells[castIndex].style)
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
        }
    }
    return copyStyleSettingsGrp
end

function STYLE_API:RebuildSpellStyleCopyArgs(unit, styleCFG, bigCFG)
    local spell_list_args = self.spellStyleListArgs[unit]
    for key, arg in pairs(spell_list_args) do
        arg.parent[arg.key] = self:createCopySettingsSpells(unit, styleCFG, key, bigCFG)
    end
end
