local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions

local LSM  = UCB.LSM

local function BuildUninterruptableArgs(args, unit)
    local cfg = GetCfg(unit).uninterruptible

    args.uninterruptibleGroup = {
        type   = "group",
        name   = "Uninterruptible options",
        inline = true,
        order  = 2,
        args = {
            uninterruptibleEnabled = {
                type  = "toggle",
                name  = "Enable uninterruptible effects",
                order = 1,
                width = 1.3,
                get = function() return cfg.showUninterruptible end,
                set = function(_, val)
                    cfg.showUninterruptible = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            uninterruptibleFill = {
                type  = "toggle",
                name  = "Show uninterruptible fill",
                desc  = "Fill the uninterruptible cast bar to show progress.",
                order = 2,
                width = 1.3,
                get = function() return cfg.showUninterruptibleFill end,
                set = function(_, val)
                    cfg.showUninterruptibleFill = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            uninterruptibleBackground = {
                type  = "toggle",
                name  = "Show uninterruptible background",
                desc  = "Show a background for the uninterruptible cast bar.",
                order = 3,
                width = 1.3,
                get = function() return cfg.showUninterruptibleBackground end,
                set = function(_, val)
                    cfg.showUninterruptibleBackground = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            fillOptionsGrp = {
                type = "group",
                name = "Fill options",
                inline = true,
                order = 4,
                hidden = function() return not cfg.showUninterruptibleFill end,
                args = {
                    fillTexture = {
                        type          = "select",
                        dialogControl = "LSM30_Statusbar",
                        name          = "Fill texture",
                        order         = 1,
                        values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                        get           = function() return cfg.fillTextureName end,
                        set           = function(_, val)
                            cfg.fillTextureName = val
                            cfg.fillTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    gap = {
                        type = "description",
                        name = " ",
                        order = 1.5,
                        width = 0.2,
                    },
                    fillColour = {
                        type = "color",
                        name = "Fill colour",
                        desc = "Colour of the uninterruptable cast bar fill.",
                        order = 2,
                        hasAlpha = true,
                        get = function()
                            local c = cfg.fillColour
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            cfg.fillColour = {r=r, g=g, b=b, a=a}
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                },
            },
            backgroundOptionsGrp = {
                type = "group",
                name = "Background options",
                inline = true,
                order = 5,
                hidden = function() return not cfg.showUninterruptibleBackground end,
                args = {
                    backgroundUseTexture = {
                        type = "toggle",
                        name = "Use texture for background",
                        desc = "If enabled, the background will use a texture. If disabled, it will use a solid colour.",
                        order = 1,
                        get = function() return cfg.backgroundUseTexture end,
                        set = function(_, val)
                            cfg.backgroundUseTexture = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    gap = {
                        type = "description",
                        name = " ",
                        order = 1.5,
                        width = 0.2,
                    },
                    backgroundTexture = {
                        type          = "select",
                        dialogControl = "LSM30_Statusbar",
                        name          = "Background texture",
                        order         = 2,
                        disabled     = function() return not cfg.backgroundUseTexture end,
                        values        = function() return LSM:HashTable(LSM.MediaType.BACKGROUND) end,
                        get           = function() return cfg.backgroundTextureName end,
                        set           = function(_, val)
                            cfg.backgroundTextureName = val
                            cfg.backgroundTexture = LSM:Fetch(LSM.MediaType.BACKGROUND, val)
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    gap2 = {
                        type = "description",
                        name = " ",
                        order = 2.5,
                        width = 0.2,
                    },
                    backgroundColour = {
                        type = "color",
                        name = "Background colour",
                        desc = "Colour of the uninterruptible cast bar background.",
                        order = 3,
                        hasAlpha = true,
                        get = function()
                            local c = cfg.backgroundColour
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            cfg.backgroundColour = {r=r, g=g, b=b, a=a}
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                },
            }
        },
    }
    args.unKickable = {
        type   = "group",
        name   = "Kick/Interrupt options",
        inline = true,
        order  = 3,
        args ={
            kickTickGrp = {
                type = "group",
                name = "Kick/Interrupt tick options",
                inline = true,
                order = 1,
                args = {
                    kickTickEnabled = {
                        type  = "toggle",
                        name  = "Show kick/interrupt tick",
                        desc  = "Show ticks on the cast bar for when a cast can be kicked or interrupted.",
                        order = 1,
                        width = "full",
                        get = function() return cfg.showKickTick end,
                        set = function(_, val)
                            cfg.showKickTick = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    kickTickOptionsGrp = {
                        type = "group",
                        name = "",
                        inline = true,
                        order = 2,
                        hidden = function() return not cfg.showKickTick end,
                        args = {
                            kickTickUseTexture = {
                                type = "toggle",
                                name = "Use texture for kick/interrupt tick",
                                desc = "If enabled, the kick/interrupt tick will use a texture. If disabled, it will use a solid colour.",
                                order = 1,
                                width = 1.3,
                                get = function() return cfg.kickTickUseTexture end,
                                set = function(_, val)
                                    cfg.kickTickUseTexture = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            gap = {
                                type = "description",
                                name = " ",
                                order = 1.5,
                                width = 0.2,
                            },
                            kickTickTexture = {
                                type          = "select",
                                dialogControl = "LSM30_Statusbar",
                                name          = "Kick/Interrupt tick texture",
                                order         = 2,
                                disabled     = function() return not cfg.kickTickUseTexture end,
                                values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                                get           = function() return cfg.kickTickTextureName end,
                                set           = function(_, val)
                                    cfg.kickTickTextureName = val
                                    cfg.kickTickTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            gap2 = {
                                type = "description",
                                name = " ",
                                order = 2.5,
                                width = 0.2,
                            },
                            kickTickColour = {
                                type = "color",
                                name = "Kick/Interrupt tick colour",
                                desc = "Colour of the kick/interrupt ticks.",
                                order = 3,
                                hasAlpha = true,
                                get = function()
                                    local c = cfg.kickTickColour
                                    return c.r, c.g, c.b, c.a
                                end,
                                set = function(_, r, g, b, a)
                                    cfg.kickTickColour = {r=r, g=g, b=b, a=a}
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            kickTickWidth = {
                                type = "range",
                                name = "Kick/Interrupt tick width",
                                desc = "Width of the kick/interrupt tick in pixels.",
                                order = 4,
                                width = 1.3,
                                min = UIOptions.channelTickWidthMin,
                                max = UIOptions.channelTickWidthMax,
                                step = 0.5,
                                get = function() return cfg.kickTickWidth end,
                                set = function(_, val)
                                    cfg.kickTickWidth = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                        }
                    }
                },
            }
        }
    }
end

-- Public builder
function Opt.BuildGeneralSettingsUninterruptableArgs(unit, opts)
    opts = opts or {}
    local args = {}
    BuildUninterruptableArgs(args, unit)

    return args
end

