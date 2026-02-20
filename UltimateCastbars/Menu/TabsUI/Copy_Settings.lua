local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.Copy = UCB.Copy or {}
UCB.COPY_API = UCB.COPY_API or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}

local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local COPY_API = UCB.COPY_API

local COPY = UCB.Copy

local function CreatePickList(current_unit)
    local pickList = {}
    for unit, used in pairs(UCB.menuUnits) do
        if used and unit ~= current_unit then
            pickList[unit] = UCB:UnitDisplayName(unit)
        end
    end
    return pickList
end


local function CopyMain(unit, copy_paths)
    local cfg = GetCFG(unit)
    local mainSettings
    local selectList = CreatePickList(unit)
    local currentSelect = nil
    mainSettings = {
        type = "group",
        name = "",
        order = 1,
        inline = true,
        args = {
            copySelect ={
                type = "select",
                name = "Copy categories from:",
                desc = "Select the unit you want to copy settings from.",
                order = 1,
                values = selectList,
                get = function()
                    return currentSelect
                    end,
                set = function(_, val)
                    currentSelect = val
                end,
            },
            gap  = {
                type = "description",
                name = "",
                order = 2,
                width = 0.3
            },
            copyButton = {
                type = "execute",
                name = function() return "Copy Settings into "..UCB:UnitDisplayName(unit) end,
                desc = "Copy settings from the selected unit to this unit.",
                order = 3,
                width = 1.5,
                confirm = true,
                confirmText = "This will overwrite the selected categories settings with the ones from another bar. Continue?",
                func = function()
                    if not currentSelect then
                        print("Please select a unit to copy settings from.")
                        return
                    end
                    local copyOne
                    UCB.CASTBAR_API:StopPrevCast(unit)
                    if not copy_paths then
                        copyOne = COPY:CopySettings(unit, currentSelect, cfg.copySettings.paths)
                    else
                        copyOne = COPY:CopySettings(unit, currentSelect, copy_paths)
                    end
                    if copyOne then
                        UCB.GUI:RefreshUnitUI(unit, {unit, "general"})
                        UCB.CASTBAR_API:UpdateCastbar(unit)
                        print("Settings copied from", UCB:UnitDisplayName(currentSelect), "to", UCB:UnitDisplayName(unit))
                    else
                        print("No settings were copied. Please make sure at least one category is selected for copying.")
                    end
                end,
            },
        }
    }
    return mainSettings
end

local function CreateCategoriesToggle(unit)
    local cfg = GetCFG(unit)
    local categories = UCB.Copy.categories
    local categoriesOrder = UCB.Copy.categoriesOrder
    local args = {}
    for i, key in ipairs(categoriesOrder) do
        local label = categories[key]
        args[key] = {
            type = "toggle",
            name = label,
            desc = "Include "..label.." in the copy.",
            order = i,
            get = function() return cfg.copySettings.paths[key] end,
            set = function(_, val) cfg.copySettings.paths[key] = val end,
        }
    end
    return {
        type = "group",
        name = "Categories to Copy",
        order = 3,
        inline = true,
        args = args,
        hidden = function ()
            return not COPY_API.showCategoryToggles
        end
    }
end

local function BuildCopySettingsArgs(args, unit, opts)
    local mainCopy = CopyMain(unit)
    COPY_API.showCategoryToggles = false

    mainCopy.args.gap2 = {
        type = "description",
        name = "",
        order = 4,
        width = 0.5
    }
    mainCopy.args.showHideButton = {
        type = "execute",
        name = function() return (COPY_API.showCategoryToggles and UCB.UIOptions.ColorText(UCB.UIOptions.red, "Hide") or UCB.UIOptions.ColorText(UCB.UIOptions.green, "Show")).." Copy Settings" end,
        desc = "Show or hide the copy settings options.",
        order = 5,
        func = function()
            COPY_API.showCategoryToggles = not COPY_API.showCategoryToggles
            UCB:NotifyChange()
        end,
    }

    args.mainCopySettings = {
        type = "group",
        name = "",
        order = 1,
        inline = true,
        disabled = false,
        args = {
            mainCopy = mainCopy,
            categoryEasyButton = {
                type = "group",
                name = "",
                order = 2,
                inline = true,
                hidden = function() return not COPY_API.showCategoryToggles end,
                args = {
                    selectAllButton = {
                        type = "execute",
                        name = "Select All Categories",
                        desc = "Select all categories to copy from the selected unit.",
                        order = 1,
                        func = function()
                            local cfg = GetCFG(unit)
                            for _, key in ipairs(UCB.Copy.categoriesOrder) do
                                cfg.copySettings.paths[key] = true
                            end
                            UCB:NotifyChange()
                        end,
                    },
                    gap = {
                        type = "description",
                        name = "",
                        order = 1.5,
                        width = 0.3
                    },
                    deselectAllButton = {
                        type = "execute",
                        name = "Deselect All Categories",
                        desc = "Deselect all categories to copy from the selected unit.",
                        order = 2,
                        func = function()
                            local cfg = GetCFG(unit)
                            for _, key in ipairs(UCB.Copy.categoriesOrder) do
                                cfg.copySettings.paths[key] = false
                            end
                            UCB:NotifyChange()
                        end,
                    },
                }
            },
            categoryToggles = CreateCategoriesToggle(unit),
        }
    }
end

function Opt.BuildCopySettingsArgs(unit, opts)
    local args = {}
    BuildCopySettingsArgs(args, unit, opts)
    return args
end