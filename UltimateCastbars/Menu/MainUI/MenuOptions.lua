local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.DefBlizzCast = UCB.DefBlizzCast or {}
UCB.GUI = UCB.GUI or {}
UCB.UIOptions = UCB.UIOptions or {}

local GUI = UCB.GUI
local GetCFG = UCB.GetValueConfig
local UIOptions = UCB.UIOptions

local function EnsureEnabledKey(cfg)
    if cfg and cfg.enabled == nil then cfg.enabled = true end
end

local function IsDisabled(unit)
    local cfg = GetCFG(unit); EnsureEnabledKey(cfg)
    return cfg and cfg.enabled == false
end

local function GetEnabled(unit)
    local cfg = GetCFG(unit); EnsureEnabledKey(cfg)
    return cfg and cfg.enabled
end

local function SetEnabled(unit, val)
    local cfg = GetCFG(unit)
    if not cfg then return end
    EnsureEnabledKey(cfg)

    cfg.enabled = (val and true or false)
    cfg.defaultBar = cfg.defaultBar or {}
    cfg.defaultBar.enabled = (cfg.enabled == false)

    if cfg.enabled then
        UCB:TrackUnit(unit)
        UCB:SelectGroup({"general"}, unit)
    else
        UCB:UntrackUnit(unit)
        UCB:SelectGroup({"defaultCastbar"}, unit)
    end

    UCB.DefBlizzCast:ApplyDefaultBlizzCastbar(unit, cfg.enabled == false)

    UCB.CASTBAR_API:UpdateCastbar(unit)
end

function GUI:BuildUnitOptionsArgs(unit)
    return {
        castbarShow = {
            type = "group",
            name = UCB:UnitDisplayName(unit) .. " Cast Bar",
            order = 0.5,
            inline = true,
            args = {
                enabled = {
                    type = "toggle",
                    name = "Enable",
                    dialogControl = "UCB_CheckBox",
                    order = 1,
                    width = "full",
                    get = function() return GetEnabled(unit) end,
                    set = function(_, v)
                        SetEnabled(unit, v)
                        if UCB.ACR then UCB.ACR:NotifyChange("UCB") end
                    end,
                },
                unitTitle = {
                    type = "header",  dialogControl = "UCB_Heading",
                    name = "Now modifying: ".. UIOptions.ColorText(UIOptions.turquoise, UCB:UnitDisplayName(unit)),
                    order = 1.5,
                },
                previewButtons = {
                    type = "group",
                    name = "Preview",
                    order = 2,
                    inline = true,
                    disabled = function() return IsDisabled(unit) end,
                    args = UCB.Options.BuildGeneralSettingsPreviewArgs(unit, { includePerTabEnable = false }),
                },
                copySection = {
                    type = "group",
                    name = "Copy Settings From Another Bar",
                    order = 3,
                    inline = true,
                    disabled = function() return IsDisabled(unit) end,
                    args = UCB.Options.BuildCopySettingsArgs(unit, { includePerTabEnable = false }),
                },
            },
        },

        general = {
            type = "group",
            name = "General",
            order = 1,
            disabled = function() return IsDisabled(unit) end,
            args = UCB.Options.BuildGeneralSettingsArgs(unit, { includePerTabEnable = false }),
        },

        text = {
            type = "group",
            name = "Text",
            order = 2,
            disabled = function() return IsDisabled(unit) end,
            childGroups = "tree",
            args = UCB.Options.BuildGeneralSettingsTextArgs(unit, { includePerTabEnable = false }),
        },

        style = {
            type = "group",
            name = "Style",
            order = 3,
            disabled = function() return IsDisabled(unit) end,
            args = UCB.Options.BuildGeneralSettingsStyleArgs(unit, { includePerTabEnable = false }),
        },

        uninterruptable = {
            type = "group",
            name = "Uninterruptable",
            order = 4,
            disabled = function() return IsDisabled(unit) end,
            args = UCB.Options.BuildGeneralSettingsUninterruptableArgs(unit, { includePerTabEnable = false }),
        },

        visibility = {
            type = "group",
            name = "Visibility",
            order = 5,
            disabled = function() return IsDisabled(unit) end,
            args = UCB.Options.BuildGeneralSettingsVisibilityArgs(unit, { includePerTabEnable = false }),
        },

        otherFeatures = {
            type = "group",
            name = "Other Features",
            order = 6,
            disabled = function() return IsDisabled(unit) end,
            args = UCB.Options.BuildGeneralSettingsOtherFeaturesArgs(unit, { includePerTabEnable = false }),
        },

        classSettings = {
            type = "group",
            name = "Class Specific Settings",
            order = 7,
            childGroups = "tree",
            disabled = function() return IsDisabled(unit) end,
            args = UCB.Options.BuildClassSettingsArgs(unit, { includePerTabEnable = false }),
        },

        defaultCastbar = {
            type = "group",
            name = "Default Blizzard Castbar",
            order = 8,
            args = UCB.Options.BuildGeneralSettingsDefaultBarArgs(unit, { includePerTabEnable = false }),
        },

        internalSettings = {
            type = "group",
            name = "Internal Settings",
            order = 9,
            args = UCB.Options.BuildGeneralSettingsInternalArgs(unit, { includePerTabEnable = false }),
        },
    }
end