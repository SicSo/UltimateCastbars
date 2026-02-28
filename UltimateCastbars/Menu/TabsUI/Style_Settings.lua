local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.STYLE_API = UCB.STYLE_API or {}
UCB.UIStructures = UCB.UIStructures or {}


local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local UIOptions = UCB.UIOptions
local STYLE_API = UCB.STYLE_API
local UIStructures = UCB.UIStructures

local function createCasttypeList(base)
    local values = {
        general   = "General",
        normal    = "Normal",
        channel   = "Channelled",
        empowered = "Empowered",
    }

    values[base] = nil

    local sorting = { "general", "normal", "channel", "empowered" }
    local newSorting = {}

    for _, k in ipairs(sorting) do
        if values[k] ~= nil then
            table.insert(newSorting, k)
        end
    end

    return values, newSorting
end

function STYLE_API:createCastTypePath(castType)
    local path = {
        general = {"style"},
        normal = {"style",  "styleNormal"},
        channel = {"style", "styleChannel"},
        empowered = {"style", "styleEmpowered"},
        class = {"classSettings", "class_" .. UCB.className, "styleSection"},
    }
    return path[castType]
end

function STYLE_API:createQuickButtons(unit, tabs)
    local buttons = {}
    for index, castType in ipairs(tabs) do
        buttons["btn_"..castType] = {
            type = "execute",
            name = function() return UIOptions.MakeTitle(castType).." casts" end,
            desc = function() return "Jump to the "..castType.." cast style settings." end,
            width = 0.8,
            order = index,
            func = function()
                UCB:SelectGroup(STYLE_API:createCastTypePath(castType), unit)
            end,
        }
        buttons["gap_"..castType] = {
            type = "description",
            name = "",
            order = index + 0.5,
            width = 0.2,
        }
    end
    return buttons
end

local function createStyleWindow(unit, castTypeStyleCFG, castType, order)
    local styleWindow = {
        type = "group",
        name = function() return UIOptions.MakeTitle(castType).." style settings" end,
        order = order,
        args = UIStructures:BuildStyleWindow(castTypeStyleCFG[castType], unit),
    }
    return styleWindow
end


local function createCopySettings(unit, cfg, base)
    local values_list, sorting = createCasttypeList(base)
    local copyFromCastType = sorting[1]
    local copyStyleSettingsGrp = {
        type = "group",
        name = "Copy style settings",
        order = 2,
        args = {
            selectSource = {
                type = "select",
                name = "Copy from cast type",
                desc = "Select the cast type you want to copy the style settings from.",
                order = 1,
                width = 1.2,
                values = createCasttypeList(base),
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
                type = "execute",
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
                type = "execute",
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

local function BuildCustomisationArgs(args, unit)
    local castTypeStyleCFG = GetCFG(unit, "styleCastType")

    args.styleSelectionGrp = {
        type = "group",
        name = "Style settings",
        order = 0,
        inline = true,
        args = {
            headerMode = {
                type = "header",
                name = function() 
                    if castTypeStyleCFG.useGeneralStyle then
                        return "Using "..UIOptions.ColorText(UIOptions.turquoise, "general").." style settings for all cast types"
                    end
                    return "Using "..UIOptions.ColorText(UIOptions.turquoise, "individual").." style settings for each cast type"
                end,
                order = 0,
            },
            useGeneralSettings = {
                type = "toggle",
                name = "Use general settings",
                desc = "Use the general settings for this cast type instead of custom ones.",
                order = 1,
                get = function() return castTypeStyleCFG.useGeneralStyle end,
                set = function(_, value)
                    castTypeStyleCFG.useGeneralStyle = value
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            buttonsFull = {
                    type = "group",
                    name = "Quick navigation",
                    order = 1.5,
                    inline = true,
                    hidden = function() return castTypeStyleCFG.useGeneralStyle end,
                    args = STYLE_API:createQuickButtons(unit, { "normal", "channel", "empowered", "class" }),
            },
            buttonsClass = {
                type = "group",
                name = "Quick navigation",
                order = 1.5,
                inline = true,
                hidden = function() return not castTypeStyleCFG.useGeneralStyle end,
                args = STYLE_API:createQuickButtons(unit, { "class" }),
            },
            generalStyleGrp = {
                type = "group",
                name = "General style settings",
                order = 2,
                inline = true,
                disabled = function() return not castTypeStyleCFG.useGeneralStyle end,
                args = {
                    copySettingsGrp = createCopySettings(unit, castTypeStyleCFG, "general"),
                    styleWindow = createStyleWindow(unit, castTypeStyleCFG, "general", 3),
                },
            },
        }
    }

    args.styleNormal = {
        type = "group",
        name = "Normal",
        order = 1,
        hidden = function() return castTypeStyleCFG.useGeneralStyle end,
        args = {
            styleNormalgrp = {
                type = "group",
                name = "Normal cast style settings",
                order = 1,
                inline = true,
                args = {
                     editHeader = {
                        type = "header",
                        name = function() return "Settings for "..UIOptions.ColorText(UIOptions.turquoise , UIOptions.MakeTitle(unit).." - NORMAL").." casts" end,
                        order = 1,
                    },
                    buttons = {
                        type = "group",
                        name = "Quick navigation",
                        order = 1.5,
                        inline = true,
                        args = STYLE_API:createQuickButtons(unit, { "general", "empowered", "channel", "class" }),
                    },
                    copySettingsGrp = createCopySettings(unit, castTypeStyleCFG, "normal"),
                    styleWindow = createStyleWindow(unit, castTypeStyleCFG, "normal", 3),
                }
            }
        },
    }

    args.styleChannel = {
        type = "group",
        name = "Channel",
        order = 2,
        hidden = function() return castTypeStyleCFG.useGeneralStyle end,
        args = {
            styleChannelgrp = {
                type = "group",
                name = "Channel cast style settings",
                order = 1,
                inline = true,
                args = {
                    editHeader = {
                        type = "header",
                        name = function() return "Settings for "..UIOptions.ColorText(UIOptions.turquoise , UIOptions.MakeTitle(unit).." - CHANNEL").." casts" end,
                        order = 1,
                    },
                    buttons = {
                        type = "group",
                        name = "Quick navigation",
                        order = 1.5,
                        inline = true,
                        args = STYLE_API:createQuickButtons(unit, { "general", "normal", "empowered", "class" }),
                    },
                    copySettingsGrp = createCopySettings(unit, castTypeStyleCFG, "channel"),
                    styleWindow = createStyleWindow(unit, castTypeStyleCFG, "channel", 3),
                },
            }
        }
    }

    args.styleEmpowered = {
        type = "group",
        name = "Empowered",
        order = 3,
        hidden = function() return castTypeStyleCFG.useGeneralStyle end,
        args = {
            styleEmpoweredgrp = {
                type = "group",
                name = "Empowered cast style settings",
                order = 1,
                inline = true,
                args = {
                    editHeader = {
                        type = "header",
                        name = function() return "Settings for "..UIOptions.ColorText(UIOptions.turquoise , UIOptions.MakeTitle(unit).." - EMPOWERED").." casts" end,
                        order = 1,
                    },
                    buttons = {
                        type = "group",
                        name = "Quick navigation",
                        order = 1.5,
                        inline = true,
                        args = STYLE_API:createQuickButtons(unit, { "general", "normal", "channel", "class" }),
                    },
                    copySettingsGrp = createCopySettings(unit, castTypeStyleCFG, "empowered"),
                    styleWindow = createStyleWindow(unit, castTypeStyleCFG, "empowered", 3),
                },
            }
        }
    }
end

-- Public builder
function Opt.BuildGeneralSettingsStyleArgs(unit, opts)
    opts = opts or {}
    local args = {}
    BuildCustomisationArgs(args, unit)

    return args
end


