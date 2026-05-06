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

function OtherFeatures_API:BuildSpellQueueOptions(unit, cfg)
 local spellQueGrp = {
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
                            showQueueWindowGCD = {
                                type = "toggle", dialogControl = "UCB_CheckBox",
                                name  = "Instant GCD Spells",
                                order = 4,
                                width = 1,
                                get   = function() return cfg.showQueueWindow.gcd end,
                                set   = function(_, val)
                                    cfg.showQueueWindow.gcd = val
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
    return spellQueGrp
end