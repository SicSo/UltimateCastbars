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

function OtherFeatures_API:BuildInterruptedOptions(unit, cfg)
     local kickedGrp = {
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
    return kickedGrp
end


function OtherFeatures_API:BuildCancelledOptions(unit, cfg)
    local cancelledGrp = {
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
    return cancelledGrp
end

