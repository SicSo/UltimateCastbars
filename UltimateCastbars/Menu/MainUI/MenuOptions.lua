local _, UCB = ...


UCB.Util = UCB.Util or {}
UCB.CFG_API  = UCB.CFG_API  or {}
UCB.Options = UCB.Options or {}
UCB.GUI = UCB.GUI or {}

local Util = UCB.Util
local CFG_API  = UCB.CFG_API
local Opt  = UCB.Options
local GUI = UCB.GUI
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
local CASTBAR_API = UCB.CASTBAR_API


local function GetCfg(unit) return UCB.CFG_API.GetValueConfig(unit) end

local function EnsureEnabledKey(cfg)
    if cfg and cfg.enabled == nil then cfg.enabled = true end
end

local function IsDisabled(unit)
    local cfg = GetCfg(unit); EnsureEnabledKey(cfg)
    return cfg and cfg.enabled == false
end

local function GetEnabled(unit)
    local cfg = GetCfg(unit); EnsureEnabledKey(cfg)
    return cfg and cfg.enabled
end

local function SetEnabled(unit, val)
    local cfg = GetCfg(unit)
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

    if UCB.DefBlizzCast and UCB.DefBlizzCast.ApplyDefaultBlizzCastbar then
        UCB.DefBlizzCast:ApplyDefaultBlizzCastbar(unit, cfg.enabled == false)
    end

    if UCB.CASTBAR_API and UCB.CASTBAR_API.UpdateCastbar then
        UCB.CASTBAR_API:UpdateCastbar(unit)
    end
end

function GUI:BuildUnitOptionsArgs(unit)
    return {
        castbarShow = {
            type = "group",
            name = (unit:gsub("^%l", string.upper)) .. " Cast Bar",
            order = 0.5,
            inline = true,
            args = {
                enabled = {
                    type = "toggle",
                    name = "Enable",
                    order = 1,
                    width = "full",
                    get = function() return GetEnabled(unit) end,
                    set = function(_, v)
                        SetEnabled(unit, v)
                        if UCB.ACR then UCB.ACR:NotifyChange("UCB") end
                    end,
                },
                previewButtons = {
                    type = "group",
                    name = "Preview",
                    order = 2,
                    inline = true,
                    disabled = function() return IsDisabled(unit) end,
                    args = UCB.Options.BuildGeneralSettingsPreviewArgs(unit, { includePerTabEnable = false }),
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
    }
end