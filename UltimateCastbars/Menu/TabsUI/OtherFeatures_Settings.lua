local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}
UCB.UIStructures = UCB.UIStructures or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local UIOptions = UCB.UIOptions
local OtherFeatures_API = UCB.OtherFeatures_API
local UIStructures = UCB.UIStructures
local LSM  = UCB.LSM

local function createPaths()
    return {
        general = {"otherFeatures"},
        channel = {"otherFeatures" , "channelTickGrp"},
        spell_que = {"otherFeatures" , "spellQueGrp"},
        mirror_inverse = {"otherFeatures" , "inversMirrorGrp"},
        interruptedEffect = {"otherFeatures" , "kickedGrp"},
        cancelledEffect = {"otherFeatures" , "cancelledGrp"},
    }
end

local function createNames()
    return {
        channel = "Channeling Options",
        spell_que = "Spell Queue",
        mirror_inverse = "Mirror/Inverse Bar",
        interruptedEffect = "Interrupted Effect",
        cancelledEffect = "Cancelled Effect",
    }
end



local function createQuickButtons(unit, tabs, names, paths, buttonSize)
    local buttons = {}
    for index, tab in ipairs(tabs) do
        buttons["btn_"..tab] = {
            type = "execute",
            name = function() return UIOptions.MakeTitle(names[tab]) end,
            desc = function() return "Jump to "..UIOptions.MakeTitle(names[tab]) end,
            width = buttonSize,
            order = index,
            func = function()
                UCB:SelectGroup(paths[tab], unit)
            end,
        }
        buttons["gap_"..tab] = {
            type = "description",
            name = "",
            order = index + 0.5,
            width = 0.2,
        }
    end
    return buttons
end



local function BuildKickedCancelledArgs(unit, cfg, castType, type, order)
    local castTypeName = castType:sub(1,1):upper()..castType:sub(2)
    local mainGrp = {
        type = "group",
        name = "",
        inline = true,
        order = order,
        args = {
            showEffect = {
                type  = "toggle",
                name  = function() return UIOptions.ColorText(UIOptions.turquoise, castTypeName).." casts: show "..UIOptions.ColorText(UIOptions.turquoise, type).." effects" end,
                order = 1,
                width = "full",
                get   = function() return cfg.enableEffect[castType] end,
                set   = function(_, val)
                    cfg.enableEffect[castType] = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            effectOptionsGro = {
                type = "group",
                name = function() return castTypeName.." cast effect options" end,
                inline = true,
                order = 2,
                hidden = function() return not cfg.enableEffect[castType] end,
                args = {
                    useMainTextureForEffect = {
                        type  = "toggle",
                        name  = function() return "Use main texture for effect" end,
                        order = 1,
                        width = "full",
                        get   = function() return cfg.useSameTextureAsMain[castType] end,
                        set   = function(_, val)
                            cfg.useSameTextureAsMain[castType] = val
                            CASTBAR_API:UpdateCastbar(unit)
                         end,
                    },
                    effectTexture = {
                        type          = "select",
                        dialogControl = "LSM30_Statusbar",
                        name          = function() return castTypeName.." cast effect texture" end,
                        order         = 2,
                        values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                        get           = function() return cfg.frameTextureName[castType] end,
                        set           = function(_, val)
                            cfg.frameTextureName[castType] = val
                            cfg.frameTexture[castType] = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                        disabled = function() return cfg.useSameTextureAsMain[castType] == true end,
                    },
                    gap1 = {
                        type = "description",
                        name = "",
                        order = 2.5,
                        width = "0.3",
                    },
                    effectColor = {
                        type = "color",
                        name = function() return castTypeName.." cast effect colour" end,
                        hasAlpha = true,
                        order = 3,
                        get = function()
                            local c = cfg.frameColour[castType]
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r,g,b,a)
                            cfg.frameColour[castType] = {r=r,g=g,b=b,a=a}
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    gap2 = {
                        type = "description",
                        name = "",
                        order = 3.5,
                        width = "0.3",
                    },
                    displayTimer = {
                        type = "range",
                        name = function() return "Duration to display effect for "..castType.." casts (s)" end,
                        min = 0, max = 5, step = 0.05,
                        order = 4,
                        width = 1.5,
                        get = function() return cfg.displayTimer[castType] end,
                        set = function(_, val)
                            cfg.displayTimer[castType] = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                },
                gap3 = {
                        hidden = function() return type ~= "cancelled" and castType ~= "cancelled" end,
                        type = "description",
                        name = "",
                        order = 5.5,
                        width = "full",
                    },
                description = {
                        hidden = function() return type ~= "cancelled" and castType ~= "cancelled" end,
                        type = "description",
                        name = function() return UIOptions.ColorText(UIOptions.turquoise, "This option is used to determine whether a channelled cast was cancelled or not. If the cast stops with less time remaining than this threshold, it will be considered finished. (1s = 1000ms)") end,
                        order = 6,
                    },
                channelError = {
                        hidden = function() return type ~= "cancelled" and castType ~= "channel" end,
                        type = "range",
                        name = function() return "Channel error threshold (ms)" end,
                        desc = function() return "This option is used to determine whether a channelled cast was cancelled or not. If the cast stops with less time remaining than this threshold, it will be considered finished. (1s = 1000ms)" end,
                        min = 0, max = 1000, step = 1,
                        order = 7,
                        width = 1.5,
                        get = function() return cfg.channelError end,
                        set = function(_, val)
                            cfg.channelError = val
                            CASTBAR_API:UpdateCastbar(unit)
                         end,
                }
            }
        }
    }
}
return mainGrp
end

local function BuildOtherArgs(args, unit)
    local cfg = GetCFG(unit, "otherFeatures")

    args.quickButtonsPlayer = {
        type = "group",
        name = "Quick Navigation",
        inline = true,
        order = 0.1,
        hidden = function() return unit ~= "player" end,
        args = createQuickButtons(unit, {"channel", "spell_que", "mirror_inverse", "interruptedEffect", "cancelledEffect"}, createNames(), createPaths(), 0.8),
    }
    args.quickButtonsOther = {
        type = "group",
        name = "Quick Navigation",
        inline = true,
        order = 0.1,
        hidden = function() return unit == "player" end,
        args = createQuickButtons(unit, {"channel", "mirror_inverse", "interruptedEffect", "cancelledEffect"}, createNames(), createPaths(), 0.8),
    }

    if unit == "player" then
        args.spellQueGrp = {
            type   = "group",
            name   = "Spell Queue",
            inline = false,
            order  = 2,
            args = {
                queueCvarGrp = {
                    type   = "group",
                    name   = "Spell Queue CVAR Options",
                    inline = true,
                    order  = 1,
                    args = {
                        queueWindowInfo = {
                            type = "description",
                            name = "This option changes the SPELL QUEUE WINDOW CVAR, which affects global spell queue timing for ALL cast bars.",
                            order = 1,
                        },
                        queueWindowCVAR = {
                            type  = "range",
                            name  = "Window Duration (ms) - CVAR",
                            min   = UIOptions.queueWindowMin, max = UIOptions.queueWindowMax, step = 10,
                            order = 2,
                            get   = function() return OtherFeatures_API:getSpellQueCVAR() end,
                            set   = function(_, val)
                                OtherFeatures_API:setSpellQueCVAR(val)
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                        
                    },
                },
                queueVisualGrp = {
                    type   = "group",
                    name   = "Spell Queue Visual Options",
                    inline = true,
                    order  = 2,
                    args = {
                        queueWindowInfo = {
                            type = "description",
                            name = "These options control the VISUAL spell queue window shown after casting a spell.",
                            order = 1,
                        },
                        showQueueWindow = {
                            type  = "toggle",
                            name  = "Show Spell Queue Window",
                            order = 2,
                            width = "full",
                            get   = function() return cfg.showQueueWindow.normal end,
                            set   = function(_, val)
                                cfg.showQueueWindow.normal = val
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                        showQueueWindowChannel = {
                            type  = "toggle",
                            name  = "Show Spell Queue Window for Channeled Spells",
                            order = 3,
                            width = "full",
                            get   = function() return cfg.showQueueWindow.channel end,
                            set   = function(_, val)
                                cfg.showQueueWindow.channel = val
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                        showQueueWindowEmpowered = {
                            type  = "toggle",
                            name  = "Show Spell Queue Window for Empowered Spells",
                            order = 4,
                            width = "full",
                            get   = function() return cfg.showQueueWindow.empowered end,
                            set   = function(_, val)
                                cfg.showQueueWindow.empowered = val
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                        queueMatchCVAR = {
                            type  = "toggle",
                            name  = "Match CVAR Duration",
                            desc  = "When enabled, the visual spell queue window duration will match the SPELL QUEUE WINDOW CVAR value.",
                            order = 5,
                            get   = function() return cfg.queueMatchCVAR end,
                            set   = function(_, val)
                                cfg.queueMatchCVAR = val
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                        queueWindow = {
                            type  = "range",
                            name  = "Window Duration (ms)",
                            min   = UIOptions.queueWindowMin, max = UIOptions.queueWindowMax, step = 10,
                            order = 6,
                            get   = function() return cfg.queueWindow end,
                            set   = function(_, val)
                                cfg.queueWindow = val
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                        queueWindowColor = {
                            type = "color",
                            name = "Window Colour",
                            hasAlpha = true,
                            order = 7,
                            get = function()
                                local c = cfg.queueWindowColour 
                                return c.r, c.g, c.b, c.a
                            end,
                            set = function(_, r,g,b,a)
                                cfg.queueWindowColour = {r=r,g=g,b=b,a=a}
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                        useQueueTexture = {
                            type  = "toggle",
                            name  = "Use texture for queue window",
                            order = 8,
                            width = "full",
                            get   = function() return cfg.useQueueTexture end,
                            set   = function(_, val)
                                cfg.useQueueTexture = val
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                        queueTextureName = {
                            type          = "select",
                            dialogControl = "LSM30_Statusbar",
                            name          = "Queue Window texture",
                            order         = 9,
                            values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                            get           = function() return cfg.queueTextureName end,
                            set           = function(_, val)
                                cfg.queueTextureName = val
                                cfg.queueTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                            disabled = function() return cfg.useQueueTexture == false end,
                        },
                    },
                },
            },
        }
    else
        args.spellQueGrp = nil
    end

    args.channelTickGrp = {
        type   = "group",
        name   = "Channeling Options",
        inline = false,
        order  = 1,
        args = {
            channelTickInfo = {
                type = "description",
                name = "These options control the appearance of tick markers shown during channeled spells. For tick timings, use the class specific settings.",
                order = 1,
            },
            showChannelTicks = {
                type  = "toggle",
                name  = "Show Channel Ticks (ON for class tick options)",
                order = 2,
                width = 1.8,
                get   = function() return cfg.showChannelTicks ~= false end,
                set   = function(_, val)
                    cfg.showChannelTicks = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            channelTickColour = {
                type = "color",
                name = "Tick Colour",
                desc = "Colour used for tick markers during channeled spells.",
                hasAlpha = true,
                order = 3,
                get = function()
                    local c = cfg.channelTickColour
                    return c.r, c.g, c.b, c.a
                end,
                set = function(_, r,g,b,a)
                    cfg.channelTickColour = {r=r,g=g,b=b,a=a}
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return cfg.showChannelTicks == false end,
                
            },
            channelTickWidth = {
                type = "range",
                name = "Tick Width",
                desc = "Thickness of tick markers during channeled spells.",
                min = UIOptions.channelTickWidthMin, max = UIOptions.channelTickWidthMax, step = 0.5,
                order = 4,
                get = function() return tonumber(cfg.channelTickWidth) end,
                set = function(_, val)
                    cfg.channelTickWidth = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return cfg.showChannelTicks == false end,
            },
            tickTexture = {
                type = "group",
                name = "Tick Texture",
                inline = true,
                order = 5,
                args = {
                    useTickTexture = {
                        type  = "toggle",
                        name  = "Use texture for ticks",
                        order = 1,
                        get   = function() return cfg.useTickTexture end,
                        set   = function(_, val)
                            cfg.useTickTexture = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    tickTextureName = {
                        type          = "select",
                        dialogControl = "LSM30_Statusbar",
                        name          = "Tick texture",
                        order         = 2,
                        values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                        get           = function() return cfg.tickTextureName end,
                        set           = function(_, val)
                            cfg.tickTextureName = val
                            cfg.tickTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                        disabled = function() return cfg.useTickTexture == false end,
                    },
                }
            }
        },
    }

    args.inversMirrorGrp = {
        type   = "group",
        name   = "Inverse/Mirror Bar",
        inline = false,
        order  = 3,
        args = {
            inverseGrp = {
                type = "group",
                name = "Inverse Bar Options",
                inline = true,
                order = 1,
                args = {
                    inverseTagInfo = {
                        type = "description",
                        name = "These settings invert the bar animation.",
                        order = 1,
                    },
                    inverseBarCast = {
                        type  = "toggle",
                        name  = "Enable Inverse Bar Normal Cast (drain)",
                        order = 2,
                        width = "full",
                        get   = function() return cfg.invertBar.normal end,
                        set   = function(_, val)
                            cfg.invertBar.normal = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    inverseBarChannel = {
                        type  = "toggle",
                        name  = "Enable Inverse Bar Channelled Cast (fill)",
                        order = 3,
                        width = "full",
                        get   = function() return cfg.invertBar.channel end,
                        set   = function(_, val)
                            cfg.invertBar.channel = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    inverseBarEmpowered = {
                        type  = "toggle",
                        name  = "Enable Inverse Bar Empowered Cast (drain)",
                        order = 4,
                        width = "full",
                        get   = function() return cfg.invertBar.empowered end,
                        set   = function(_, val)
                            cfg.invertBar.empowered = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                }
            },
            mirrorGrp = {
                type = "group",
                name = "Mirror Bar Options",
                inline = true,
                order = 2,
                args = {
                    mirrorTagInfo = {
                        type = "description",
                        name = "Changes the direction of fill/drain. By default it is right->left for fill and left->right for drain, this option makes it the opposite.",
                        order = 1,
                    },
                    mirrorBarCast = {
                        type  = "toggle",
                        name  = "Enable Mirror Bar Normal Cast",
                        order = 2,
                        width = "full",
                        get   = function() return cfg.mirrorBar.normal end,
                        set   = function(_, val)
                            cfg.mirrorBar.normal = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    mirrorBarChannel = {
                        type  = "toggle",
                        name  = "Enable Mirror Bar Channelled Cast",
                        order = 3,
                        width = "full",
                        get   = function() return cfg.mirrorBar.channel end,
                        set   = function(_, val)
                            cfg.mirrorBar.channel = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    mirrorBarEmpowered = {
                        type  = "toggle",
                        name  = "Enable Mirror Bar Empowered Cast",
                        order = 4,
                        width = "full",
                        get   = function() return cfg.mirrorBar.empowered end,
                        set   = function(_, val)
                            cfg.mirrorBar.empowered = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                }
            }
        },
    }
    
    args.kickedGrp = {
        type = "group",
        name = "Interrupted Effect",
        inline = false,
        order = 4,
        args = {
            kickedCancelledInfo = {
                type = "description",
                name = function() return UIOptions.ColorText(UIOptions.turquoise, "These options control the display of interrupted effects that are caused by the players. Interrupted happens when a unit gets kicked.") end,
                order = 0,
            },
            normalGrp = BuildKickedCancelledArgs(unit, cfg.interruptedEffect, "normal", "interrupted", 1),
            channelGrp = BuildKickedCancelledArgs(unit, cfg.interruptedEffect, "channel", "interrupted", 2),
            empoweredGrp = BuildKickedCancelledArgs(unit, cfg.interruptedEffect, "empowered", "interrupted", 3),
        }
    }

    args.cancelledGrp = {
        type = "group",
        name = "Cancelled Effect",
        inline = false,
        order = 5,
        args = {
            kickedCancelledInfo = {
                type = "description",
                name = function() return UIOptions.ColorText(UIOptions.turquoise, "These options control the display of cancelled effects that are caused by the players. Cancelled happens when a unit stops the cast on its own, through failure or if it gets CCed.") end,
                order = 0,
            },
            normalGrp = BuildKickedCancelledArgs(unit, cfg.cancelledEffect, "normal", "cancelled", 1),
            channelGrp = BuildKickedCancelledArgs(unit, cfg.cancelledEffect, "channel", "cancelled", 2),
            empoweredGrp = BuildKickedCancelledArgs(unit, cfg.cancelledEffect, "empowered", "cancelled", 3),
        }
    }

    if unit == "player" then
        args.cancelledGrp.args.filterGroup = UIStructures:BuildAbilityFilterSectionPlayer(cfg.cancelledEffect, unit, true, "Blacklist/Whitelist cancelled spells", 4)
    else
        args.cancelledGrp.args.filterGroup = nil
    end
end


-- Public builder
function Opt.BuildGeneralSettingsOtherFeaturesArgs(unit, opts)
    opts = opts or {}
    local args = {}

    BuildOtherArgs(args, unit)

    return args
end
