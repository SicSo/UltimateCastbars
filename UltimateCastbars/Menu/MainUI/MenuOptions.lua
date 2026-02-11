local _, UCB = ...


UCB.Util = UCB.Util or {}
UCB.CFG_API  = UCB.CFG_API  or {}
UCB.Options = UCB.Options or {}

local Util = UCB.Util
local CFG_API  = UCB.CFG_API
local Opt  = UCB.Options
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
local CASTBAR_API = UCB.CASTBAR_API

UCB.DefBlizzCast = UCB.DefBlizzCast or {}
local DefBlizzCast = UCB.DefBlizzCast

UCB.optionsTable = UCB.optionsTable or {}
UCB._optionsRegistered = UCB._optionsRegistered or {}


local function GetPlayerCfg(unit)
   return CFG_API.GetValueConfig(unit)
end


-----------------------------------------Eneble/Disable Cast Bar-----------------------------------------
local function EnsureEnabledKey(cfg)
    if not cfg then return end
    if cfg.enabled == nil then
        cfg.enabled = true
    end
end

local function IsCastbarDisabled(unit)
    local cfg = GetPlayerCfg(unit)
    EnsureEnabledKey(cfg)
    return cfg.enabled == false
end

local function GetCastbarEnabled(unit)
    local cfg = GetPlayerCfg(unit)
    EnsureEnabledKey(cfg)
    return cfg.enabled
end


local function SetCastbarEnabled(unit, val)
    local cfg = GetPlayerCfg(unit)
    if not cfg then return end
    EnsureEnabledKey(cfg)

    -- Store real boolean
    cfg.enabled = (val and true or false)

    -- When custom is enabled -> Blizzard should be hidden
    -- When custom is disabled -> Blizzard should be shown
    local showBlizzard = (cfg.enabled == false)
    cfg.defaultBar.enabled = showBlizzard

    -- Spellcast events: only needed when custom bar is enabled
    if cfg.enabled then
        UCB:EUCBurePlayerSpellcastEventFrame(unit)
        UCB:SelectGroup(unit, {"general"})
    else
        UCB:DestroyPlayerSpellcastEventFrame(unit)
        UCB:SelectGroup(unit, {"defaultCastbar"})
    end

    -- Apply Blizzard bar visibility/state
    DefBlizzCast:ApplyDefaultBlizzCastbar(unit, showBlizzard)

    -- Update/delete/rebuild custom bar based on cfg.enabled
    if CASTBAR_API and CASTBAR_API.UpdateCastbar then
        CASTBAR_API:UpdateCastbar(unit)
    end
end

-- ---------- Options registration and display ----------
function UCB:EnsureOptionsRegistered(unit)
    if UCB._optionsRegistered[unit] then return end

    UCB.optionsTable[unit] = {
        type = "group",
        name = "UCB",
        args = (function()
            local args = {}

            -- -------- Player Cast Bar enable/disable (own top-level node) --------
            args.castbarShow = {
                type = "group",
                name = function() return (unit:gsub("^%l", string.upper)).." Cast Bar" end,
                order = 0.5,
                inline = true,
                disabled = false,
                args = {
                    enabled = {
                        type = "toggle",
                        name = function() return "Enable " .. (unit:gsub("^%l", string.upper)) .. " Cast Bar" end,
                        order = 0.51,
                        width = "full",
                        get = function() return GetCastbarEnabled(unit) end,
                        set = function(_, val)
                            SetCastbarEnabled(unit, val)
                            UCB:NotifyChange(unit)
                        end,
                    },
                    previewButtons = {
                        type = "group",
                        name = "Preview Castbar",
                        order = 0.53,
                        width = "full",
                        disabled = function() return IsCastbarDisabled(unit) end,
                        args = (function()
                            return Opt.BuildGeneralSettingsPreviewArgs(unit, { includePerTabEnable = false })
                        end)(),
                    },
                },
            }
            -- -------- General (own top-level node) --------
            args.general = {
                type = "group",
                name = "General",
                order = 1,
                disabled = function() return IsCastbarDisabled(unit) end,
                args = (function()
                    return Opt.BuildGeneralSettingsArgs(unit, { includePerTabEnable = false })
                end)(),
            }
            args.text = {
                type = "group",
                name = "Text",
                order = 2,
                disabled = function() return IsCastbarDisabled(unit) end,
                childGroups = "tree",
                args = (function()
                    return Opt.BuildGeneralSettingsTextArgs(unit, { includePerTabEnable = false })
                end)(),
            }
            args.style = {
                type = "group",
                name = "Style",
                order = 3,
                disabled = function() return IsCastbarDisabled(unit) end,
                args = (function()
                    return Opt.BuildGeneralSettingsStyleArgs(unit, { includePerTabEnable = false })
                end)(),
            }
            args.visibility = {
                type = "group",
                name = "Visibility",
                order = 4,
                disabled = function() return IsCastbarDisabled(unit) end,
                args = (function()
                    return Opt.BuildGeneralSettingsVisibilityArgs(unit, { includePerTabEnable = false })
                end)(),
            }
            args.otherFeatures = {
                type = "group",
                name = "Other Features",
                order = 5,
                disabled = function() return IsCastbarDisabled(unit) end,
                args = (function()
                    return Opt.BuildGeneralSettingsOtherFeaturesArgs(unit, { includePerTabEnable = false })
                end)(),
            }
            args.classSettings = {
                type = "group",
                name = "Class Specific Settings",
                order = 6,
                childGroups = "tree",
                disabled = function() return IsCastbarDisabled(unit) end,
                args = (function()
                    return Opt.BuildClassSettingsArgs(unit, { includePerTabEnable = false })
                end)(),
            }

            args.defaultCastbar = {
                type = "group",
                name = "Default Blizzard Castbar",
                order = 7,
                args = (function()
                    -- General edits the shared/base config for the player cast bar
                    return Opt.BuildGeneralSettingsDefaultBarArgs(unit, { includePerTabEnable = false })
                end)(),
            }
        return args
        end)(),
    }

    UCB.AC:RegisterOptionsTable(UCB.appNames[unit], UCB.optionsTable[unit])
    UCB._optionsRegistered[unit] = true
end


function UCB:BuildUnitOptionsArgs(unit)
    local function GetCfg() return UCB.CFG_API.GetValueConfig(unit) end

    local function EnsureEnabledKey(cfg)
        if cfg and cfg.enabled == nil then cfg.enabled = true end
    end

    local function IsDisabled()
        local cfg = GetCfg(); EnsureEnabledKey(cfg)
        return cfg and cfg.enabled == false
    end

    local function GetEnabled()
        local cfg = GetCfg(); EnsureEnabledKey(cfg)
        return cfg and cfg.enabled
    end

    local function SetEnabled(val)
        local cfg = GetCfg()
        if not cfg then return end
        EnsureEnabledKey(cfg)

        cfg.enabled = (val and true or false)
        cfg.defaultBar = cfg.defaultBar or {}
        cfg.defaultBar.enabled = (cfg.enabled == false)

        if cfg.enabled then
            UCB:EUCBurePlayerSpellcastEventFrame(unit)
        else
            UCB:DestroyPlayerSpellcastEventFrame(unit)
        end

        if UCB.DefBlizzCast and UCB.DefBlizzCast.ApplyDefaultBlizzCastbar then
            UCB.DefBlizzCast:ApplyDefaultBlizzCastbar(unit, cfg.enabled == false)
        end

        if UCB.CASTBAR_API and UCB.CASTBAR_API.UpdateCastbar then
            UCB.CASTBAR_API:UpdateCastbar(unit)
        end
    end

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
                    get = GetEnabled,
                    set = function(_, v)
                        SetEnabled(v)
                        if UCB.ACR then UCB.ACR:NotifyChange("UCB") end
                    end,
                },
                previewButtons = {
                    type = "group",
                    name = "Preview",
                    order = 2,
                    inline = true,
                    disabled = IsDisabled,
                    args = UCB.Options.BuildGeneralSettingsPreviewArgs(unit, { includePerTabEnable = false }),
                },
            },
        },

        general = {
            type = "group",
            name = "General",
            order = 1,
            disabled = IsDisabled,
            args = UCB.Options.BuildGeneralSettingsArgs(unit, { includePerTabEnable = false }),
        },

        text = {
            type = "group",
            name = "Text",
            order = 2,
            disabled = IsDisabled,
            childGroups = "tree",
            args = UCB.Options.BuildGeneralSettingsTextArgs(unit, { includePerTabEnable = false }),
        },

        style = {
            type = "group",
            name = "Style",
            order = 3,
            disabled = IsDisabled,
            args = UCB.Options.BuildGeneralSettingsStyleArgs(unit, { includePerTabEnable = false }),
        },

        visibility = {
            type = "group",
            name = "Visibility",
            order = 4,
            disabled = IsDisabled,
            args = UCB.Options.BuildGeneralSettingsVisibilityArgs(unit, { includePerTabEnable = false }),
        },

        otherFeatures = {
            type = "group",
            name = "Other Features",
            order = 5,
            disabled = IsDisabled,
            args = UCB.Options.BuildGeneralSettingsOtherFeaturesArgs(unit, { includePerTabEnable = false }),
        },

        classSettings = {
            type = "group",
            name = "Class Specific Settings",
            order = 6,
            childGroups = "tree",
            disabled = IsDisabled,
            args = UCB.Options.BuildClassSettingsArgs(unit, { includePerTabEnable = false }),
        },

        defaultCastbar = {
            type = "group",
            name = "Default Blizzard Castbar",
            order = 7,
            args = UCB.Options.BuildGeneralSettingsDefaultBarArgs(unit, { includePerTabEnable = false }),
        },
    }
end



-- Public: open inside an AceGUI container (your Player tab scroll frame)
function UCB:OpenOptionsInContainer(parentWidget, unit)
    UCB:EnsureOptionsRegistered(unit)

    local appName =  UCB.appNames[unit]

    -- remember where this unit is embedded
    UCB.GUI = UCB.GUI or {}
    UCB.GUI._embedParent = UCB.GUI._embedParent or {}
    if parentWidget then
        UCB.GUI._embedParent[unit] = parentWidget
    end

    -- Standalone
    if not parentWidget then
        UCB.ACD:Open(appName)
        -- Delay selection to ensure tree exists even in standalone
        C_Timer.After(0, function()
        UCB:SelectGroup(unit, {"general"})
        end)
        return
    end

    -- Close if previously open elsewhere
    if UCB.ACD and UCB.ACD.Close then
        UCB.ACD:Close(appName)
    end

    parentWidget:ReleaseChildren()
    if parentWidget.SetLayout then parentWidget:SetLayout("Fill") end
    if parentWidget.SetFullWidth then parentWidget:SetFullWidth(true) end
    if parentWidget.SetFullHeight then parentWidget:SetFullHeight(true) end

    C_Timer.After(0, function()
        if not parentWidget then return end
        UCB.ACD:Open(appName, parentWidget)
        UCB:SelectGroup(unit, {"general"})
    end)

    -- Embed
    --UCB.ACD:Open(appName, parentWidget)

    -- Immediate attempt (may update right pane)
    --UCB:SelectGroup(unit, {"general"})

    --UCB.optionsPanel, UCB.optionsCategoryID = UCB.ACD:AddToBlizOptions("UCB", "UCB")
end