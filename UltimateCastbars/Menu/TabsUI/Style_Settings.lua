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

STYLE_API.spellStyleListArgs = STYLE_API.spellStyleListArgs or {}

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
            type = "execute",dialogControl = "UCB_Button",
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
        if castType == "class" then
            buttons["btn_"..castType].hidden = function() return not UCB:IsPlayer(unit) end
            buttons["btn_"..castType].hidden = function() return not UCB:IsPlayer(unit) end
        end
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


local function BuildCustomisationArgs(args, unit)
    local bigCFG = GetCFG(unit)
    local castTypeStyleCFG = bigCFG.styleCastType

    args.styleSelectionGrp = {
        type = "group",
        name = "Style settings",
        order = 0,
        inline = true,
        args = {
            headerMode = {
                type = "header",  dialogControl = "UCB_Heading",
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
                    STYLE_API:RebuildMainStyleCopyArgs(unit, castTypeStyleCFG, bigCFG)
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
                hidden = function() return not castTypeStyleCFG.useGeneralStyle or not UCB:IsPlayer(unit) end,
                args = STYLE_API:createQuickButtons(unit, { "class" }),
            },
            generalStyleGrp = {
                type = "group",
                name = "General style settings",
                order = 2,
                inline = true,
                disabled = function() return not castTypeStyleCFG.useGeneralStyle end,
                args = {
                    copyGrp = {
                        type = "group",
                        name = "Copy style settings",
                        order = 1,
                        disabled = false,
                        args = {
                            copySettingsGrp = STYLE_API:createCopySettingsMainTOMain(unit, castTypeStyleCFG, "general"),
                            copySettingsSpellsGrp = STYLE_API:createCopySettingsSpellsTOMain(unit, castTypeStyleCFG, "general", bigCFG),
                        },
                    },
                    styleWindow = createStyleWindow(unit, castTypeStyleCFG, "general", 4),
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
                        type = "header",  dialogControl = "UCB_Heading",
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
                    copyGrp = {
                        type = "group",
                        name = "Copy style settings",
                        order = 2,
                        args = {
                            copySettingsGrp = STYLE_API:createCopySettingsMainTOMain(unit, castTypeStyleCFG, "normal"),
                            copySettingsSpellsGrp = STYLE_API:createCopySettingsSpellsTOMain(unit, castTypeStyleCFG, "normal", bigCFG),
                        }
                    },
                    styleWindow = createStyleWindow(unit, castTypeStyleCFG, "normal", 4),
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
                        type = "header",  dialogControl = "UCB_Heading",
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
                    copyGrp = {
                        type = "group",
                        name = "Copy style settings",
                        order = 2,
                        args = {
                            copySettingsGrp = STYLE_API:createCopySettingsMainTOMain(unit, castTypeStyleCFG, "channel"),
                            copySettingsSpellsGrp = STYLE_API:createCopySettingsSpellsTOMain(unit, castTypeStyleCFG, "channel", bigCFG),
                        },
                    },
                    styleWindow = createStyleWindow(unit, castTypeStyleCFG, "channel", 4),
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
                        type = "header",  dialogControl = "UCB_Heading",
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
                    copyGrp = {
                        type = "group",
                        name = "Copy style settings",
                        order = 2,
                        args = {
                            copySettingsGrp = STYLE_API:createCopySettingsMainTOMain(unit, castTypeStyleCFG, "empowered"),
                            copySettingsSpellsGrp = STYLE_API:createCopySettingsSpellsTOMain(unit, castTypeStyleCFG, "empowered", bigCFG),
                        },
                    },
                    styleWindow = createStyleWindow(unit, castTypeStyleCFG, "empowered", 4),
                },
            }
        }
    }
    STYLE_API.spellStyleListArgs[unit] = {
        general = { parent = args.styleSelectionGrp.args.generalStyleGrp.args.copyGrp.args, key = "copySettingsSpellsGrp" },
        normal  = { parent = args.styleNormal.args.styleNormalgrp.args.copyGrp.args,       key = "copySettingsSpellsGrp" },
        channel = { parent = args.styleChannel.args.styleChannelgrp.args.copyGrp.args,     key = "copySettingsSpellsGrp" },
        empowered = { parent = args.styleEmpowered.args.styleEmpoweredgrp.args.copyGrp.args, key = "copySettingsSpellsGrp" },
    }
end

-- Public builder
function Opt.BuildGeneralSettingsStyleArgs(unit, opts)
    opts = opts or {}
    local args = {}
    BuildCustomisationArgs(args, unit)

    return args
end


