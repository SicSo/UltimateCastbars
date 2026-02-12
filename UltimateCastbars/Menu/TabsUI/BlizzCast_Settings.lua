local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.DefBlizzCast = UCB.DefBlizzCast or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local DefBlizzCast = UCB.DefBlizzCast



local function BuildDefaultBarArgs(args, unit, opts)
    local bigCFG = GetCfg(unit)
    local cfg = bigCFG.defaultBar
    local debugCFG = GetCfg("debug")

    args.hideDefaultBargrp = {
        type = "group",
        name = "Default Castbar",
        order = 1,
        inline = true,
        disabled = false,
        args = {
            hideDefaultBar = {
                type  = "toggle",
                name  = "Show Default Castbar",
                order = 1,
                get   = function() return cfg.enabled end,
                set   = function(_, val)
                    cfg.enabled = val
                    DefBlizzCast:ApplyDefaultBlizzCastbar(unit, cfg.shorBarOnEnable)
                end,
            },
            hint = {
                type = "description",
                name = "This can be used to see how the default and custom castbars compare/behave. \n"..
                "Enabling showing \"Show static bar on enable\" will alwatys show the castbar in a static state when toggle. Casting will make it dynamic again.",
                order = 2,
                width = "full",
            },
            shorBarOnEnable = {
                type  = "toggle",
                name  = "Show static bar on enable",
                desc  = "When enabled, the default castbar show in its last state without pressing a cast when toggled on. Casting makes it dynamic again.",
                order = 3,
                get   = function()
                    return cfg.shorBarOnEnable == true
                end,
                set   = function(_, val)
                    cfg.shorBarOnEnable = val and true or false
                end,
            },
        }
    }
    args.defaultCastbarSettings = {
        type = "group",
        name = "Default Castbar Settings",
        order = 2,
        inline = true,
        disabled = function() return cfg.enabled == false end,
        args = {
            useBlizzardDefaults = {
                type  = "toggle",
                name  = "Use Blizzard default size & position",
                desc  = "When enabled, the default castbar uses Blizzard's original saved placement and scale. Disable to use custom settings below.",
                order = 1,
                get   = function()
                    DefBlizzCast:EnsureDefaultBarKeys(unit)
                    return cfg.useBlizzardDefaults == true
                end,
                set   = function(_, val)
                    DefBlizzCast:EnsureDefaultBarKeys(unit)
                    cfg.useBlizzardDefaults = val and true or false
                    DefBlizzCast:RefreshBlizzardCastbarLayoutMode(unit, cfg.shorBarOnEnable)
                end,
            },
            defaultBarPos = {
                type = "group",
                name = "Scale and Position",
                inline = true,
                order = 2,
                disabled = function() return cfg.useBlizzardDefaults == true end,
                args = {
                    blizzBarScale = {
                        type  = "range",
                        name  = "Scale",
                        min   = UIOptions.blizzScaleMin, max = UIOptions.blizzScaleMax, step = 0.01,
                        order = 1,
                        get   = function() return cfg.blizzBarScale or 0.01 end,
                        set   = function(_, val)
                            cfg.blizzBarScale = val
                            DefBlizzCast:RefreshBlizzardCastbarScale(unit)
                        end,
                    },
                    offsetX = {
                        type = "range",
                        name = "X Offset",
                        min = UIOptions.blizzOffsetMin, max = UIOptions.blizzOffsetMax, step = 1,
                        order = 2,
                        get = function()
                            return tonumber(cfg.offsetX) or 0
                        end,
                        set = function(_, val)
                            DefBlizzCast:UpdateDefaultCastbarPosition(val, cfg.offsetY or 0, cfg.anchorPoint or "CENTER",  unit)
                        end,
                    },
                    offsetY = {
                        type = "range",
                        name = "Y Offset",
                        min = UIOptions.blizzOffsetMin, max = UIOptions.blizzOffsetMax, step = 1,
                        order = 3,
                        get = function()
                            return tonumber(cfg.offsetY) or 0
                        end,
                        set = function(_, val)
                            DefBlizzCast:UpdateDefaultCastbarPosition(cfg.offsetX or 0, val, cfg.anchorPoint or "CENTER",  unit)
                        end,
                    },
                },
            }
        },
    }
    args.debugMode = {
        type = "group",
        name = "Debug Controls",
        order = 3,
        inline = true,
        args = {
            title = {
                type = "header",
                name = function()
                    local addonsDisabled = debugCFG._addonList and #debugCFG._addonList or 0
                    if addonsDisabled > 0 then
                        return UCB.UIOptions.ColorText(UCB.UIOptions.red, addonsDisabled).. " addons disabled for debug mode."
                    else
                        return  UCB.UIOptions.ColorText(UCB.UIOptions.green, "Debug mode inactive (no addon disabled)")
                    end
                end,
                order = 1,
            },
            descDebug = {
                type = "description",
                name = "Debug mode disables all other addons to help identify if an issue is caused by an addon conflict. Click the button below to toggle debug mode on/off.".. 
                "Alternatively, you can use the command /ucbdebug to start and /ucbdebugstop to stop without opening the menu.",
                order = 1.5,
            },
            debugButton = {
                type = "execute",
                name = function()
                    if not debugCFG.enabled then
                        return "Start debug mode"
                    else
                        return "Stop debug mode"
                    end
                end,
                order = 2,
                func = function()
                    local startDebug = not debugCFG.enabled
                    if startDebug then
                        UCB:StartDebug()
                    else
                        UCB:StopDebug()
                    end
                end,
            }
        }
    }
end


-- Public builder
function Opt.BuildGeneralSettingsDefaultBarArgs(unit, opts)
    opts = opts or {}
    local args = {}

    BuildDefaultBarArgs(args, unit, opts)
    return args
end
