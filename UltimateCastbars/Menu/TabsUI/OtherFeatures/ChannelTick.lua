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


function OtherFeatures_API:BuildChannelTickOptions(unit, cfg)
    local channelTickGrp = {
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
    return channelTickGrp
end