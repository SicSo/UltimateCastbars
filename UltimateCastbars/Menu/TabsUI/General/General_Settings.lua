-- File: GeneralSettings_Main.lua
local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.GeneralSettings_API = UCB.GeneralSettings_API or {}

local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local UIOptions = UCB.UIOptions
local GeneralSettings_API = UCB.GeneralSettings_API

local function BuildFramePickerArgs(args, unit)
    local g = GetCFG(unit, "general")

    args.framePickerGrp = {
        type = "group",
        name = "Frame Picker",
        inline = true,
        order = 0,
        args = {
            info = {
                order = 1,
                width = "full",
                type = "description",
                name ="This is a helper functionality to find the desired frame within your UI. You can use it to find frame to anchor the castbar to or sync the width or height."..
                    "To do so, click the 'Grab Mouseover Frame' button and then hover on any frame within the UI. The frame will be highlighted in green. If you are looking for another frame on another strata,"..
                    "press the keys UP/DOWN arrows to find change the strata level. Once you found the desired, click CTRL while hovering. The name of the frame will be shown in the 'Frame clicked' field and can be copied from there. "..
                    "You can copy the value from the textbox above and paste it into the 'Custom Anchor Frame', 'Custom Width Frame' or 'Custom Height Frame' field."
            },
            frameClickedLast = {
                type = "header", dialogControl = "UCB_Heading",
                name = function()
                    return "Frame clicked last: "..UIOptions.ColorText(UIOptions.turquoise, g.frameLastClicked)
                end,
                width = "full",
                order = 1,
            },
            grabButton = {
                type = "execute", dialogControl = "UCB_Button",
                name = "Grab Mouseover Frame",
                order = 2,
                width = 1.5,
                func = function()
                    UCB.SimpleFramePickerObj:Start(
                        function(frameName)
                            g.frameLastClicked = frameName
                            UCB.GUI:RefreshGUI(true, { unit, "general" })
                        end,
                        function()
                            print("Picker cancelled.")
                        end
                    )
                end,
            },
            gap1 = {
                order = 2.5,
                type = "description",
                name = " ",
                width = 0.1
            },
            frameLastClickedCopy = {
                type = "input", dialogControl = "UCB_EditBox",
                name = "Frame clicked",
                width = 1.2,
                order = 3,
                get = function() return g.frameLastClicked end,
                set = function() end,
            },
        }
    }
end

function Opt.BuildGeneralSettingsArgs(unit, opts)
    opts = opts or {}
    local args = {}
    local cfg = GetCFG(unit, "general")

    BuildFramePickerArgs(args, unit)
    args.position = GeneralSettings_API:BuildPositionArgs(cfg, unit)
    args.size = GeneralSettings_API:BuildSizeArgs(cfg, unit)
    GeneralSettings_API:BuildIconArgs(args, cfg, unit)

    return args
end