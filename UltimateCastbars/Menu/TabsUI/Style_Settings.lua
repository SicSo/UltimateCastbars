local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.STYLE_API = UCB.STYLE_API or {}
UCB.UIStructures = UCB.UIStructures or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local UIOptions = UCB.UIOptions
local STYLE_API = UCB.STYLE_API
local UIStructures = UCB.UIStructures

STYLE_API.castType = "normal"

local function createCasttypeList()
    local values = {
        normal    = "Normal",
        channel   = "Channelled",
        empowered = "Empowered",
    }

    local sorting = { "normal", "channel", "empowered" } -- desired order

    return values, sorting
end

local function createStyleWindow(args, unit, castTypeStyleCFG)
    if castTypeStyleCFG.useGeneralStyle then
        args.styleSelectionGrp.args.styleWindow = {
            type = "group",
            name = "General style settings",
            order = 2,
            args = UIStructures:BuildStyleWindow(castTypeStyleCFG.general, unit),
        }
    else
        args.styleSelectionGrp.args.styleWindow = {
            type = "group",
            name = function() return UIOptions.MakeTitle(STYLE_API.castType).." style settings" end,
            order = 2,
            args = UIStructures:BuildStyleWindow(castTypeStyleCFG[STYLE_API.castType], unit),
        }
    end
end

local function BuildCustomisationArgs(args, unit)
    local castTypeStyleCFG = GetCFG(unit, "styleCastType")

    args.styleSelectionGrp = {
        type = "group",
        name = "Style settings",
        order = 0,
        inline = true,
        args = {
            useGeneralSettings = {
                type = "toggle",
                name = "Use general settings",
                desc = "Use the general settings for this cast type instead of custom ones.",
                order = 0,
                get = function() return castTypeStyleCFG.useGeneralStyle end,
                set = function(_, value)
                    castTypeStyleCFG.useGeneralStyle = value
                    createStyleWindow(args, unit, castTypeStyleCFG)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            styleSelectionGrp = {
                type = "group",
                name = "Per cast type style settings",
                order = 1,
                hidden = function() return castTypeStyleCFG.useGeneralStyle end,
                args = {
                    editHeader = {
                        type = "header",
                        name = function() return "Settings for "..UIOptions.ColorText(UIOptions.turquoise , UIOptions.MakeTitle(unit).." - "..string.upper(STYLE_API.castType)).." cast bars" end,
                        order = 0,
                    },
                    selectType = {
                        type = "select",
                        name = "Select cast type",
                        order = 1,
                        values = createCasttypeList(),
                        get = function() return STYLE_API.castType end,
                        set = function(_, value)
                            STYLE_API.castType = value
                            createStyleWindow(args, unit, castTypeStyleCFG)
                        end,
                    },
                    -- add copy controls

                },
            }
        }
    }
    createStyleWindow(args, unit, castTypeStyleCFG)
end

-- Public builder
function Opt.BuildGeneralSettingsStyleArgs(unit, opts)
    opts = opts or {}
    local args = {}
    BuildCustomisationArgs(args, unit)

    return args
end


