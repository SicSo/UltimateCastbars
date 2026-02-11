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


local function BuildLayeringArgs(args, unit)
    local cfg = GetCfg(unit).visibility


    args.layeringGroup = {
        type   = "group",
        name   = "Castbar layering and strata options",
        inline = true,
        order  = 1,
        args = {
            frameStrata = {
                type  = "select",
                name  = "Strata",
                desc  = "Controls which UI layer the cast bar is drawn on. Higher strata shows above lower strata.",
                order = 1,
                width = 1.5,
                values = UIOptions.strata,
                sorting = {
                    "BACKGROUND","LOW","MEDIUM","HIGH","DIALOG","FULLSCREEN","FULLSCREEN_DIALOG","TOOLTIP",
                },
                get = function() return cfg.frameStrata end,
                set = function(_, val)
                    cfg.frameStrata = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            frameLevel = {
                type  = "range",
                name  = "Frame Level",
                desc  = "Only affects draw order among frames in the same strata. Higher level appears above.",
                min   = UIOptions.frameLevelMin, max = UIOptions.frameLevelMax, step = 1,
                order = 2,
                width = 1.5,
                get = function() return cfg.frameLevel end,
                set = function(_, val)
                    cfg.frameLevel = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
        },
    }
end


-- Public builder
function Opt.BuildGeneralSettingsVisibilityArgs(unit, opts)
    opts = opts or {}
    local args = {}
    BuildLayeringArgs(args, unit)

    return args
end


