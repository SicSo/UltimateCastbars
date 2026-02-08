local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.STYLE_API = UCB.STYLE_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local STYLE_API = UCB.STYLE_API

local LSM  = UCB.LSM


local function BuildCustomisationArgs(args, unit)
    local cfg = CFG_API:Proxy(unit, {"style"})
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
            bgColour = {
                type = "color",
                name = "Color",
                order = 2,
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
            bgAlpha = {
                type = "range",
                name = "Transparency",
                min = UIOptions.alphaMin, max = UIOptions.alphaMax, step = 0.01,
                order = 3,
                width = 1.5,
                get = function()
                    local c = cfg.bgColour
                    return c.a
                end,
                set = function(_, val)
                    local c = cfg.bgColour 
                    c.a = val
                    cfg.bgColour = c
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return cfg.showBackground == false end,
            }
        }
    }

    args.grpBorder = {
        type   = "group",
        name   = "Border castbar",
        inline = true,
        order  = 4,
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
                disabled = function() return cfg.showBorder == false end,
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
                disabled = function() return cfg.showBorder == false end,
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
                    STYLE_API:RebuildOffsets(args, cfg, UIOptions, unit, oldThickness, cfg.borderThicknessIcon)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return cfg.showBorder == false end,
            },
            borderOffsetGrp = {
                type   = "group",
                name   = "Border Offsets",
                order  = 5,
                disabled = function() return cfg.showBorder == false end,
                args = STYLE_API:BuildBorderOffsetArgs(cfg, UIOptions, unit, cfg.borderThickness)
            },
        }
    }
    args.grpBorderIcon = {
        type   = "group",
        name   = "Border icon",
        inline = true,
        order  = 5,
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
                    STYLE_API:RebuildOffsets(args, cfg, UIOptions, unit)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return cfg.showBorderIcon == false end,
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
                disabled = function() return cfg.showBorderIcon == false or cfg.syncBorderIcon == true end,
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
                    STYLE_API:RebuildOffsets(args, cfg, UIOptions, unit, cfg.borderThickness, oldThicknessIcon)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return cfg.showBorderIcon == false or cfg.syncBorderIcon == true end,
            },
            borderOffsetGrp = {
                type   = "group",
                name   = "Border Offsets",
                order  = 5,
                disabled = function() return cfg.showBorderIcon == false  end,
                args = STYLE_API:BuildBorderOffsetIconArgs(cfg, UIOptions, unit, cfg.borderThickness, cfg.borderThicknessIcon)
            },
        }
    }
end

-- Public builder
function Opt.BuildGeneralSettingsStyleArgs(unit, opts)
    opts = opts or {}
    local args = {}
    BuildCustomisationArgs(args, unit)

    return args
end


