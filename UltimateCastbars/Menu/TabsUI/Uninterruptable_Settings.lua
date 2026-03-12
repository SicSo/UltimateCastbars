local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.UNINTERRUPTIBLE_API = UCB.UNINTERRUPTIBLE_API or {}
UCB.UIStructures = UCB.UIStructures or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local UIOptions = UCB.UIOptions
local UNINTERRUPTIBLE = UCB.UNINTERRUPTIBLE_API
local UIStructures = UCB.UIStructures

local LSM  = UCB.LSM

local function BuildUninterruptableArgs(args, unit)
    local cfg = GetCFG(unit, "uninterruptible")

    args.uninterruptibleGroup = {
        type   = "group",
        name   = "Uninterruptible casts",
        inline = false,
        order  = 2,
        args = {
            descUnint = {
                type = "description",
                name = function() return UIOptions.ColorText(UIOptions.turquoise,"These options are for UNINTERRUPTIBLE casts. These casts cannot be interrupted by kick either by default or through a kick imunity gain.") end,
                order = 0,
                width = "full",
            },
            hideBarUnInt = {
                type = "toggle", dialogControl = "UCB_CheckBox",
                name  = "Hide bar for uninterruptible casts",
                desc  = "If enabled, the cast bar will not be shown for uninterruptible casts. Only the uninterruptible effects (fill, background, etc.) will be shown.",
                order = 1,
                width = "full",
                get = function() return cfg.disableBarUnInt end,
                set = function(_, val)
                    cfg.disableBarUnInt = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            alphaGrp = {
                type = "group",
                name = "",
                inline = true,
                order = 2,
                disabled = function() return cfg.disableBarUnInt end,
                args = {
                    uninterruptibleChnageAlpha = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name = "Change transparency uninterruptible",
                        desc = "If enabled, the transparency of the cast bar will be changed for uninterruptible casts to make them more distinguishable.",
                        order = 1,
                        width ="full",
                        get = function() return cfg.changeAlphaBarUnint end,
                        set = function(_, val)
                            cfg.changeAlphaBarUnint = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    changeAlphaOptionsGrp = {
                        type = "group",
                        name = "Alpha Settings",
                        inline = true,
                        order = 2,
                        hidden = function() return not cfg.changeAlphaBarUnint or cfg.disableBarUnInt end,
                        args = {
                            includeIconAlphaUnint = {
                                type = "toggle", dialogControl = "UCB_CheckBox",
                                name  = "Include cast icon",
                                desc  = "If enabled, the cast icon will also have its transparency changed for uninterruptible casts.",
                                order = 1,
                                width = 1.3,
                                get = function() return cfg.includeIconAlphaUnint end,
                                set = function(_, val)
                                    cfg.includeIconAlphaUnint = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            uninterruptibleAlpha = {
                                type = "range", dialogControl = "UCB_Slider",
                                name = "Uninterruptible cast bar transparency",
                                min = UIOptions.alphaMin, max = UIOptions.alphaMax, step = 0.01,
                                order = 2,
                                width = 1.3,
                                get = function() return cfg.alphaBarUnint end,
                                set = function(_, val)
                                    cfg.alphaBarUnint = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                        },
                    },
                }
            },
            unintFillGrp = {
                type = "group",
                name = "",
                inline = true,
                order = 3,
                disabled = function() return cfg.disableBarUnInt end,
                args = {
                     uninterruptibleFill = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name  = "Show custom fill for uninterruptible casts",
                        desc  = "Fill the uninterruptible cast bar to show progress.",
                        order = 1,
                        width = "full",
                        disabled = function() return cfg.disableBarUnInt end,
                        get = function() return cfg.showUninterruptibleFill end,
                        set = function(_, val)
                            cfg.showUninterruptibleFill = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    fillOptionsGrp = {
                        type = "group",
                        name = "Fill options",
                        inline = true,
                        order = 2,
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
                                type = "color", dialogControl = "UCB_ColorPicker",
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
                }
            },
            unintBackGrp = {
                type = "group",
                name = "",
                inline = true,
                order = 4,
                disabled = function() return cfg.disableBarUnInt end,
                args = {
                    uninterruptibleBackground = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name  = "Show overlay for uninterruptible casts",
                        desc  = "Show an overlay for the uninterruptible cast bar.",
                        order = 3,
                        width = "full",
                        disabled = function() return cfg.disableBarUnInt end,
                        get = function() return cfg.showUninterruptibleBackground end,
                        set = function(_, val)
                            cfg.showUninterruptibleBackground = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    unintBackOptionsGrp = {
                        type = "group",
                        name = "Overlay options",
                        inline = true,
                        order = 6,
                        hidden = function() return not cfg.showUninterruptibleBackground or cfg.disableBarUnInt end,
                        args = {
                            backgroundUseTexture = {
                                type = "toggle", dialogControl = "UCB_CheckBox",
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
                                type = "color", dialogControl = "UCB_ColorPicker",
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
                }
            },
            unintBorderGrp = {
                type = "group",
                name = "",
                inline = true,
                order = 5,
                disabled = function() return cfg.disableBarUnInt end,
                args = {
                    uninterruptibleBorder = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name  = "Show border for uninterruptible casts",
                        desc  = "Show a border for uninterruptible casts.",
                        order = 1,
                        width = "full",
                        disabled = function() return cfg.disableBarUnInt end,
                        get = function() return cfg.showUninterruptibleBorder end,
                        set = function(_, val)
                            cfg.showUninterruptibleBorder = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    grpBorder = {
                        type   = "group",
                        name   = "Castbar border options",
                        inline = true,
                        order  = 2,
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
                            borderFillCorners = {
                                type = "toggle", dialogControl = "UCB_CheckBox",
                                name = "Fill corners of border",
                                desc = "If enabled, the corners of the border will be filled in. If disabled, the corners will be hollow.",
                                order = 1.5,
                                get = function() return cfg.borderFillCorners end,
                                set = function(_, val)
                                    cfg.borderFillCorners = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            borderColour = {
                                type = "color", dialogControl = "UCB_ColorPicker",
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
                                type = "range", dialogControl = "UCB_Slider",
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
                                type = "range", dialogControl = "UCB_Slider",
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
                        order  = 3,
                        hidden = function() return not cfg.showUninterruptibleBorder or cfg.disableBarUnInt end,
                        args   = {
                            showBorderIcon = {
                                type = "toggle", dialogControl = "UCB_CheckBox",
                                name  = "Show border icon for uninterruptible casts",
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
                                        type = "toggle", dialogControl = "UCB_CheckBox",
                                        name  = "Sync border icon with Castbar Border",
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
                                    borderFillCornersIcon = {
                                        type = "toggle", dialogControl = "UCB_CheckBox",
                                        name = "Fill corners of border",
                                        desc = "If enabled, the corners of the border will be filled in. If disabled, the corners will be hollow.",
                                        order = 2.45,
                                        get = function() return cfg.borderFillCornersIcon end,
                                        set = function(_, val)
                                            cfg.borderFillCornersIcon = val
                                            CASTBAR_API:UpdateCastbar(unit)
                                        end,
                                        disabled = function() return cfg.syncBorderIcon == true end,
                                    },
                                    borderColourIcon = {
                                        type = "color", dialogControl = "UCB_ColorPicker",
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
                                        type = "range", dialogControl = "UCB_Slider",
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
                                        type = "range", dialogControl = "UCB_Slider",
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
                }
            },
        },
    }
    if UCB:IsPlayer(unit) then
        args.uninterruptibleGroup.args.filterGroup = UIStructures:BuildAbilityFilterSectionPlayer(cfg.blacklistWhitelist, unit, true, "Blacklist/Whitelist spells", 6)
    else
        args.uninterruptibleGroup.args.filterGroup = nil
    end

    --------------------------------------------------------------------------------------------------------------------------
    args.unKickable = {
        type   = "group",
        name   = "Kick/Interrupt casts",
        inline = false,
        order  = 3,
        args ={
            descKick = {
                type = "description",
                name = function() return UIOptions.ColorText(UIOptions.turquoise,"These options are for casts that can be kicked or interrupted. They will not have any effect on UNINTERRUPTIBLE casts or if you DO NOT HAVE a Kick/Interrupt.") end,
                order = 0,
                width = "full",
            },
            disableBarUnKick = {
                type = "toggle", dialogControl = "UCB_CheckBox",
                name  = "Hide bar for kickable/interruptible casts if you can't kick/interrupt. Shows bar ONLY when the kick is available. "..UIOptions.ColorText(UIOptions.red,"(Per frame updates)"),
                desc  = "If enabled, the cast bar will not be shown for casts that can be kicked or interrupted. Only the kick/interrupt tick and until kick/interrupt tick (if enabled) will be shown.",
                order = 1,
                width = "full",
                get = function() return cfg.disableBarUnKick end,
                set = function(_, val)
                    cfg.disableBarUnKick = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            alphaGrp = {
                type = "group",
                name = "",
                inline = true,
                order = 2,
                disabled = function() return cfg.disableBarUnKick end,
                args = {
                     changeAlphaBarUnKick = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name = "Change transparency when not kickable/interruptible",
                        desc = "If enabled, the transparency of the cast bar will be changed for casts that can be kicked or interrupted but currently can't be to make them more distinguishable.",
                        order = 1,
                        width = "full",
                        get = function() return cfg.changeAlphaBarUnKick end,
                        set = function(_, val)
                            cfg.changeAlphaBarUnKick = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    alphaOptionsGrp = {
                        type = "group",
                        name = "Alpha Settings",
                        inline = true,
                        order = 2,
                        hidden = function() return cfg.disableBarUnKick or not cfg.changeAlphaBarUnKick end,
                        args = {
                            descAlpha = {
                                type = "description",
                                name = UCB.UIOptions.ColorText(UIOptions.turquoise,"By default, the alpha is set semi-dynamic, meaning a cast will stay on the same alpha if the kick is on cooldown at the start of the cast. Dynamic toggle makes it change alpha during the cast."),
                                order = 0,
                                width = "full",
                            },
                            dynamicKickAlphaBar = {
                                type = "toggle", dialogControl = "UCB_CheckBox",
                                name = "Dynamic transparency for kickable/interruptible casts "..UCB.UIOptions.ColorText(UIOptions.red,"(Per frame updates)"),
                                desc = "If enabled, the transparency of the cast bar will change dynamically based on whether the cast can currently be kicked or interrupted if the cast is kickable or interruptible.",
                                order = 0.5,
                                width = "full",
                                get = function() return cfg.dynamicKickAlphaBar end,
                                set = function(_, val)
                                    cfg.dynamicKickAlphaBar = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            includeIconAlphaUnKick = {
                                type = "toggle", dialogControl = "UCB_CheckBox",
                                name  = "Include cast icon",
                                desc  = "If enabled, the cast icon will also have its transparency changed for casts that can be kicked or interrupted but currently can't be.",
                                order = 1,
                                width = 1.3,
                                get = function() return cfg.includeIconAlphaUnKick end,
                                set = function(_, val)
                                    cfg.includeIconAlphaUnKick = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            unKickableAlpha = {
                                type = "range", dialogControl = "UCB_Slider",
                                name = "Not kickable/interruptible cast bar transparency",
                                min = UIOptions.alphaMin, max = UIOptions.alphaMax, step = 0.01,
                                order = 2,
                                width = 1.3,
                                get = function() return cfg.alphaBarUnKick end,
                                set = function(_, val)
                                    cfg.alphaBarUnKick = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                        },
                    },
                }
            },
            kickTickGrp = {
                type = "group",
                name = "",
                inline = true,
                order = 3,
                disabled = function() return cfg.disableBarUnKick end,
                args = {
                    kickTickEnabled = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
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
                                type = "toggle", dialogControl = "UCB_CheckBox",
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
                                type = "color", dialogControl = "UCB_ColorPicker",
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
                                type = "range", dialogControl = "UCB_Slider",
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
                }
            },
            untilKickTickFillGrp = {
                type = "group",
                name = "",
                inline = true,
                order = 4,
                disabled = function() return cfg.disableBarUnKick end,
                args = {
                    untilKickTickEnabled = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name  = "Show custom fillbar until kick/interrupt tick "..UIOptions.ColorText(UIOptions.red,"(Per frame updates)"),
                        desc  = "Show a tick on the cast bar for the point at which the cast can no longer be kicked or interrupted.",
                        order = 1,
                        width = "full",
                        get = function() return cfg.showUntilKickTick end,
                        set = function(_, val)
                            cfg.showUntilKickTick = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    untilKickFillOptionsGrp = {
                        type = "group",
                        name = "Until kick/interrupt tick fillbar options",
                        inline = true,
                        order = 2,
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
                                type = "color", dialogControl = "UCB_ColorPicker",
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
                }
            },
            untilKickTickOverlayGrp = {
                type = "group",
                name = "",
                inline = true,
                order = 5,
                disabled = function() return cfg.disableBarUnKick end,
                args = {
                    untilKickTickOverlayShow = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name = "Show overlay for bar until kick/interrupt tick",
                        desc = "Show an overlay for the until kick/interrupt tick to make it more visible.",
                        order = 1,
                        width = "full",
                        get = function() return cfg.showUntilKickTickBackground end,
                        set = function(_, val)
                            cfg.showUntilKickTickBackground = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    untilKickTickOverlayOptionsGrp = {
                        type = "group",
                        name = "Until kick/interrupt tick overlay options",
                        inline = true,
                        order = 2,
                        hidden = function() return not cfg.showUntilKickTickBackground end,
                        args = {
                            untilKickTickOverlayUseTexture = {
                                type = "toggle", dialogControl = "UCB_CheckBox",
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
                            untilKickTickOverlayTexture = {
                                type          = "select",
                                dialogControl = "LSM30_Statusbar",
                                name          = "Until kick/interrupt tick overlay texture",
                                order         = 2,
                                disabled     = function() return not cfg.untilKickTickBackUseTexture end,
                                values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                                get           = function() return cfg.untilKickTickBackTextureName end,
                                set           = function(_, val)
                                    cfg.untilKickTickBackTextureName = val
                                    cfg.untilKickTickBackTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            gap2 = {
                                type = "description",
                                name = " ",
                                order = 2.5,
                                width = 0.2,
                            },
                            untilKickTickOverlayColour = {
                                type = "color", dialogControl = "UCB_ColorPicker",
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
            },
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

