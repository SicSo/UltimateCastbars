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


local unit = "player"  -- This module is only for the player cast bar

local function GetPlayerCfg()
   return CFG_API:Proxy(unit, {})--CFG_API.GetValueConfig(unit)
end


-----------------------------------------Eneble/Disable Cast Bar-----------------------------------------
local function EnsureEnabledKey(cfg)
    if not cfg then return end
    if cfg.enabled == nil then
        cfg.enabled = true
    end
end

local function IsCastbarDisabled()
    local cfg = GetPlayerCfg()
    EnsureEnabledKey(cfg)
    return cfg.enabled == false
end

local function GetCastbarEnabled()
    local cfg = GetPlayerCfg()
    EnsureEnabledKey(cfg)
    return cfg.enabled
end


local function SetCastbarEnabled(unit, val)
    local cfg = GetPlayerCfg()
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
        UCB.ACD:SelectGroup("UCB", "general")
    else
        UCB:DestroyPlayerSpellcastEventFrame(unit)
        UCB.ACD:SelectGroup("UCB", "defaultCastbar")
    end

    -- Apply Blizzard bar visibility/state
    DefBlizzCast:ApplyDefaultBlizzCastbar(unit, showBlizzard)

    -- Update/delete/rebuild custom bar based on cfg.enabled
    if CASTBAR_API and CASTBAR_API.UpdateCastbar then
        CASTBAR_API:UpdateCastbar(unit)
    end
end



-- ---------- Class name coloring helpers ----------
local function GetClassColorAARRGGBB(token)
    if C_ClassColor and C_ClassColor.GetClassColor then
        local c = C_ClassColor.GetClassColor(token)
        if c and c.GenerateHexColor then
            local hex = c:GenerateHexColor()
            if #hex == 6 then return "FF" .. hex end     -- RRGGBB
            if #hex == 8 then return hex end            -- AARRGGBB
        end
    end

    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if c then
        return string.format("FF%02X%02X%02X",
            math.floor((c.r or 1) * 255 + 0.5),
            math.floor((c.g or 1) * 255 + 0.5),
            math.floor((c.b or 1) * 255 + 0.5)
        )
    end

    return "FFFFFFFF"
end

local function Colorize(text, aarrggbb)
    return ("|c%s%s|r"):format(aarrggbb, text)
end

local function GetClassDisplayName(token)
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token])
        or (LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[token])
        or token
end

local function GetClassList()
    if _G.CLASS_SORT_ORDER then
        local out = {}
        for _, token in ipairs(_G.CLASS_SORT_ORDER) do out[#out + 1] = token end
        return out
    end
    return {"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","DEATHKNIGHT","SHAMAN","MAGE","WARLOCK","MONK","DRUID","DEMONHUNTER","EVOKER"}
end



local function GoToClass(ct)
    if ct ~= UCB.className then
        UCB.ACD:SelectGroup("UCB", "classSettings", "otherClasses", "class_" .. ct)
    else
        UCB.ACD:SelectGroup("UCB", "classSettings", "class_" .. ct)
    end
end

local function BuildClassButtonMatrix(classes, excludeToken, groupName, groupOrder)
    return {
        type = "group",
        name = groupName or "Choose a class",
        order = groupOrder or 0,
        inline = true,
        args = (function()
        local btns = {}
        local o = 1

        for _, ct in ipairs(classes) do
            if not excludeToken or ct ~= excludeToken then
            btns["btn_" .. ct] = {
                type = "execute",
                name = function()
                return Colorize(GetClassDisplayName(ct), GetClassColorAARRGGBB(ct))
                end,
                order = o,
                width = "quarter",
                func = function() GoToClass(ct) end,
            }
            o = o + 1
            end
        end

        return btns
        end)(),
    }
end




-- ---------- Options registration and display ----------
local function EnsureOptionsRegistered()
    if UCB._optionsRegistered then return end

    UCB.optionsTable = {
        type = "group",
        name = "UCB",
        args = (function()
            local args = {}

            -- -------- Player Cast Bar enable/disable (own top-level node) --------
            args.castbarShow = {
                type = "group",
                name = "Player Cast Bar",
                order = 0.5,
                inline = true,
                disabled = false,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable Player Cast Bar",
                        order = 0.51,
                        width = "full",
                        get = function() return GetCastbarEnabled() end,
                        set = function(_, val)
                            SetCastbarEnabled(unit, val)
                            UCB.ACR:NotifyChange("UCB")
                        end,
                    },
                    hint = {
                        type = "description",
                        name = "When disabled, all settings are locked (greyed out).",
                        order = 0.52,
                        width = "full",
                    },
                    previewButtons = {
                        type = "group",
                        name = "Preview Castbar",
                        order = 0.53,
                        width = "full",
                        disabled = IsCastbarDisabled,
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
                disabled = IsCastbarDisabled,
                args = (function()
                    return Opt.BuildGeneralSettingsArgs(unit, { includePerTabEnable = false })
                end)(),
            }
            args.text = {
                type = "group",
                name = "Text",
                order = 2,
                disabled = IsCastbarDisabled,
                childGroups = "tree",
                args = (function()
                    return Opt.BuildGeneralSettingsTextArgs(unit, { includePerTabEnable = false })
                end)(),
            }
            args.style = {
                type = "group",
                name = "Style",
                order = 3,
                disabled = IsCastbarDisabled,
                args = (function()
                    return Opt.BuildGeneralSettingsStyleArgs(unit, { includePerTabEnable = false })
                end)(),
            }
            args.visibility = {
                type = "group",
                name = "Visibility",
                order = 4,
                disabled = IsCastbarDisabled,
                args = (function()
                    return Opt.BuildGeneralSettingsVisibilityArgs(unit, { includePerTabEnable = false })
                end)(),
            }
            args.otherFeatures = {
                type = "group",
                name = "Other Features",
                order = 5,
                disabled = IsCastbarDisabled,
                args = (function()
                    return Opt.BuildGeneralSettingsOtherFeaturesArgs(unit, { includePerTabEnable = false })
                end)(),
            }

            -- -------- Class Specific Settings (parent node) --------
            args.classSettings = {
            type = "group",
            name = "Class Specific Settings",
            order = 6,
            childGroups = "tree",
            disabled = IsCastbarDisabled,
            args = (function()
                local classArgs = {}
                local classes = GetClassList()

                local function BuildClassGroup(ct, order)
                return {
                    type = "group",
                    name = function()
                    return Colorize(GetClassDisplayName(ct), GetClassColorAARRGGBB(ct))
                    end,
                    order = order,
                    args = (function()
                    local a = {}
                    local extraArgs = Opt.GetExtraClassArgs(ct, unit)
                    for k, v in pairs(extraArgs) do
                        a[k] = v
                    end
                    return a
                    end)(),
                }
                end

                -- Parent panel: Current Class group
                classArgs.currentClass = {
                type = "group",
                name = "Current Class",
                order = 0,
                inline = true,
                args = {
                    btn_currentClass = {
                    type = "execute",
                    name = function()
                        return Colorize(GetClassDisplayName(UCB.className), GetClassColorAARRGGBB(UCB.className))
                    end,
                    order = 1,
                    width = "quarter",
                    func = function() GoToClass(UCB.className) end,
                    },
                },
                }

                -- Parent panel: Matrix under Current Class (same idea as otherClasses)
                -- Exclude your current class so you don't have duplicate with the button above.
                classArgs.classMatrix = BuildClassButtonMatrix(classes, UCB.className, "Other Classes", 1)

                -- Tree node 1: your class first
                classArgs["class_" .. UCB.className] = BuildClassGroup(UCB.className, 2)

                -- Tree node 2: Other Classes (keep your matrix + keep class nodes)
                classArgs.otherClasses = {
                type = "group",
                name = "Other Classes",
                order = 3,
                childGroups = "tree",
                args = (function()
                    local other = {}

                    -- Keep the matrix here too
                    other.classPicker = BuildClassButtonMatrix(classes, UCB.className, "Other Classes", 0)

                    -- Keep the class tree nodes under otherClasses
                    local order = 1
                    for _, ct in ipairs(classes) do
                    if ct ~= UCB.className then  -- IMPORTANT: this was `ct ~= UCB` in your snippet
                        other["class_" .. ct] = BuildClassGroup(ct, order)
                        order = order + 1
                    end
                    end

                    return other
                end)(),
                }

                return classArgs
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

    -- Profiles page
    UCB.optionsTable.args.profiles = UCB.ADBO:GetOptionsTable(UCB.db)
    UCB.optionsTable.args.profiles.order = 100

    -- LibDualSpec support
    local LibDualSpec = LibStub and LibStub("LibDualSpec-1.0", true)
    if LibDualSpec then
        LibDualSpec:EnhanceOptions(UCB.optionsTable.args.profiles, UCB.db)
    end

    UCB.AC:RegisterOptionsTable("UCB", UCB.optionsTable)
    UCB._optionsRegistered = true
end


-- Public: open inside an AceGUI container (your Player tab scroll frame)
function UCB:OpenOptionsInContainer(parentWidget)
    EnsureOptionsRegistered()

    -- Standalone
    if not parentWidget then
        UCB.ACD:Open("UCB")
        -- Delay selection to ensure tree exists even in standalone
        C_Timer.After(0, function()
        if UCB.ACD and UCB.ACD.SelectGroup then
            UCB.ACD:SelectGroup("UCB", "general")
        end
        end)
        return
    end

    -- Close if previously open elsewhere
    if UCB.ACD and UCB.ACD.Close then
        UCB.ACD:Close("UCB")
    end

    -- Fill the container
    if parentWidget.SetLayout then parentWidget:SetLayout("Fill") end
    if parentWidget.SetFullWidth then parentWidget:SetFullWidth(true) end
    if parentWidget.SetFullHeight then parentWidget:SetFullHeight(true) end

    -- Embed
    UCB.ACD:Open("UCB", parentWidget)

    -- Immediate attempt (may update right pane)
    if UCB.ACD and UCB.ACD.SelectGroup then
        UCB.ACD:SelectGroup("UCB", "general")
    end

    -- Next frame: ensures the left tree is created + highlight updates
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
        if UCB.ACD and UCB.ACD.SelectGroup then
            UCB.ACD:SelectGroup("UCB", "general")
        end
        end)
    end
end

-- Keep slash command as a convenience (opens standalone frame if no container supplied)
--[[
SLASH_PLAYERSCASTBAR1 = "/pcb"
SlashCmdList["PLAYERSCASTBAR"] = function()
    EnsureOptionsRegistered()
    UCB.ACD:Open("UCB") -- standalone window
end
--]]
