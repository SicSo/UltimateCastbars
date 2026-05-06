local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}
UCB.UIStructures = UCB.UIStructures or {}
UCB.STYLE_API = UCB.STYLE_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local UIOptions = UCB.UIOptions
local OtherFeatures_API = UCB.OtherFeatures_API
local UIStructures = UCB.UIStructures
local STYLE_API = UCB.STYLE_API
local LSM  = UCB.LSM

local function BuildBackgroundStyleArgs(bg, unit)
    return {
         showBackground = {
            type = "toggle", dialogControl = "UCB_CheckBox",
            name  = "Show Background",
            order = 1,
            width = "full",
            get   = function() return bg.showBackground end,
            set   = function(_, val)
                bg.showBackground = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
        textureNameBack = {
            type          = "select",
            dialogControl = "LSM30_Statusbar",
            name          = "Background Texture",
            order         = 2,
            width         = 0.9,
            values        = function() return LSM:HashTable(LSM.MediaType.BACKGROUND) end,
            get           = function() return bg.textureNameBack end,
            set           = function(_, val)
                bg.textureNameBack = val
                bg.textureBack = LSM:Fetch(LSM.MediaType.BACKGROUND, val)
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
        --[[
        bgColourMode = {
            type = "select",
            name = "Colour Mode",
            order = 3,
            width = 1.2,
            values = {
                custom = "Custom colour",
                class  = "Class colour",
            },
            get = function()
                return bg.bgColourMode or "custom"
            end,
            set = function(_, val)
                bg.bgColourMode = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
            disabled = function() return bg.showBackground == false end,
        },
        --]]
        bgEnemyColour = {
            type = "toggle", dialogControl = "UCB_CheckBox",
            name = "Use enemy colour for non-player units",
            order = 4,
            width = 1.4,
            get = function()
                return bg.bgEnemyColour == true
            end,
            set = function(_, val)
                bg.bgEnemyColour = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
            hidden = function()
                return (bg.bgColourMode or "custom") ~= "class"
            end,
            disabled = function() return bg.showBackground == false end,
        },

        bgColour = {
            type = "color", dialogControl = "UCB_ColorPicker",
            name = "Color",
            order = 5,
            hasAlpha = true,
            get = function()
                local c = bg.bgColour
                return c.r, c.g, c.b, c.a
            end,
            set = function(_, r, g, b, a)
                bg.bgColour = { r = r, g = g, b = b, a = a }
                CASTBAR_API:UpdateCastbar(unit)
            end,
            hidden = function()
                return (bg.bgColourMode or "custom") ~= "custom"
            end,
            disabled = function() return bg.showBackground == false end,
        },

        alphaGrp = {
            type   = "group",
            name   = "",
            order  = 6,
            inline = true,
            args = {
                bgUseCustomAlpha = {
                    type = "toggle", dialogControl = "UCB_CheckBox",
                    name = "Use custom transparency",
                    order = 1,
                    get = function() return bg.bgUseCustomAlpha == true end,
                    set = function(_, val)
                        bg.bgUseCustomAlpha = val
                        CASTBAR_API:UpdateCastbar(unit)
                    end,
                    disabled = function() return bg.showBackground == false end,
                },
                bgAlpha = {
                    type = "range", dialogControl = "UCB_Slider",
                    name = "Transparency",
                    min = UIOptions.alphaMin,
                    max = UIOptions.alphaMax,
                    step = 0.01,
                    order = 2,
                    width = 1.5,
                    hidden = function() return not bg.bgUseCustomAlpha end,
                    get = function()
                        return bg.bgAlpha
                    end,
                    set = function(_, val)
                        bg.bgAlpha = val
                        CASTBAR_API:UpdateCastbar(unit)
                    end,
                    disabled = function() return bg.showBackground == false end,
                }
            }
        }
    }
end

local function BuildBorderArgs(bg, bigCFG, unit, rootArgs)
    return {
        showBorder = {
            type = "toggle", dialogControl = "UCB_CheckBox",
            name = "Show Border",
            order = 0,
            width = "full",
            get = function() return bg.showBorder end,
            set = function(_, val)
                bg.showBorder = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
        includeBorderInWidth = {
            type = "toggle", dialogControl = "UCB_CheckBox",
            name = "Include border in width",
            order = 0.25,
            disabled = function() return not bg.showBorder end,
            get = function() return bigCFG.includeBorderInWidth == true end,
            set = function(_, val)
                bigCFG.includeBorderInWidth = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
        includeBorderInHeight = {
            type = "toggle", dialogControl = "UCB_CheckBox",
            name = "Include border in height",
            order = 0.5,
            disabled = function() return not bg.showBorder end,
            get = function() return bigCFG.includeBorderInHeight == true end,
            set = function(_, val)
                bigCFG.includeBorderInHeight = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
        gap1 = {
            type = "description",
            name = "",
            order = 0.75,
            width = "full",
        },
        textureNameBord = {
            type          = "select",
            dialogControl = "LSM30_Statusbar",
            name          = "Border Texture",
            order         = 1,
            width         = 0.9,
            disabled = function() return not bg.showBorder end,
            values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
            get           = function() return bg.textureNameBorder end,
            set           = function(_, val)
                bg.textureNameBorder = val
                bg.textureBorder = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
        borderFillCorners = {
            type = "toggle", dialogControl = "UCB_CheckBox",
            name = "Fill Corners",
            order = 3,
            get = function() return bg.borderFillCorners end,
            set = function(_, val)
                bg.borderFillCorners = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
            disabled = function() return not bg.showBorder end,
        },
        borderColour = {
            type = "color", dialogControl = "UCB_ColorPicker",
            name = "Color",
            order = 4,
            hasAlpha = true,
            get = function()
                local c = bg.borderColour
                return c.r, c.g, c.b, c.a
            end,
            set = function(_, r, g, b, a)
                bg.borderColour = { r = r, g = g, b = b, a = a }
                CASTBAR_API:UpdateCastbar(unit)
            end,
            disabled = function() return not bg.showBorder end,
        },
        borderAlpha = {
            type = "range", dialogControl = "UCB_Slider",
            name = "Transparency",
            min = UIOptions.alphaMin,
            max = UIOptions.alphaMax,
            step = 0.01,
            order = 5,
            width = 1.5,
            get = function()
                local c = bg.borderColour
                return c.a
            end,
            set = function(_, val)
                local c = bg.borderColour
                c.a = val
                bg.borderColour = c
                CASTBAR_API:UpdateCastbar(unit)
            end,
            disabled = function() return not bg.showBorder end,
        },
        borderThickness = {
            type = "range", dialogControl = "UCB_Slider",
            name = "Thickness",
            min = UIOptions.borderThicknessMin,
            max = UIOptions.borderThicknessMax,
            step = 0.5,
            order = 6,
            width = 1.5,
            get = function() return bg.borderThickness end,
            set = function(_, val)
                local oldThickness = bg.borderThickness
                bg.borderThickness = val
                STYLE_API:RebuildOffsets(rootArgs.permanentBackgrodund.args, bg, unit, oldThickness, bg.borderThicknessIcon, {bar=true, icon=false})
                CASTBAR_API:UpdateCastbar(unit)
            end,
            disabled = function() return not bg.showBorder end,
        },
        borderOffsetGrp = {
            type   = "group",
            name   = "Border Offsets",
            order  = 7,
            disabled = function() return not bg.showBorder end,
            args = STYLE_API:BuildBorderOffsetArgs(bg, unit, bg.borderThickness)
        },
    }
end


function OtherFeatures_API:BuildPermanentBackgroundOptions(unit, cfg, args)
    local bgCFG = cfg.permanentBackgrodund
    args.permanentBackgrodund = {
        type   = "group",
        name   = "Permanent background",
        inline = false,
        order  = 8,
        args = {
            enable = {
                type = "toggle", dialogControl = "UCB_CheckBox",
                name = "Enable",
                order = 1,
                width = 1.5,
                get = function() return bgCFG.enable end,
                set = function(_, val)
                    bgCFG.enable = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            hideWhenCasting = {
                type = "toggle", dialogControl = "UCB_CheckBox",
                name = "Hide when casting",
                order = 1.5,
                width = 1.5,
                get = function() return bgCFG.hideWhenCasting end,
                set = function(_, val)
                    bgCFG.hideWhenCasting = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return not bgCFG.enable end,
            },
            style = {
                type = "group",
                name = "Background style",
                inline = true,
                order = 2,
                disabled = function() return not bgCFG.enable end,
                args = BuildBackgroundStyleArgs(bgCFG.style, unit),
            },
            grpBorder = {
                type = "group",
                name = "Border",
                inline = true,
                order = 3,
                disabled = function() return not bgCFG.enable end,
                args = BuildBorderArgs(bgCFG.style, bgCFG, unit, args),
            },
        },
    }
end