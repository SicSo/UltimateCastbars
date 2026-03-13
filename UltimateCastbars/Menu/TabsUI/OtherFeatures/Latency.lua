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



function OtherFeatures_API:BuildLatencyOptions(unit, cfg)
    local latencyGrp = {
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
                latencyAdditionalSettingsGrp = {
                    type = "group",
                    name = "Additional Settings",
                    inline = true,
                    order = 4,
                    disabled = function() return not cfg.latency.enabled end,
                    args = {
                        worldLatencyInfo = {
                            type = "description",
                            name = UIOptions.ColorText(UIOptions.turquoise,"World latency is the latency between your client and the server, as reported by the game. Computed latency is calculated based on the time difference between when you send a spellcast command and when the server responds with the cast start event. If you have a high world latency, computed latency may be inaccurate and cause the overlay to be mistimed. You can choose to use world latency instead, but this may cause the overlay to be longer than your actual latency." ),
                            order = 1,
                        },
                        useWorldLatency = {
                            type = "toggle", dialogControl = "UCB_CheckBox",
                            name  = "Use world latency (instead of computed latency)",
                            order = 2,
                            width = 2,
                            get   = function() return cfg.latency.useWorldLatency end,
                            set   = function(_, val)
                                cfg.latency.useWorldLatency = val
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                        maxLatencyInfo = {
                            type = "description",
                            name = UIOptions.ColorText(UIOptions.turquoise,"This option caps the maximum latency that will be displayed by the overlay. This is useful if you have a high latency/latency errors and don't want the overlay to be too long." ),
                            order = 3,
                        },
                        maxLatency = {
                            type = "range", dialogControl = "UCB_Slider",
                            name = "Max latency to display (ms)",
                            desc = "This option caps the maximum latency that will be displayed by the overlay. This is useful if you have a high latency and don't want the overlay to be too long.",
                            min = 0, max = 2000, step = 10,
                            order = 4,
                            width = 2,
                            get = function() return cfg.latency.maxLatency end,
                            set = function(_, val)
                                cfg.latency.maxLatency = val
                                CASTBAR_API:UpdateCastbar(unit)
                            end,
                        },
                    },
                },

                latencyStyleOptionsGrp = {
                    type   = "group",
                    name   = "Latency Overlay Options",
                    inline = true,
                    order  = 5,
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
    return latencyGrp
end