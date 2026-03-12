local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.UIOptions = UCB.UIOptions or {}

local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local UIOptions = UCB.UIOptions

local function BuildInternalArgs(args, unit)
    args.scaleUI = {
        type = "group",
        name = "Scale UI",
        order = 0,
        inline = true,
        args = {
            description = {
                type = "description",
                name = function() return UIOptions.ColorText(UIOptions.turquoise, "This will scale the entire castbar configuration UI. It does not affect the scale of the castbars themselves.") end,
                order = 0,
                width = "full"
            },
            scale = {
                type = "range", dialogControl = "UCB_Slider",
                name = "UI Scale",
                desc = "Scale of the castbar configuration UI.",
                order = 1,
                min = 5, max = 150, step = 1,
                arg = {
                    commitOnRelease = true,
                },
                get = function() return GetCFG().misc.UIScale * 100 end,
                set  = function(_, val)
                    GetCFG().misc.UIScale = val / 100
                    if UCB.Container then
                        UCB.Container:SetScale(val / 100)
                    end
                    --C_UI.Reload()
                end,
            },
        }
    }

    args.loadAssets = {
        type = "group",
        name =  "Load Assets into LSM (pressing a toggle will reload the UI)",
        order = 1,
        inline = true,
        args = {
            description = {
                type = "description",
                name = function() return UIOptions.ColorText(UIOptions.turquoise, "To get the latest Textures and Fonts, download the ShareMedia addon!") end,
                order = 0,
                width = "full"
            },
            statusbar = {
                type = "toggle", dialogControl = "UCB_CheckBox",
                name = "Statusbar",
                desc = "When enabled, castbar statusbar textures will be loaded. If you are using custom textures, you can disable this to save memory.",
                order = 1,
                get = function() return GetCFG().misc.loadAssets.statusbar end,
                set = function(_, val)
                    GetCFG().misc.loadAssets.statusbar = val
                    C_UI.Reload()
                end,
            },
            background = {
                type = "toggle", dialogControl = "UCB_CheckBox",
                name = "Background",
                desc = "When enabled, castbar background textures will be loaded. If you are using custom textures, you can disable this to save memory.",
                order = 2,
                get = function() return GetCFG().misc.loadAssets.background end,
                set = function(_, val)
                    GetCFG().misc.loadAssets.background = val
                    C_UI.Reload()
                end,
            },
            border = {
                type = "toggle", dialogControl = "UCB_CheckBox",
                name = "Border",
                desc = "When enabled, castbar border textures will be loaded. If you are using custom textures, you can disable this to save memory.",
                order = 3,
                get = function() return GetCFG().misc.loadAssets.border end,
                set = function(_, val)
                    GetCFG().misc.loadAssets.border = val
                    C_UI.Reload()
                end,
            },
            font = {
                type = "toggle", dialogControl = "UCB_CheckBox",
                name = "Font",
                desc = "When enabled, castbar fonts will be loaded. If you are using custom fonts, you can disable this to save memory.",
                order = 4,
                get = function() return GetCFG().misc.loadAssets.font end,
                set = function(_, val)
                    GetCFG().misc.loadAssets.font = val
                    C_UI.Reload()
                end,
            },
        }
    }
end


-- Public builder
function Opt.BuildGeneralSettingsInternalArgs(unit, opts)
    opts = opts or {}
    local args = {}
    BuildInternalArgs(args, unit)

    return args
end


