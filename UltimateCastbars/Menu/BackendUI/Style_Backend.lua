
local _, UCB = ...
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.STYLE_API = UCB.STYLE_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local UIOptions = UCB.UIOptions
local STYLE_API = UCB.STYLE_API
local GetCFG = UCB.GetValueConfig

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

function STYLE_API:RebuildOffsets(args, cfg, unit, oldThickness, oldThicknessIcon, opts)
    if opts.bar then
        args.grpBorder.args.borderOffsetGrp.args = self:BuildBorderOffsetArgs(cfg, unit, oldThickness)
    end
    if opts.icon then
        args.grpBorderIcon.args.borderOffsetGrp.args = self:BuildBorderOffsetIconArgs(cfg, unit, oldThickness, oldThicknessIcon)
    end
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
            type  = "range", dialogControl = "UCB_Slider",
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
            type  = "range", dialogControl = "UCB_Slider",
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
            type  = "range", dialogControl = "UCB_Slider",
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
            type  = "range", dialogControl = "UCB_Slider",
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
            type  = "range", dialogControl = "UCB_Slider",
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
            type  = "range", dialogControl = "UCB_Slider",
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
            type  = "range", dialogControl = "UCB_Slider",
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
            type  = "range", dialogControl = "UCB_Slider",
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

-------------------------------------------------------------------------- STYLE per cast type and spell style copy functions --------------------------------------------------------------------------
local function createCasttypeList(useGeneral, base)
    local values = {
        general   = "General",
        normal    = "Normal",
        channel   = "Channelled",
        empowered = "Empowered",
    }

    if base~=nil then values[base] = nil end
    if useGeneral then
        values.normal = nil
        values.channel = nil
        values.empowered = nil
    end

    local sorting = { "general", "normal", "channel", "empowered" }
    local newSorting = {}

    for _, k in ipairs(sorting) do
        if values[k] ~= nil then
            table.insert(newSorting, k)
        end
    end

    return values, newSorting
end

function STYLE_API:createCopySettingsMainTOMain(unit, cfg, base)
    local values_list, sorting = createCasttypeList(cfg.useGeneralStyle, base)
    local copyFromCastType = sorting[1]
    local copyStyleSettingsGrp = {
        type = "group",
        name = "Main types style",
        order = 2,
        hidden = function() return base == "general" and cfg.useGeneralStyle end,
        args = {
            selectSource = {
                type = "select",
                name = "Copy from cast type",
                desc = "Select the cast type you want to copy the style settings from.",
                order = 1,
                width = 1.2,
                values = createCasttypeList(cfg.useGeneralStyle, base),
                get = function() return copyFromCastType end,
                set = function(_, value)
                    copyFromCastType = value
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
                type = "execute",dialogControl = "UCB_Button",
                name = function() return "Copy from "..UIOptions.ColorText(UIOptions.turquoise, UIOptions.MakeTitle(copyFromCastType)) end,
                desc = "Copy the current cast type style settings to the other cast types.",
                order = 2,
                width = 1.2,
                func = function()
                    STYLE_API:DeepCopy(cfg[base], cfg[copyFromCastType])
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
            gap2 = {
                type = "description",
                name = "",
                order = 2.5,
                width = 0.1,
            },
            resetDefault = {
                type = "execute",dialogControl = "UCB_Button",
                name = "Reset to default",
                desc = "Reset the current cast type style settings to default.",
                order = 3,
                width = 1.2,
                func = function()
                    STYLE_API:DeepCopy(cfg[base], cfg.default)
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            }
        }
    }
    return copyStyleSettingsGrp
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

function STYLE_API:createCopySettingsSpellsTOMain(unit, cfg, base, bigCFG)
    if not UCB:IsPlayer(unit) then return nil end
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
                type = "execute",dialogControl = "UCB_Button",
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
        arg.parent[arg.key] = self:createCopySettingsSpellsTOMain(unit, styleCFG, key, bigCFG)
    end
end



function STYLE_API:createCopySettingsSpellTOSpell(unit, cfg, base_index)
    local values_list = {}
    for i, spellInfo in ipairs(cfg.styleSpells) do
        if i == base_index then
            values_list[i] = nil
        elseif spellInfo and spellInfo.name then
            values_list[i] = spellInfo.name .. " - " .. spellInfo.id
        else
            values_list[i] = "Unknown spell - " .. (spellInfo and spellInfo.id or "nil")
        end
    end
    local src_index = base_index ~= 1 and 1 or 2
    local copyStyleSettingsGrp = {
        type = "group",
        name = "Spell style",
        order = 1,
        hidden = function() return #cfg.styleSpells == 1 end,
        args = {
            selectSource = {
                type = "select",
                name = "Copy from spell",
                desc = "Select the spell you want to copy the style settings from.",
                order = 1,
                width = 1.2,
                values = values_list,
                get = function() return src_index end,
                set = function(_, value)
                    src_index = value
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
                type = "execute",dialogControl = "UCB_Button",
                name = function() return "Copy from "..UIOptions.ColorText(UIOptions.turquoise, UIOptions.MakeTitle(values_list[src_index])) end,
                desc = "Copy the current spell style settings to the other spells.",
                order = 2,
                width = 1.2,
                func = function()
                    STYLE_API:DeepCopy(cfg.styleSpells[base_index].style, cfg.styleSpells[src_index].style)
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
            gap2 = {
                type = "description",
                name = "",
                order = 2.5,
                width = 0.1,
            },
            resetDefault = {
                type = "execute",dialogControl = "UCB_Button",
                name = "Reset to default",
                desc = "Reset the current cast type style settings to default.",
                order = 3,
                width = 1.2,
                func = function()
                    STYLE_API:DeepCopy(cfg.styleSpells[base_index].style, GetCFG(unit, {"styleCastType", "default"}))
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            }
        }
    }
    return copyStyleSettingsGrp
end


function STYLE_API:createCopySettingsMainToSpell(unit, cfg, base_index, styleCFG)
    local values_list, sorting = createCasttypeList(styleCFG.useGeneralStyle)
    local copyFromCastType = sorting[1]
    local copyStyleSettingsGrp = {
        type = "group",
        name = "Main types style",
        order = 2,
        args = {
            selectSource = {
                type = "select",
                name = "Copy from cast type",
                desc = "Select the cast type you want to copy the style settings from.",
                order = 1,
                width = 1.2,
                values = createCasttypeList(styleCFG.useGeneralStyle),
                get = function() return copyFromCastType end,
                set = function(_, value)
                    copyFromCastType = value
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
                type = "execute",dialogControl = "UCB_Button",
                name = function() return "Copy from "..UIOptions.ColorText(UIOptions.turquoise, UIOptions.MakeTitle(copyFromCastType)) end,
                desc = "Copy the current cast type style settings to the other cast types.",
                order = 2,
                width = 1.2,
                func = function()
                    STYLE_API:DeepCopy(cfg.styleSpells[base_index].style, styleCFG[copyFromCastType])
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
        }
    }
    return copyStyleSettingsGrp
end

function STYLE_API:RebuildMainStyleCopyArgs(unit, styleCFG, bigCFG)
    local spellStyling = bigCFG.CLASSES[UCB.className].spellStyling
    local mainCopyArgs = self.ClassCopyMain
    mainCopyArgs.parent[mainCopyArgs.key] = self:createCopySettingsMainToSpell(unit, spellStyling, mainCopyArgs.index, styleCFG)
end