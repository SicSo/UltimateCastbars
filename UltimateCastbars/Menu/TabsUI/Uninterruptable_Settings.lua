local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.UNINTERRUPTIBLE_API = UCB.UNINTERRUPTIBLE_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local UNINTERRUPTIBLE = UCB.UNINTERRUPTIBLE_API

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
                width = "full",
                get = function() return cfg.showUninterruptible end,
                set = function(_, val)
                    cfg.showUninterruptible = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            disableBarUnInt = {
                type = "toggle",
                name  = "Disable bar for uninterruptible casts",
                desc  = "If enabled, the cast bar will not be shown for uninterruptible casts. Only the uninterruptible effects (fill, background, etc.) will be shown.",
                order = 1.5,
                width = "full",
                get = function() return cfg.disableBarUnInt end,
                set = function(_, val)
                    cfg.disableBarUnInt = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            uninterruptibleFill = {
                type  = "toggle",
                name  = "Show uninterruptible fill",
                desc  = "Fill the uninterruptible cast bar to show progress.",
                order = 2,
                width = 1.3,
                disabled = function() return cfg.disableBarUnInt or not cfg.showUninterruptible end,
                get = function() return cfg.showUninterruptibleFill end,
                set = function(_, val)
                    cfg.showUninterruptibleFill = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            uninterruptibleBackground = {
                type  = "toggle",
                name  = "Show uninterruptible overlay",
                desc  = "Show an overlay for the uninterruptible cast bar.",
                order = 3,
                width = 1.3,
                disabled = function() return cfg.disableBarUnInt or not cfg.showUninterruptible end,
                get = function() return cfg.showUninterruptibleBackground end,
                set = function(_, val)
                    cfg.showUninterruptibleBackground = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            uninterruptibleBorder = {
                type  = "toggle",
                name  = "Show uninterruptible border",
                desc  = "Show a border for uninterruptible casts.",
                order = 4,
                width = 1.3,
                disabled = function() return cfg.disableBarUnInt or not cfg.showUninterruptible end,
                get = function() return cfg.showUninterruptibleBorder end,
                set = function(_, val)
                    cfg.showUninterruptibleBorder = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            fillOptionsGrp = {
                type = "group",
                name = "Fill options",
                inline = true,
                order = 5,
                hidden = function() return not cfg.showUninterruptibleFill or cfg.disableBarUnInt end,
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
                name = "Overlay options",
                inline = true,
                order = 6,
                hidden = function() return not cfg.showUninterruptibleBackground or cfg.disableBarUnInt end,
                args = {
                    backgroundUseTexture = {
                        type = "toggle",
                        name = "Use texture for overlay",
                        desc = "If enabled, the overlay will use a texture. If disabled, it will use a solid colour.",
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
                        name          = "Overlay texture",
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
                        name = "Overlay colour",
                        desc = "Colour of the uninterruptible cast bar overlay.",
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
            },
            grpBorder = {
                type   = "group",
                name   = "Castbar border options",
                inline = true,
                order  = 7,
                hidden = function() return not cfg.showUninterruptibleBorder or cfg.disableBarUnInt end,
                args   = {
                    textureNameBord = {
                        type          = "select",
                        dialogControl = "LSM30_Statusbar",
                        name          = "Border Castbar Texture",
                        order         = 1,
                        values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                        get           = function() return cfg.textureNameBorder end,
                        set           = function(_, val)
                            cfg.textureNameBorder = val
                            cfg.textureBorder = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    borderColour = {
                        type = "color",
                        name = "Border Colour",
                        order = 2,
                        hasAlpha = true,
                        get = function()
                            local c = cfg.borderColour
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r,g,b,a)
                            cfg.borderColour = {r=r,g=g,b=b,a=a}
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    borderAlpha = {
                        type = "range",
                        name = "Transparency",
                        min = UIOptions.alphaMin, max = UIOptions.alphaMax, step = 0.01,
                        order = 3,
                        width = 1.5,
                        get = function()
                            local c = cfg.borderColour
                            return c.a
                        end,
                        set = function(_, val)
                            local c = cfg.borderColour 
                            c.a = val
                            cfg.borderColour = c
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    borderThickness = {
                        type = "range",
                        name = "Thickness",
                        min = UIOptions.borderThicknessMin, max = UIOptions.borderThicknessMax, step = 0.5,
                        order = 4,
                        width = 1.5,
                        get = function() return cfg.borderThickness end,
                        set = function(_, val)
                            local oldThickness = cfg.borderThickness
                            cfg.borderThickness = val
                            UNINTERRUPTIBLE:RebuildOffsets(args, cfg, unit, oldThickness, cfg.borderThicknessIcon)
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                        disabled = function() return cfg.showBorder == false end,
                    },
                    borderOffsetGrp = {
                        type   = "group",
                        name   = "Border Offsets",
                        order  = 5,
                        disabled = function() return cfg.showBorder == false end,
                        args = UNINTERRUPTIBLE:BuildBorderOffsetArgs(cfg, unit, cfg.borderThickness)
                    },
                }
            },
            grpBorderIcon = {
                type   = "group",
                name   = "Icon Border options",
                inline = true,
                order  = 8,
                hidden = function() return not cfg.showUninterruptibleBorder or cfg.disableBarUnInt end,
                args   = {
                    showBorderIcon = {
                        type  = "toggle",
                        name  = "Show Border Icon",
                        order = 1,
                        get   = function() return cfg.showUninterruptibleBorderIcon end,
                        set   = function(_, val)
                            cfg.showUninterruptibleBorderIcon = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    iconBorderOptionGrp = {
                        type = "group",
                        name = "",
                        inline = true,
                        order = 2,
                        hidden = function() return not cfg.showUninterruptibleBorderIcon end,
                        args = {
                            syncBorderIcon = {
                                type  = "toggle",
                                name  = "Sync with Castbar Border",
                                order = 2,
                                get   = function() return cfg.syncBorderIcon end,
                                set   = function(_, val)
                                    cfg.syncBorderIcon = val
                                    UNINTERRUPTIBLE:RebuildOffsets(args, cfg, unit, cfg.borderThickness, cfg.borderThicknessIcon)
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            textureNameBordIcon = {
                                type          = "select",
                                dialogControl = "LSM30_Statusbar",
                                name          = "Border Icon Texture",
                                order         = 2.4,
                                disabled     = function() return cfg.syncBorderIcon == true end,
                                values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                                get           = function() return cfg.textureNameBorderIcon end,
                                set           = function(_, val)
                                    cfg.textureNameBorderIcon = val
                                    cfg.textureBorderIcon = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            borderColourIcon = {
                                type = "color",
                                name = "Colour",
                                order = 2.5,
                                hasAlpha = true,
                                get = function()
                                    local c = cfg.borderColourIcon
                                    return c.r, c.g, c.b, c.a
                                end,
                                set = function(_, r,g,b,a)
                                    cfg.borderColourIcon = {r=r,g=g,b=b,a=a}
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                                disabled = function() return cfg.syncBorderIcon == true  end,
                            },
                            borderAlphaIcon = {
                                type = "range",
                                name = "Transparency",
                                min = UIOptions.alphaMin, max = UIOptions.alphaMax, step = 0.01,
                                order = 3,
                                get = function()
                                    local c = cfg.borderColourIcon
                                    return c.a
                                end,
                                set = function(_, val)
                                    local c = cfg.borderColourIcon 
                                    c.a = val
                                    cfg.borderColourIcon = c
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                                disabled = function() return cfg.syncBorderIcon == true end,
                            },
                            borderThicknessIcon = {
                                type = "range",
                                name = "Thickness",
                                min = UIOptions.borderThicknessMin, max = UIOptions.borderThicknessMax, step = 0.5,
                                order = 4,
                                width = 1.5,
                                get = function() return cfg.borderThicknessIcon end,
                                set = function(_, val)
                                    local oldThicknessIcon = cfg.borderThicknessIcon
                                    cfg.borderThicknessIcon = val
                                    UNINTERRUPTIBLE:RebuildOffsets(args, cfg, unit, cfg.borderThickness, oldThicknessIcon)
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                                disabled = function() return cfg.syncBorderIcon == true end,
                            },
                            borderOffsetGrp = {
                                type   = "group",
                                name   = "Border Offsets",
                                order  = 5,
                                args = UNINTERRUPTIBLE:BuildBorderOffsetIconArgs(cfg, unit, cfg.borderThickness, cfg.borderThicknessIcon)
                            },
                        }
                    }
                }
            }
        },
    }
    args.unKickable = {
        type   = "group",
        name   = "Kick/Interrupt options",
        inline = true,
        order  = 3,
        args ={
            disableBarUnKick = {
                type = "toggle",
                name  = "Disable bar for kickable/interruptible casts if you can't kick/interrupt "..UIOptions.ColorText(UIOptions.red,"(Per frame updates)"),
                desc  = "If enabled, the cast bar will not be shown for casts that can be kicked or interrupted. Only the kick/interrupt tick and until kick/interrupt tick (if enabled) will be shown.",
                order = 1,
                width = "full",
                get = function() return cfg.disableBarUnKick end,
                set = function(_, val)
                    cfg.disableBarUnKick = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            kickTickGrp = {
                type = "group",
                name = "",
                inline = true,
                order = 2,
                disabled = function() return cfg.disableBarUnKick end,
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
                        name = "Kick/Interrupt tick options",
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
                    },
                    untilKickTickEnabled = {
                        type  = "toggle",
                        name  = "Show effect until kick/interrupt tick "..UIOptions.ColorText(UIOptions.red,"(Per frame updates)"),
                        desc  = "Show a tick on the cast bar for the point at which the cast can no longer be kicked or interrupted.",
                        order = 3,
                        width = "full",
                        get = function() return cfg.showUntilKickTick end,
                        set = function(_, val)
                            cfg.showUntilKickTick = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    untilKickGrp = {
                        type = "group",
                        name = "Until kick/interrupt tick options",
                        inline = true,
                        order = 4,
                        hidden = function() return not cfg.showUntilKickTick end,
                        args = {
                            untilKickTickTexture = {
                                type          = "select",
                                dialogControl = "LSM30_Statusbar",
                                name          = "Until kick/interrupt tick texture",
                                order         = 1,
                                values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                                get           = function() return cfg.untilKickTickTextureName end,
                                set           = function(_, val)
                                    cfg.untilKickTickTextureName = val
                                    cfg.untilKickTickTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            gap2 = {
                                type = "description",
                                name = " ",
                                order = 1.5,
                                width = 0.2,
                            },
                            untilKickTickColour = {
                                type = "color",
                                name = "Until kick/interrupt tick colour",
                                desc = "Colour of the until kick/interrupt tick.",
                                order = 2,
                                hasAlpha = true,
                                get = function()
                                    local c = cfg.untilKickTickColour
                                    return c.r, c.g, c.b, c.a
                                end,
                                set = function(_, r, g, b, a)
                                    cfg.untilKickTickColour = {r=r, g=g, b=b, a=a}
                                    CASTBAR_API:UpdateCastbar(unit)
                                 end,
                            }
                        }
                    },
                    untilKickTickBackShow = {
                        type = "toggle",
                        name = "Show overlay for until kick/interrupt tick",
                        desc = "Show an overlay for the until kick/interrupt tick to make it more visible.",
                        order = 5,
                        width = "full",
                        get = function() return cfg.showUntilKickTickBackground end,
                        set = function(_, val)
                            cfg.showUntilKickTickBackground = val
                            CASTBAR_API:UpdateCastbar(unit)
                         end,
                    },
                    untilKickTickBackOptionsGrp = {
                        type = "group",
                        name = "Until kick/interrupt tick overlay options",
                        inline = true,
                        order = 6,
                        hidden = function() return not cfg.showUntilKickTickBackground end,
                        args = {
                            untilKickTickBackUseTexture = {
                                type = "toggle",
                                name = "Use texture for until kick/interrupt tick overlay",
                                desc = "If enabled, the until kick/interrupt tick overlay will use a texture. If disabled, it will use a solid colour.",
                                order = 1,
                                width = 1.3,
                                get = function() return cfg.untilKickTickBackUseTexture end,
                                set = function(_, val)
                                    cfg.untilKickTickBackUseTexture = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            gap = {
                                type = "description",
                                name = " ",
                                order = 1.5,
                                width = 0.2,
                            },
                            untilKickTickBackTexture = {
                                type          = "select",
                                dialogControl = "LSM30_Statusbar",
                                name          = "Until kick/interrupt tick overlay texture",
                                order         = 2,
                                disabled     = function() return not cfg.untilKickTickBackUseTexture end,
                                values        = function() return LSM:HashTable(LSM.MediaType.BACKGROUND) end,
                                get           = function() return cfg.untilKickTickBackTextureName end,
                                set           = function(_, val)
                                    cfg.untilKickTickBackTextureName = val
                                    cfg.untilKickTickBackTexture = LSM:Fetch(LSM.MediaType.BACKGROUND, val)
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            gap2 = {
                                type = "description",
                                name = " ",
                                order = 2.5,
                                width = 0.2,
                            },
                            untilKickTickBackColour = {
                                type = "color",
                                name = "Until kick/interrupt tick overlay colour",
                                desc = "Colour of the until kick/interrupt tick overlay.",
                                order = 3,
                                hasAlpha = true,
                                get = function()
                                    local c = cfg.untilKickTickBackColour
                                    return c.r, c.g, c.b, c.a
                                end,
                                set = function(_, r, g, b, a)
                                    cfg.untilKickTickBackColour = {r=r, g=g, b=b, a=a}
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                        }
                    }
                }
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

