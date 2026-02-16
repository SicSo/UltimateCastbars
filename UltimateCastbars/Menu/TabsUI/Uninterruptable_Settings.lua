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
    local cfg = GetCfg(unit).uninterruptable

    args.uninterruptableGroup = {
        type   = "group",
        name   = "Uninterruptable cast bar options",
        inline = true,
        order  = 2,
        args = {
            uninterruptableEnabled = {
                type  = "toggle",
                name  = "Enable uninterruptable cast bars",
                desc  = "Show a separate cast bar for uninterruptable casts.",
                order = 1,
                width = 1,
                get = function() return cfg.showUninterruptable end,
                set = function(_, val)
                    cfg.showUninterruptable = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            uninterruptableFill = {
                type  = "toggle",
                name  = "Show uninterruptable fill",
                desc  = "Fill the uninterruptable cast bar to show progress.",
                order = 2,
                get = function() return cfg.showUninterruptableFill end,
                set = function(_, val)
                    cfg.showUninterruptableFill = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            uninterruptableBackground = {
                type  = "toggle",
                name  = "Show uninterruptable background",
                desc  = "Show a background for the uninterruptable cast bar.",
                order = 3,
                get = function() return cfg.showUninterruptableBackground end,
                set = function(_, val)
                    cfg.showUninterruptableBackground = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            fillOptionsGrp = {
                type = "group",
                name = "Fill options",
                inline = true,
                order = 4,
                hidden = function() return not cfg.showUninterruptableFill end,
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
                hidden = function() return not cfg.showUninterruptableBackground end,
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
                    backgroundColour = {
                        type = "color",
                        name = "Background colour",
                        desc = "Colour of the uninterruptable cast bar background.",
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
end

-- Public builder
function Opt.BuildGeneralSettingsUninterruptableArgs(unit, opts)
    opts = opts or {}
    local args = {}
    BuildUninterruptableArgs(args, unit)

    return args
end

