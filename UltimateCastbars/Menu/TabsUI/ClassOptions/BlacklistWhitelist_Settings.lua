local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local UIOptions = UCB.UIOptions


-- Registry: classToken -> function(cfgGetter) -> argsTable
Opt.ClassExtraBuilders = Opt.ClassExtraBuilders or {}


local function _SafeSpellInfo(spellID)
    local id = tonumber(spellID)
    if not id then return nil end

    local info = C_Spell.GetSpellInfo(id)
    if not info then
        return { id = id, name = "Unknown", icon = 134400 }
    end

    return {
        id   = id,
        name = info.name or "Unknown",
        icon = info.originalIconID or 134400,
    }
end

local function _BuildAllSpellsDropdownValues()
    local merged, seen = {}, {}

    local function addList(list)
        for _, sid in ipairs(list or {}) do
            sid = tonumber(sid)
            if sid and not seen[sid] then
                local info = C_Spell.GetSpellInfo(sid)
                if info and info.name then
                    seen[sid] = true
                    table.insert(merged, { id = sid, name = info.name })
                end
            end
        end
    end

    addList(UCB.allSpellTypes and UCB.allSpellTypes.channel)
    addList(UCB.allSpellTypes and UCB.allSpellTypes.normal)
    addList(UCB.allSpellTypes and UCB.allSpellTypes.empowered)

    table.sort(merged, function(a, b)
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)

    local values = {}
    for _, s in ipairs(merged) do
        values[s.id] = s.name .. " - " .. s.id
    end
    return values
end

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
                    type = "execute",
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

local function BuildAbilityFilterTable(unit, class)
    local bigCFG = GetCFG(unit)
    local cfg = bigCFG.CLASSES[class]

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

        local info = _SafeSpellInfo(id)
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
        disabled = function() return not cfg.enableAbilityFilter end, -- master toggle disables whole table
        args = {
            -- MODE HEADER + SWITCH BUTTON
            modeHeader = {
                type = "header",
                name = function()
                    if cfg.blackList then
                        return "Mode: "..UIOptions.ColorText(UIOptions.red, "Blacklist")
                    end
                    return "Mode: "..UIOptions.ColorText(UIOptions.green, "Whitelist")
                end,
                order = 0.5,
                width = "full",
            },

            switchMode = {
                type = "execute",
                name = "Switch mode",
                order = 0.6,
                width = 1.5,
                func = function()
                    cfg.blackList = not cfg.blackList
                    -- refresh rows for the other list
                    BuildAbilityRows(abilityTable, cfg, unit)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },

            spacer0 = { type = "description", name = "", order = 0.7, width = "full" },

            selectGroup = {
                type = "group",
                name = "Select Spell",
                inline = true,
                order = 1,
                args = {
                    selectedSpell = {
                        type = "header",
                        name = function()
                            local info = _SafeSpellInfo(cfg._abilitySelect)
                            if info then
                                return "Selected: " .. UIOptions.ColorText(UIOptions.turquoise, info.name .. " (" .. tostring(info.id) .. ")")
                            end
                            return "Selected: " .. UIOptions.ColorText(UIOptions.red, "None")
                        end,
                        order = 1,
                        width = "full",
                    },

                    spellDescription = {
                        type = "description",
                        name = function()
                            local id = tonumber(cfg._abilitySelect)
                            local tooltip = (id and id >= -2147483648 and id <= 2147483647) and C_TooltipInfo.GetSpellByID(id) or nil
                            local spellDesc = tooltip and tooltip.lines and tooltip.lines[4] and tooltip.lines[4].leftText or "No description available."
                            return spellDesc
                        end,
                        order = 2,
                        width = "full",
                    },

                    selectedSpellId = {
                        type = "input",
                        name = "Selected Spell ID",
                        order = 3,
                        width = 1.5,
                        get = function() return tostring(cfg._abilitySelect or "") end,
                        set = function(_, v) end,
                    },

                    v1 = { type = "description", name = "", order = 3.5, width = 0.2 },

                    spellSelect = {
                        type = "select",
                        name = "All Spells For Current Class",
                        desc = "Channel + normal + empowered (merged)",
                        order = 4,
                        width = 1.5,
                        values = function()
                            return _BuildAllSpellsDropdownValues()
                        end,
                        get = function() return cfg._abilitySelect end,
                        set = function(_, v) cfg._abilitySelect = v end,
                    },
                },
            },

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
                        type = "execute",
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
                args = {},
            },
        },
    }

    BuildAbilityRows(abilityTable, cfg, unit)
    return abilityTable
end

function Opt:BuildAbilityFilterSectionPlayer(args, unit, class)
    local bigCFG = GetCFG(unit)
    local cfg = bigCFG.CLASSES[class]

    -- defaults (in case section is built before table)
    if cfg.enableAbilityFilter == nil then cfg.enableAbilityFilter = false end
    if cfg.blackList == nil then cfg.blackList = true end
    cfg.blackListSpells = cfg.blackListSpells or {}
    cfg.whiteListSpells = cfg.whiteListSpells or {}

    args.abilityFilterSection = {
        type = "group",
        name = "Blacklist/Whitelist Spells",
        order = 10,
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

            abilityTable = BuildAbilityFilterTable(unit, class),
        },
    }
end

