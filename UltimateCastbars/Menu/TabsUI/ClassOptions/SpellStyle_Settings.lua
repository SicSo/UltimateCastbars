local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.UIStructures = UCB.UIStructures or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.Default_DB = UCB.Default_DB or {}
UCB.STYLE_API = UCB.STYLE_API or {}

local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local UIStructures = UCB.UIStructures
local CASTBAR_API = UCB.CASTBAR_API
local UIOptions = UCB.UIOptions
local STYLE_API = UCB.STYLE_API


-- Registry: classToken -> function(cfgGetter) -> argsTable
Opt.ClassExtraBuilders = Opt.ClassExtraBuilders or {}


local function GoToStyle(unit, ct)
    -- adjust these paths if your tree differs
    if ct ~= UCB.className then
        UCB:SelectGroup({"classSettings", "otherClasses", "class_" .. ct, "styleSection", "spellStyleGroup"}, unit)
    else
        UCB:SelectGroup({"classSettings", "class_" .. ct, "styleSection", "spellStyleGroup"}, unit)
    end
end


local function AddSpellByID(id, cfg)
    id = tonumber(id)
    if not id then return false end

    local info = UIStructures:_SafeSpellInfo(id)
    local list = cfg.styleSpells

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
        style = UCB.Default_DB:createStyle(),
    })
    return true
end

local function buildStyleWindow(args, unit, spellStyle)
    if not spellStyle then args.spellStyleWindow = {} return end
    args.spellStyleWindow = {
        type = "group",
        name = function() return "Editing style for: " .. (spellStyle.name or "Unknown") end,
        order = 3,
        inline =  true,
        args = UIStructures:BuildStyleWindow(spellStyle.style, unit),
    }
end


local function BuildSpellStyle(args, unit, cfg, indexedSpellStyle)

    if #cfg.styleSpells == 0 then args.styleSection.args.spellStyleGroup = nil return end
    if not indexedSpellStyle then indexedSpellStyle = 1 end
    cfg._setyleSpellsIndex = indexedSpellStyle
    local spellStyle = cfg.styleSpells[indexedSpellStyle]
    args.styleSection.args.spellStyleGroup = {
        type = "group",
        name = "Edit style options",
        inline = false,
        order = 2,
        hidden = function() return not cfg.useStyleSpell end,
        args = {
            header = {
                type = "header",
                name = function() 
                    local shown = spellStyle and spellStyle.enable and UIOptions.ColorText(UIOptions.green, "Enabled") or UIOptions.ColorText(UIOptions.red, "Disabled")
                    return "Spell " .. UIOptions.ColorText(UIOptions.turquoise, (spellStyle.name or "Unknown")) .. " - (" .. UIOptions.ColorText(UIOptions.turquoise, tostring(spellStyle.id or "")) .. ") (" .. shown..")" end,
                order = 0,
            },
            spellStyleSelection = {
                type = "select",
                name = "Select spell style to edit",
                order = 1,
                width = 1.2,
                values = function()
                    local vals
                    for i, spell in ipairs(cfg.styleSpells) do
                        vals = vals or {}
                        vals[i] = spell.name .. " (" .. spell.id .. ")"
                    end
                    return vals
                end,
                get = function() return indexedSpellStyle end,
                set = function(_, v)
                    BuildSpellStyle(args, unit, cfg, v)
                end,
            },
            gap1 = {
                type = "description",
                name = "",
                order = 1.5,
                width = "full",
            },
            enableSpellStyle = {
                type = "toggle",
                name = "Enable style for this spell",
                order = 2,
                width = 1.2,
                get = function() return spellStyle.enable end,
                set = function(_, v)
                    spellStyle.enable = v
                    BuildSpellStyle(args, unit, cfg, indexedSpellStyle)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
        }
    }
    buildStyleWindow(args.styleSection.args.spellStyleGroup.args, unit, spellStyle)
end

local function BuildAbilityRows(args, mainGrp, cfg, unit, class, bigCFG)
    local list = cfg.styleSpells

    mainGrp.args.contentGrp.args.spellTable.args.rows.args = {}
    local rowsArgs = mainGrp.args.contentGrp.args.spellTable.args.rows.args

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

                settings = {
                    type = "execute",
                    name = "Settings",
                    order = 9,
                    width = 0.60,
                    func = function()
                        BuildSpellStyle(args, unit, cfg, i)
                        GoToStyle(unit, class)
                    end,
                },

                v5 = { type = "description", name = "|", order = 10, width = 0.05 },

                remove = {
                    type = "execute",
                    name = "Remove",
                    order = 11,
                    width = 0.60,
                    func = function()
                        table.remove(list, i)
                        if #cfg.styleSpells == 0 or cfg._setyleSpellsIndex == i then
                            BuildSpellStyle(args, unit, cfg)
                        end
                        STYLE_API:RebuildSpellStyleCopyArgs(unit, bigCFG.styleCastType, bigCFG)
                        CASTBAR_API:UpdateCastbar(unit)
                        BuildAbilityRows(args, mainGrp, cfg, unit, class, bigCFG)
                    end,
                },
            },
        }
    end
end

local function buildMainGroup(args, cfg, unit, class, bigCFG)

    local mainGrp 
    mainGrp = {
        type = "group",
        name = "",
        inline = true,
        order = 1,
        args = {
            useStyleSpell = {
                type = "toggle",
                name = "Use specific spell styles",
                desc = "If enabled, the cast bar will use the style settings of a specific spell instead of the general cast type style settings.",
                order = 1,
                width = 1.2,
                get = function() return cfg.useStyleSpell end,
                set = function(_, value)
                    cfg.useStyleSpell = value
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            buttonsAll = {
                type = "group",
                name = "Quick navigation",
                order = 1.5,
                inline = true,
                hidden = function() return bigCFG.styleCastType.useGeneralStyle end,
                args = STYLE_API:createQuickButtons(unit, { "general", "normal", "channel", "empowered"}),
            },
            buttonsGeneral = {
                type = "group",
                name = "Quick navigation",
                order = 1.5,
                inline = true,
                hidden = function() return not bigCFG.styleCastType.useGeneralStyle end,
                args = STYLE_API:createQuickButtons(unit, { "general" }),
            },
            contentGrp = {
                type = "group",
                name = "",
                order = 2,
                inline = true,
                disabled = function() return not cfg.useStyleSpell end,
                args = {
                    spellSelectGroup = UIStructures:createSelectBlock(cfg, 1),
                    addSpell = {
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
                                get = function() return tostring(cfg._abilityAddStyle or "") end,
                                set = function(_, v) cfg._abilityAddStyle = v end,
                            },

                            v1 = { type = "description", name = "", order = 2.5, width = 0.2 },

                            addBtn = {
                                type = "execute",
                                name = "Add Spell ID",
                                order = 3,
                                width = 1.5,
                                func = function()
                                    if not cfg._abilityAddStyle or cfg._abilityAddStyle == "" then return end
                                    local added = AddSpellByID(cfg._abilityAddStyle, cfg)
                                    cfg._abilityAddStyle = ""
                                    if added then
                                        BuildAbilityRows(args, mainGrp, cfg, unit, class, bigCFG)
                                        BuildSpellStyle(args, unit, cfg, #cfg.styleSpells)
                                        STYLE_API:RebuildSpellStyleCopyArgs(unit, bigCFG.styleCastType, bigCFG)
                                        CASTBAR_API:UpdateCastbar(unit)
                                    end
                                end,
                            },
                        },
                    },
                    spellTable = {
                        type = "group",
                        name = "Spells with specific styles",
                        inline = true,
                        order = 3,
                        disabled = function() return not cfg.useStyleSpell or #cfg.styleSpells == 0 end,
                        args = {
                            tableHeader = {
                                type = "group",
                                name = "",
                                inline = true,
                                order = 1,
                                args = {
                                    h_icon = { type = "description", name = "Icon",   order = 1, width = 0.30 },
                                    v1     = { type = "description", name = "|",      order = 2, width = 0.05 },
                                    h_name = { type = "description", name = "Name",   order = 3, width = 1 },
                                    v2     = { type = "description", name = "|",      order = 4, width = 0.05 },
                                    h_id   = { type = "description", name = "ID",     order = 5, width = 0.40 },
                                    v3     = { type = "description", name = "|",      order = 6, width = 0.05 },
                                    h_en   = { type = "description", name = "Enable", order = 7, width = 0.30 },
                                    v4     = { type = "description", name = "|",      order = 8, width = 0.05 },
                                    h_st   = { type = "description", name = "Settings", order = 9, width = 0.60 },
                                    v5     = { type = "description", name = "|",      order = 10, width = 0.05 },
                                    h_rm   = { type = "description", name = "Remove", order = 11, width = 0.60 },
                                },
                            },

                            rows = {
                                type = "group",
                                name = "",
                                inline = true,
                                order = 2,
                                args = {},
                            },
                        },
                    }
                },
            },
            
        },
    }
    BuildAbilityRows(args, mainGrp, cfg, unit, class, bigCFG)
    return mainGrp
end


function Opt:BuildAbilityStylePlayer(args, unit, class)
    local bigCFG = GetCFG(unit)
    local cfg = bigCFG.CLASSES[class].spellStyling

    args.styleSection = {
        type = "group",
        name = "Per-spell style settings",
        order = 1,
        args = {
            mainGroup = buildMainGroup(args, cfg, unit, class, bigCFG),
            spellStyleWindow = nil,
        },
    }
    BuildSpellStyle(args, unit, cfg)
end

