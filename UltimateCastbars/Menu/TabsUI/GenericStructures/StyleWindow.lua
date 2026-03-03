local _, UCB = ...

UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.STYLE_API = UCB.STYLE_API or {}
UCB.UIStructures = UCB.UIStructures or {}

local CASTBAR_API = UCB.CASTBAR_API
local UIOptions = UCB.UIOptions
local STYLE_API = UCB.STYLE_API
local UIStructures = UCB.UIStructures
local LSM  = UCB.LSM

function UIStructures:BuildStyleWindow(cfg, unit)
    local args = {}
    args.grpBarTexture = {
        type   = "group",
        name   = "Texture",
        inline = true,
        order  = 1,
        args   = {
                textureName = {
                    type          = "select",
                    dialogControl = "LSM30_Statusbar",
                    name          = "Castbar",
                    order         = 1,
                    width         = 0.9,
                    values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                    get           = function() return cfg.textureName end,
                    set           = function(_, val)
                        cfg.textureName = val
                        cfg.texture = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                        CASTBAR_API:UpdateCastbar(unit)
                    end,
                },
                textureNameBack = {
                    type          = "select",
                    dialogControl = "LSM30_Statusbar",
                    name          = "Background",
                    order         = 2,
                    width         = 0.9,
                    values        = function() return LSM:HashTable(LSM.MediaType.BACKGROUND) end,
                    get           = function() return cfg.textureNameBack end,
                    set           = function(_, val)
                        cfg.textureNameBack = val
                        cfg.textureBack = LSM:Fetch(LSM.MediaType.BACKGROUND, val)
                        CASTBAR_API:UpdateCastbar(unit)
                    end,
                },
                textureNameBord = {
                    type          = "select",
                    dialogControl = "LSM30_Statusbar",
                    name          = "Border Castbar",
                    order         = 3,
                    width         = 0.9,
                    values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                    get           = function() return cfg.textureNameBorder end,
                    set           = function(_, val)
                        cfg.textureNameBorder = val
                        cfg.textureBorder = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                        CASTBAR_API:UpdateCastbar(unit)
                    end,
                },
                textureNameBordIcon = {
                    type          = "select",
                    dialogControl = "LSM30_Statusbar",
                    name          = "Border Icon",
                    order         = 4,
                    width         = 0.9,
                    values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                    get           = function() return cfg.textureNameBorderIcon end,
                    set           = function(_, val)
                        cfg.textureNameBorderIcon = val
                        cfg.textureBorderIcon = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                        CASTBAR_API:UpdateCastbar(unit)
                    end,
                }
         },
    }

    args.grpColours = {
        type   = "group",
        name   = "Colours",
        inline = true,
        order  = 2,
        args   = { 
            colourMode = {
                type  = "select",
                name  = "Cast Bar Colour Mode",
                order = 1,
                values = { class="Class Colour", ombre="Ombre (Rainbow)", custom="Custom Colour" },
                get   = function() return cfg.colourMode or "class" end,
                set   = function(_, val)
                    cfg.colourMode = val
                    CASTBAR_API:UpdateCastbar(unit) 
                end,
            },
            customEnemyColour = nil,
            gradientEnable = {
                type = "toggle",
                name = "Enable Gradient",
                order = 2,
                get = function() return cfg.gradientEnable == true end,
                set = function(_, val)
                    cfg.gradientEnable = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                hidden = function() return cfg.colourMode ~= "custom" end,
            },
            customColour = {
                type = "color",
                name = function() if cfg.gradientEnable then return "Gradient Start" else return "Colour" end end,
                order = 3,
                width = 0.8,
                hasAlpha = true,
                get = function()
                    local c = cfg.customColour
                    return c.r, c.g, c.b, c.a
                end,
                set = function(_, r,g,b,a)
                    cfg.customColour = {r=r,g=g,b=b,a=a}
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                hidden = function() return cfg.colourMode ~= "custom" end,
            },
            customColour2 = {
                type = "color",
                name = "Gradient End",
                order = 4,
                width = 0.8,
                hasAlpha = true,
                get = function()
                    local c = cfg.customColour2
                    return c.r, c.g, c.b, c.a 
                end,
                set = function(_, r,g,b,a)
                    cfg.customColour2 = {r=r,g=g,b=b,a=a}
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                hidden = function() return cfg.colourMode ~= "custom" or not cfg.gradientEnable end,
            }
        }
    }

    if not UCB:IsPlayer(unit) then
        args.grpColours.args.customEnemyColour = {
                type = "color",
                name = function() return "Enemy colour (NPC)" end,
                order = 2,
                hasAlpha = true,
                get = function()
                    local c = cfg.enemyColour
                    return c.r, c.g, c.b, c.a
                end,
                set = function(_, r,g,b,a)
                    cfg.enemyColour = {r=r,g=g,b=b,a=a}
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                hidden = function() return cfg.colourMode ~= "class" and cfg.colourMode~="ombre" end,
            }
    end

    args.grpBackground = {
        type   = "group",
        name   = "Background",
        inline = true,
        order  = 3,
        args   = {
            showBackground = {
                type  = "toggle",
                name  = "Show Background",
                order = 1,
                get   = function() return cfg.showBackground end,
                set   = function(_, val)
                    cfg.showBackground = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            colourMode = {
                type  = "select",
                name  = "Background Colour Mode",
                order = 2,
                values = { class="Class Colour", custom="Custom Colour" },
                get   = function() return cfg.bgColourMode end,
                set   = function(_, val)
                    cfg.bgColourMode = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                hidden = function() return not cfg.showBackground end,
            },
            bgColour = {
                type = "color",
                name = "Color",
                order = 3,
                hidden = function() return cfg.bgColourMode ~= "custom" end,
                hasAlpha = true,
                get = function()
                    local c = cfg.bgColour
                    return c.r, c.g, c.b, c.a
                end,
                set = function(_, r,g,b,a)
                    cfg.bgColour = {r=r,g=g,b=b,a=a}
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return cfg.showBackground == false end,
            },
            bgEnemyColour = {
                type = "color",
                name = "Enemy colour (NPC)",
                order = 3,
                hidden = function() return cfg.bgColourMode ~= "class" or UCB:IsPlayer(unit) end,
                hasAlpha = true,
                get = function()
                    local c = cfg.bgEnemyColour
                    return c.r, c.g, c.b, c.a
                end,
                set = function(_, r,g,b,a)
                    cfg.bgEnemyColour = {r=r,g=g,b=b,a=a}
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return cfg.showBackground == false end,
            },
            alphaGrp = {
                type  = "group",
                name   = "",
                order  = 4,
                inline = true,
                args = {
                    bgUseCustomAlpha = {
                        type = "toggle",
                        name = "Use custom transparency",
                        order = 1,
                        get = function() return cfg.bgUseCustomAlpha == true end,
                        set = function(_, val)
                            cfg.bgUseCustomAlpha = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                        disabled = function() return cfg.showBackground == false end,
                    },
                    bgAlpha = {
                        type = "range",
                        name = "Transparency",
                        min = UIOptions.alphaMin, max = UIOptions.alphaMax, step = 0.01,
                        order = 2,
                        width = 1.5,
                        hidden = function() return not cfg.bgUseCustomAlpha end,
                        get = function()
                            return cfg.bgAlpha
                        end,
                        set = function(_, val)
                            cfg.bgAlpha = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                        disabled = function() return cfg.showBackground == false end,
                    }
                }
            }
        }
    }

    args.effects = {
        type   = "group",
        name   = "Effects",
        inline = true,
        order  = 4,
        args   = {
            sparkGrp = {
                type   = "group",
                name   = "Spark",
                inline = true,
                order  = 1,
                args   = {
                     spark = {
                        type  = "toggle",
                        name  = function() return "Use Spark ("..UIOptions.ColorText(UIOptions.red, "per frame update if MIRRORED")..")" end,
                        order = 1,
                        width = "full",
                        get   = function() return cfg.effects.spark.enable end,
                        set   = function(_, val)
                            cfg.effects.spark.enable = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    sparkSettingsGrp = {
                        type = "group",
                        name = "",
                        inline = true,
                        order = 2,
                        hidden = function() return not cfg.effects.spark.enable end,
                        args = {
                            sparkColour = {
                                type = "color",
                                name = "Colour",
                                order = 1,
                                hasAlpha = true,
                                get = function()
                                    local c = cfg.effects.spark.colour
                                    return c.r, c.g, c.b, c.a
                                end,
                                set = function(_, r,g,b,a)
                                    cfg.effects.spark.colour = {r=r,g=g,b=b,a=a}
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            sparkWidth = {
                                type = "range",
                                name = "Width (default: 20)",
                                min = 1, max = 100, step = 1,
                                order = 2,
                                get = function() return cfg.effects.spark.width end,
                                set = function(_, val)
                                    cfg.effects.spark.width = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            sparkHeightMult = {
                                type = "range",
                                name = "Height multiplier (default 2.2)",
                                min = 0.1, max = 5, step = 0.1,
                                order = 3,
                                get = function() return cfg.effects.spark.heightMult end,
                                set = function(_, val)
                                    cfg.effects.spark.heightMult = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                        },
                    }
                }
            },
        }
    }

    args.grpBorder = {
        type   = "group",
        name   = "Border castbar",
        inline = true,
        order  = 5,
        args   = {
            showBorder = {
                type  = "toggle",
                name  = "Show Border",
                order = 1,
                get   = function() return cfg.showBorder end,
                set   = function(_, val)
                    cfg.showBorder = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            borderFillCorners = {
                type  = "toggle",
                name  = "Fill Corners",
                order = 1.5,
                get   = function() return cfg.borderFillCorners end,
                set   = function(_, val)
                    cfg.borderFillCorners = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return not cfg.showBorder end,
            },
            borderColour = {
                type = "color",
                name = "Color",
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
                disabled = function() return not cfg.showBorder end,
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
                disabled = function() return not cfg.showBorder end,
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
                    STYLE_API:RebuildOffsets(args, cfg, unit, oldThickness, cfg.borderThicknessIcon)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return not cfg.showBorder end,
            },
            borderOffsetGrp = {
                type   = "group",
                name   = "Border Offsets",
                order  = 5,
                disabled = function() return not cfg.showBorder end,
                args = STYLE_API:BuildBorderOffsetArgs(cfg, unit, cfg.borderThickness)
            },
        }
    }
    args.grpBorderIcon = {
        type   = "group",
        name   = "Border icon",
        inline = true,
        order  = 6,
        args   = {
            showBorderIcon = {
                type  = "toggle",
                name  = "Show Border Icon",
                order = 1,
                get   = function() return cfg.showBorderIcon end,
                set   = function(_, val)
                    cfg.showBorderIcon = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            syncBorderIcon = {
                type  = "toggle",
                name  = "Sync with Castbar Border",
                order = 2,
                get   = function() return cfg.syncBorderIcon end,
                set   = function(_, val)
                    cfg.syncBorderIcon = val
                    STYLE_API:RebuildOffsets(args, cfg, unit, cfg.borderThickness, cfg.borderThicknessIcon)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return not cfg.showBorderIcon end,
            },
            borderFillCornersIcon = {
                type  = "toggle",
                name  = "Fill Corners",
                order = 2.25,
                get   = function() return cfg.borderFillCornersIcon end,
                set   = function(_, val)
                    cfg.borderFillCornersIcon = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return not cfg.showBorderIcon or cfg.syncBorderIcon end,
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
                disabled = function() return not cfg.showBorderIcon or cfg.syncBorderIcon end,
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
                disabled = function() return cfg.showBorderIcon == false or cfg.syncBorderIcon == true end,
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
                    STYLE_API:RebuildOffsets(args, cfg, unit, cfg.borderThickness, oldThicknessIcon)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return cfg.showBorderIcon == false or cfg.syncBorderIcon == true end,
            },
            borderOffsetGrp = {
                type   = "group",
                name   = "Border Offsets",
                order  = 5,
                disabled = function() return cfg.showBorderIcon == false  end,
                args = STYLE_API:BuildBorderOffsetIconArgs(cfg, unit, cfg.borderThickness, cfg.borderThicknessIcon)
            },
        }
    }
    return args
end
