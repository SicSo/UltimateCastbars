local _, UCB = ...

UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.UIStructures = UCB.UIStructures or {}

local CASTBAR_API = UCB.CASTBAR_API
local UIOptions = UCB.UIOptions
local UIStructures = UCB.UIStructures

local function _GetActiveAbilityList(cfg)
    -- independent lists
    if cfg.blackList then
        cfg.blackListSpells = cfg.blackListSpells or {}
        return cfg.blackListSpells
    else
        cfg.whiteListSpells = cfg.whiteListSpells or {}
        return cfg.whiteListSpells
    end
end

local function BuildAbilityRows(abilityTable, cfg, unit)
    local list = _GetActiveAbilityList(cfg)

    abilityTable.args.rows.args = {}
    local rowsArgs = abilityTable.args.rows.args

    for i, spell in ipairs(list) do
        rowsArgs["row" .. i] = {
            type = "group",
            name = "",
            inline = true,
            order = i,
            args = {
                icon = {
                    type = "description",
                    name = "",
                    order = 1,
                    width = 0.30,
                    image = spell.icon,
                    imageWidth = 16,
                    imageHeight = 16,
                },
                v1 = { type = "description", name = "|", order = 2, width = 0.05 },

                name = {
                    type = "description",
                    name = tostring(spell.name or ""),
                    order = 3,
                    width = 1,
                },
                v2 = { type = "description", name = "|", order = 4, width = 0.05 },

                id = {
                    type = "description",
                    name = tostring(spell.id or ""),
                    order = 5,
                    width = 0.40,
                },
                v3 = { type = "description", name = "|", order = 6, width = 0.05 },

                enable = {
                    type = "toggle",
                    name = "",
                    order = 7,
                    width = 0.30,
                    get = function() return list[i] and (list[i].enable ~= false) end,
                    set = function(_, v)
                        if list[i] then
                            list[i].enable = v
                            CASTBAR_API:UpdateCastbar(unit)
                        end
                    end,
                },
                v4 = { type = "description", name = "|", order = 8, width = 0.05 },

                remove = {
                    type = "execute",dialogControl = "UCB_Button",
                    name = "Remove",
                    order = 9,
                    width = 0.60,
                    func = function()
                        table.remove(list, i)
                        CASTBAR_API:UpdateCastbar(unit)
                        BuildAbilityRows(abilityTable, cfg, unit)
                    end,
                },
            },
        }
    end
end

local function BuildAbilityFilterTable(cfg, unit, disabled)

    -- defaults
    if cfg.enableAbilityFilter == nil then cfg.enableAbilityFilter = false end
    if cfg.blackList == nil then cfg.blackList = true end

    cfg.blackListSpells = cfg.blackListSpells or {}
    cfg.whiteListSpells = cfg.whiteListSpells or {}

    cfg._abilityAdd = cfg._abilityAdd or ""
    cfg._abilitySelect = cfg._abilitySelect or ""

    local function AddSpellByID(id)
        id = tonumber(id)
        if not id then return false end

        local info = UIStructures:_SafeSpellInfo(id)
        local list = _GetActiveAbilityList(cfg)

        for _, existing in ipairs(list) do
            if existing.id == id then
                return false
            end
        end

        table.insert(list, {
            icon = info.icon,
            name = info.name,
            id = info.id,
            enable = true,
        })
        return true
    end

    local abilityTable
    abilityTable = {
        type = "group",
        name = "Ability Filter Table",
        inline = true,
        order = 1,
        disabled = function() return not cfg.enableAbilityFilter and disabled end, -- master toggle disables whole table
        hidden = function() return not cfg.enableAbilityFilter and not disabled end, -- hide table when master toggle is off
        args = {
            -- MODE HEADER + SWITCH BUTTON
            modeHeader = {
                type = "header",  dialogControl = "UCB_Heading",
                name = function()
                    if cfg.blackList then
                        return "Mode: "..UIOptions.ColorText(UIOptions.red, "Blacklist")
                    end
                    return "Mode: "..UIOptions.ColorText(UIOptions.green, "Whitelist")
                end,
                order = 0.4,
                width = "full",
            },

            switchMode = {
                type = "execute",dialogControl = "UCB_Button",
                name = "Switch mode",
                order = 0.5,
                width = 1.5,
                func = function()
                    cfg.blackList = not cfg.blackList
                    -- refresh rows for the other list
                    BuildAbilityRows(abilityTable, cfg, unit)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },

            spacer0 = { type = "description", name = "", order = 0.6, width = "full" },

            descToggle = {
                type = "description",
                name = function() return UIOptions.ColorText(UIOptions.turquoise, "You can either use a manual table or have the addon automatically read your player's spell list. The manual table allows you to add any spell by ID, while the player spell list will show all spells available to your class and spec.") end,
                order = 0.65,
                width = "full",
            },

            manualTableToggle = {
                type = "toggle",
                name = "Use Manual Table (instead of other options)",
                order = 0.7,
                width = 2,
                get = function() return cfg.useManualTable end,
                set = function(_, val)
                    cfg.useManualTable = val
                    BuildAbilityRows(abilityTable, cfg, unit)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },

            playerSpellListToggle = {
                type = "toggle",
                name = "Use Player Spell List (instead of other options)",
                order = 0.8,
                width = 2,
                disabled = function() return cfg.useManualTable or not cfg.enableAbilityFilter end,
                get = function() return cfg.usePlayerSpellList end,
                set = function(_, val)
                    cfg.usePlayerSpellList = val
                    BuildAbilityRows(abilityTable, cfg, unit)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },

            spacer1 = { type = "description", name = "", order = 0.9, width = "full" },

            selectGroup = UIStructures:createSelectBlock(cfg, 1),

            addRow = {
                type = "group",
                name = "Add Spell",
                inline = true,
                order = 2,
                args = {
                    spellId = {
                        type = "input",
                        name = "Add by Spell ID",
                        order = 2,
                        width = 1.5,
                        get = function() return tostring(cfg._abilityAdd or "") end,
                        set = function(_, v) cfg._abilityAdd = v end,
                    },

                    v1 = { type = "description", name = "", order = 2.5, width = 0.2 },

                    addBtn = {
                        type = "execute",dialogControl = "UCB_Button",
                        name = "Add Spell ID",
                        order = 3,
                        width = 1.5,
                        func = function()
                            if not cfg._abilityAdd or cfg._abilityAdd == "" then return end
                            local added = AddSpellByID(cfg._abilityAdd)
                            cfg._abilityAdd = ""
                            if added then
                                BuildAbilityRows(abilityTable, cfg, unit)
                                CASTBAR_API:UpdateCastbar(unit)
                            end
                        end,
                    },
                },
            },

            tableHeader = {
                type = "group",
                name = "",
                inline = true,
                order = 3,
                disabled = function() return not cfg.useManualTable end,
                args = {
                    h_icon = { type = "description", name = "Icon",   order = 1, width = 0.30 },
                    v1     = { type = "description", name = "|",      order = 2, width = 0.05 },
                    h_name = { type = "description", name = "Name",   order = 3, width = 1 },
                    v2     = { type = "description", name = "|",      order = 4, width = 0.05 },
                    h_id   = { type = "description", name = "ID",     order = 5, width = 0.40 },
                    v3     = { type = "description", name = "|",      order = 6, width = 0.05 },
                    h_en   = { type = "description", name = "Enable", order = 7, width = 0.30 },
                    v4     = { type = "description", name = "|",      order = 8, width = 0.05 },
                    h_rm   = { type = "description", name = "Remove", order = 9, width = 0.60 },
                },
            },

            rows = {
                type = "group",
                name = "",
                inline = true,
                order = 4,
                disabled = function() return not cfg.useManualTable end,
                args = {},
            },
        },
    }

    BuildAbilityRows(abilityTable, cfg, unit)
    return abilityTable
end

function UIStructures:BuildAbilityFilterSectionPlayer(cfg, unit, disabled, name, order)

    -- defaults (in case section is built before table)
    if cfg.enableAbilityFilter == nil then cfg.enableAbilityFilter = false end
    if cfg.blackList == nil then cfg.blackList = true end
    cfg.blackListSpells = cfg.blackListSpells or {}
    cfg.whiteListSpells = cfg.whiteListSpells or {}

    local abilityFilterSection = {
        type = "group",
        name = name or "Blacklist/Whitelist",
        order = order or 1,
        args = {
            enableAbilityFilter = {
                type  = "toggle",
                name  = "Enable Blacklist/Whitelist",
                order = 0,
                width = 2,
                get   = function() return cfg.enableAbilityFilter end,
                set   = function(_, val)
                    cfg.enableAbilityFilter = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },

            abilityTable = BuildAbilityFilterTable(cfg, unit, disabled),
        },
    }
    return abilityFilterSection
end

