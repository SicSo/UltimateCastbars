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
        latency = {"otherFeatures" , "latencyGrp"},
        mirror_inverse = {"otherFeatures" , "inversMirrorGrp"},
        interruptedEffect = {"otherFeatures" , "kickedGrp"},
        cancelledEffect = {"otherFeatures" , "cancelledGrp"},
    }
end

local function createNames()
    return {
        channel = "Channeling Options",
        spell_que = "Spell Queue",
        latency = "Latency Indicator",
        mirror_inverse = "Mirror/Inverse Bar",
        interruptedEffect = "Interrupted Effect",
        cancelledEffect = "Cancelled Effect",
    }
end



local function createQuickButtons(unit, tabs, names, paths, buttonSize)
    local buttons = {}
    for index, tab in ipairs(tabs) do
        buttons["btn_"..tab] = {
            type = "execute",dialogControl = "UCB_Button",
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
                type = "toggle", dialogControl = "UCB_CheckBox",
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
                        type = "toggle", dialogControl = "UCB_CheckBox",
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
                        type = "color", dialogControl = "UCB_ColorPicker",
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
                        type = "range", dialogControl = "UCB_Slider",
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
                channelErrorGrp = {
                        hidden = function() return type ~= "cancelled" and castType ~= "channel" end,
                        type = "group",
                        name = "Channel Error Threshold",
                        inline = true,
                        order = 5,
                        args = {
                            description = {
                                type = "description",
                                name = function() return UIOptions.ColorText(UIOptions.turquoise, "This option is used to determine whether a channelled cast was cancelled or not. If the cast stops with less time remaining than this threshold, it will be considered finished. This is done to combat latency.\nFor Player castbars, computed latency will be used by default. If you have many false positives enable this and adjust until you are happy with the outcome.\n(1s = 1000ms)") end,
                                order = 1,
                                width = "full"
                            },
                        useChannelError = {
                                type = "toggle", dialogControl = "UCB_CheckBox",
                                name = function() return "Use channel error threshold" end,
                                desc = function() return "When enabled, the channel error threshold will be used to determine whether a channelled cast was cancelled or not. If the cast stops with less time remaining than this threshold, it will be considered finished." end,
                                order = 2,
                                width = 1.5,
                                get = function() return cfg.useManualChannelError end,
                                set = function(_, val)
                                    cfg.useManualChannelError = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                        channelError = {
                                type = "range", dialogControl = "UCB_Slider",
                                name = function() return "Channel latency (ms)" end,
                                desc = function() return "This option is used to determine whether a channelled cast was cancelled or not. If the cast stops with less time remaining than this threshold, it will be considered finished. (1s = 1000ms)" end,
                                min = 0, max = 1000, step = 1,
                                order = 3,
                                width = 1.5,
                                get = function() return cfg.channelError end,
                                set = function(_, val)
                                    cfg.channelError = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            }
                        }
                },
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
        hidden = function() return not UCB:IsPlayer(unit) end,
        args = createQuickButtons(unit, {"channel", "spell_que", "latency", "mirror_inverse", "interruptedEffect", "cancelledEffect"}, createNames(), createPaths(), 0.8),
    }
    args.quickButtonsOther = {
        type = "group",
        name = "Quick Navigation",
        inline = true,
        order = 0.1,
        hidden = function() return UCB:IsPlayer(unit) end,
        args = createQuickButtons(unit, {"channel", "mirror_inverse", "interruptedEffect", "cancelledEffect"}, createNames(), createPaths(), 0.8),
    }

    if UCB:IsPlayer(unit) then
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
                            type  = "range", dialogControl = "UCB_Slider",
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
                        showGrp = {
                            type = "group",
                            name = "Show Window for:",
                            inline = true,
                            order = 1.5,
                            args = {
                                showQueueWindow = {
                                    type = "toggle", dialogControl = "UCB_CheckBox",
                                    name  = "Normal Spells",
                                    order = 1,
                                    width = 1,
                                    get   = function() return cfg.showQueueWindow.normal end,
                                    set   = function(_, val)
                                        cfg.showQueueWindow.normal = val
                                        CASTBAR_API:UpdateCastbar(unit)
                                    end,
                                },
                                showQueueWindowChannel = {
                                    type = "toggle", dialogControl = "UCB_CheckBox",
                                    name  = "Channeled Spells",
                                    order = 2,
                                    width = 1,
                                    get   = function() return cfg.showQueueWindow.channel end,
                                    set   = function(_, val)
                                        cfg.showQueueWindow.channel = val
                                        CASTBAR_API:UpdateCastbar(unit)
                                    end,
                                },
                                showQueueWindowEmpowered = {
                                    type = "toggle", dialogControl = "UCB_CheckBox",
                                    name  = "Empowered Spells",
                                    order = 3,
                                    width = 1,
                                    get   = function() return cfg.showQueueWindow.empowered end,
                                    set   = function(_, val)
                                        cfg.showQueueWindow.empowered = val
                                        CASTBAR_API:UpdateCastbar(unit)
                                    end,
                                },    
                            }
                        },
                        queueWindowtimeGrp = {
                            type = "group",
                            name = "Window Timing",
                            inline = true,
                            order = 5,
                            args = {
                                queueMatchCVAR = {
                                    type = "toggle", dialogControl = "UCB_CheckBox",
                                    name  = "Match CVAR Duration",
                                    desc  = "When enabled, the visual spell queue window duration will match the SPELL QUEUE WINDOW CVAR value.",
                                    order = 1,
                                    get   = function() return cfg.queueMatchCVAR end,
                                    set   = function(_, val)
                                        cfg.queueMatchCVAR = val
                                        CASTBAR_API:UpdateCastbar(unit)
                                    end,
                                },
                                queueWindow = {
                                    type  = "range", dialogControl = "UCB_Slider",
                                    name  = "Window Duration (ms)",
                                    min   = UIOptions.queueWindowMin, max = UIOptions.queueWindowMax, step = 10,
                                    order = 2,
                                    disabled = function() return cfg.queueMatchCVAR end,
                                    get   = function() return cfg.queueWindow end,
                                    set   = function(_, val)
                                        cfg.queueWindow = val
                                        CASTBAR_API:UpdateCastbar(unit)
                                    end,
                                },
                            }
                        },
                        queuePlacmenrGrp = {
                            type = "group",
                            name = "Window Strata (Z-index)",
                            inline = true,
                            order = 6,
                            args = {
                                queuePlacement = {
                                    type = "select",
                                    name = "Queue Window Placement",
                                    desc = "Choose whether the spell queue window appears above or below the cast fill.",
                                    order = 1,
                                    values = {
                                        over = "Over (the cast fill)",
                                        under = "Under (the cast fill)",
                                    },
                                    get = function() return cfg.queuePlacement end,
                                    set = function(_, val)
                                        cfg.queuePlacement = val
                                        CASTBAR_API:UpdateCastbar(unit)
                                    end,
                                },
                            }
                        },
                        queueWindowDesignGrp = {
                            type = "group",
                            name = "Window Design",
                            inline = true,
                            order = 7,
                            args = {
                                queueWindowColor = {
                                    type = "color", dialogControl = "UCB_ColorPicker",
                                    name = "Window Colour",
                                    hasAlpha = true,
                                    order = 1,
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
                                    type = "toggle", dialogControl = "UCB_CheckBox",
                                    name  = "Use texture for queue window",
                                    order = 2,
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
                                    order         = 3,
                                    values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                                    get           = function() return cfg.queueTextureName end,
                                    set           = function(_, val)
                                        cfg.queueTextureName = val
                                        cfg.queueTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                                        CASTBAR_API:UpdateCastbar(unit)
                                    end,
                                    disabled = function() return cfg.useQueueTexture == false end,
                                },
                            }
                        }
                    },
                },
            },
        }
        args.latencyGrp = {
            type   = "group",
            name   = "Latency Overlay",
            inline = false,
            order  = 3,
            args = {
                latencyInfo = {
                    type = "description",
                    name = function() return UIOptions.ColorText(UIOptions.turquoise, "When pressing a spell, the command to start the cast is sent to the server. Once the server receives that information, it replies with an event that starts the cast on your system. This means that on the server, the cast starts before the client and thus will finish faster than on the client. This is called cast latency and can be computed in-game. These options show an overlay on the bar for that latency. The only practical application is that you can move/end a cast before the end of the cast, and the cast will finish anyway without getting cancelled. DOES NOT WORK ON EMPOWERED CASTS.") end,
                    order = 1,
                },
                enableLatency = {
                    type = "toggle", dialogControl = "UCB_CheckBox",
                    name  = "Enable Latency Overlay",
                    order = 2,
                    width = "full",
                    get   = function() return cfg.latency.enabled end,
                    set   = function(_, val)
                        cfg.latency.enabled = val
                        CASTBAR_API:UpdateCastbar(unit)
                    end,
                },
                showLatnecyGrp = {
                    type = "group",
                    name = "Latency Overlay Show",
                    inline = true,
                    order = 3,
                    disabled = function() return not cfg.latency.enabled end,
                    args = {
                        showLatencyNormal = {
                            type = "toggle", dialogControl = "UCB_CheckBox",
                            name  = "On normal casts",
                            order = 1,
                            width = 1.5,
                            get   = function() return cfg.latency.show.normal end,
                            set   = function(_, val)
                                cfg.latency.show.normal = val
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                        showLatencyChannel = {
                            type = "toggle", dialogControl = "UCB_CheckBox",
                            name  = "On channeled casts",
                            order = 2,
                            width = 1.5,
                            get   = function() return cfg.latency.show.channel end,
                            set   = function(_, val)
                                cfg.latency.show.channel = val
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                    },
                },
                latencyOptionsGrp = {
                    type   = "group",
                    name   = "Latency Overlay Options",
                    inline = true,
                    order  = 4,
                    disabled = function() return not cfg.latency.enabled end,
                    args = {
                        latencyColor = {
                            type = "color", dialogControl = "UCB_ColorPicker",
                            name = "Overlay Colour",
                            hasAlpha = true,
                            order = 1,
                            get = function()
                                local c = cfg.latency.colour 
                                return c.r, c.g, c.b, c.a
                            end,
                            set = function(_, r,g,b,a)
                                cfg.latency.colour = {r=r,g=g,b=b,a=a}
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                        useLatencyTexture = {
                            type = "toggle", dialogControl = "UCB_CheckBox",
                            name  = "Use texture for overlay",
                            order = 2,
                            get   = function() return cfg.latency.useTexture end,
                            set   = function(_, val)
                                cfg.latency.useTexture = val
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                        latencyTextureName = {
                            type          = "select",
                            dialogControl = "LSM30_Statusbar",
                            name          = "Overlay texture",
                            order         = 3,
                            values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                            get           = function() return cfg.latency.textureName end,
                            set           = function(_, val)
                                cfg.latency.textureName = val
                                cfg.latency.texture = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                            disabled = function() return cfg.latency.useTexture == false end,
                        },
                    },
                },
            },
        }
    else
        args.spellQueGrp = nil
        args.latencyGrp = nil
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
                type = "toggle", dialogControl = "UCB_CheckBox",
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
                type = "color", dialogControl = "UCB_ColorPicker",
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
                type = "range", dialogControl = "UCB_Slider",
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
                        type = "toggle", dialogControl = "UCB_CheckBox",
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
        order  = 4,
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
                        type = "toggle", dialogControl = "UCB_CheckBox",
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
                        type = "toggle", dialogControl = "UCB_CheckBox",
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
                        type = "toggle", dialogControl = "UCB_CheckBox",
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
                        type = "toggle", dialogControl = "UCB_CheckBox",
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
                        type = "toggle", dialogControl = "UCB_CheckBox",
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
                        type = "toggle", dialogControl = "UCB_CheckBox",
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
        order = 5,
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
        order = 6,
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

    if UCB:IsPlayer(unit) then
        args.cancelledGrp.args.filterGroup = UIStructures:BuildAbilityFilterSectionPlayer(cfg.cancelledEffect.blacklistWhitelist, unit, true, "Blacklist/Whitelist cancelled spells", 4)
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
