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

local function DeepCopy(src)
    if type(src) ~= "table" then
        return src
    end

    local dst = {}
    for k, v in pairs(src) do
        dst[k] = DeepCopy(v)
    end
    return dst
end

local function EnsureSpellDefaults(spell)
    if not spell then return end

    if spell.enable == nil then spell.enable = true end
    if spell.enableCast == nil then spell.enableCast = true end
    if spell.enableInstant == nil then spell.enableInstant = false end
    if spell.useSameStyle == nil then spell.useSameStyle = false end
    if spell.sameStyleType == nil or (spell.sameStyleType ~= "cast" and spell.sameStyleType ~= "instant") then
        spell.sameStyleType = "cast"
    end
    if not spell.style then
        spell.style = UCB.Default_DB:createStyle()
    end
    if not spell.styleInstant then
        spell.styleInstant = UCB.Default_DB:createStyle()
    end
end

local function IsInstantGCDEnabled(bigCFG)
    return bigCFG
        and bigCFG.otherFeatures
        and bigCFG.otherFeatures.instantGCD
        and bigCFG.otherFeatures.instantGCD.enable
end

local function HasCustomInstantGCDStyle(bigCFG)
    return IsInstantGCDEnabled(bigCFG)
        and bigCFG.otherFeatures
        and bigCFG.otherFeatures.instantGCD
        and bigCFG.otherFeatures.instantGCD.useCustomStyle
        and bigCFG.otherFeatures.instantGCD.customStyle
end

local function GoToInstantGCD(unit)
    UCB:SelectGroup({ "otherFeatures", "gcdGrp" }, unit)
end

local function GetSpellStyleTable(spell, styleType)
    if styleType == "instant" then
        spell.styleInstant = spell.styleInstant or UCB.Default_DB:createStyle()
        return spell.styleInstant
    end

    spell.style = spell.style or UCB.Default_DB:createStyle()
    return spell.style
end

local function GetDisplayedStyleTable(spell, styleType)
    if spell.useSameStyle then
        return GetSpellStyleTable(spell, spell.sameStyleType or "cast")
    end
    return GetSpellStyleTable(spell, styleType)
end

local function IsStyleTypeEnabled(spell, styleType)
    if not spell.enable then
        return false
    end

    if spell.useSameStyle then
        return spell.sameStyleType == styleType
    end

    if styleType == "instant" then
        return spell.enableInstant
    end

    return spell.enableCast
end

local function GoToStyle(unit, ct)
    if ct and ct ~= UCB.className then
        UCB:SelectGroup({ "classSettings", "otherClasses", "class_" .. ct, "styleSection", "spellStyleGroup" }, unit)
    else
        if not ct then
            UCB:SelectGroup({ "classSettings", "class_" .. UCB.className, "styleSection", "spellStyleGroup" }, unit)
        else
            UCB:SelectGroup({ "classSettings", "class_" .. ct, "styleSection", "spellStyleGroup" }, unit)
        end
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
        enableCast = true,
        enableInstant = false,
        useSameStyle = false,
        sameStyleType = "cast",
        style = UCB.Default_DB:createStyle(),
        styleInstant = UCB.Default_DB:createStyle(),
    })
    return true
end

local function GetMainStyleValues(bigCFG)
    local vals = {}

    vals.general = "General"

    if not bigCFG.styleCastType.useGeneralStyle then
        vals.normal = "Normal"
        vals.channel = "Channel"
        vals.empowered = "Empowered"
    end

    if HasCustomInstantGCDStyle(bigCFG) then
        vals.customGCD = "Custom GCD"
    end

    return vals
end

local function GetMainStyleTable(bigCFG, key)
    if key == "customGCD" then
        if HasCustomInstantGCDStyle(bigCFG) then
            return bigCFG.otherFeatures.instantGCD.customStyle
        end
        return nil
    end

    if not bigCFG or not bigCFG.styleCastType then return nil end

    local entry = bigCFG.styleCastType[key]
    if not entry then return nil end

    if entry.style then
        return entry.style
    end

    return entry
end

local function BuildSpellValues(cfg, currentIndex, sourceStyleType, targetStyleType)
    local vals = {}

    for i, spell in ipairs(cfg.styleSpells) do
        EnsureSpellDefaults(spell)

        local allow = true

        if sourceStyleType == targetStyleType and i == currentIndex then
            allow = false
        end

        if allow then
            vals[i] = (spell.name or "Unknown") .. " (" .. tostring(spell.id or "") .. ")"
        end
    end

    return vals
end

local function CreateCopySettingsGroup(unit, cfg, bigCFG, indexedSpellStyle, targetStyleType)
    local spell = cfg.styleSpells[indexedSpellStyle]
    if not spell then
        return {
            type = "group",
            name = "Copy settings",
            inline = true,
            args = {},
        }
    end

    local sourceSameKey = "_copyFrom_" .. targetStyleType .. "_spell"
    local sourceOtherKey = "_copyFrom_" .. targetStyleType .. "_opposite"
    local sourceMainKey = "_copyFrom_" .. targetStyleType .. "_main"

    local oppositeStyleType = targetStyleType == "cast" and "instant" or "cast"

    local function GetSpellLabel(idx)
        local src = idx and cfg.styleSpells[idx]
        if not src then
            return UIOptions.ColorText(UIOptions.red, "None")
        end
        return UIOptions.ColorText(
            UIOptions.turquoise,
            (src.name or "Unknown") .. " (" .. tostring(src.id or "") .. ")"
        )
    end

    local function GetMainLabel(key)
        local labels = {
            general = "General",
            normal = "Normal",
            channel = "Channel",
            empowered = "Empowered",
            customGCD = "Custom GCD",
        }
        return UIOptions.ColorText(UIOptions.turquoise, labels[key] or "General")
    end

    local function ResetStyleTable(styleTbl)
        if not styleTbl then return end
        wipe(styleTbl)

        local defaults = UCB.Default_DB:createStyle()
        for k, v in pairs(DeepCopy(defaults)) do
            styleTbl[k] = v
        end
    end

    return {
        type = "group",
        name = "Copy settings",
        inline = true,
        args = {
            copySameSelect = {
                type = "select",
                name = targetStyleType == "cast" and "Copy from cast spell" or "Copy from instant spell",
                order = 1,
                width = 1.6,
                values = function()
                    return BuildSpellValues(cfg, indexedSpellStyle, targetStyleType, targetStyleType)
                end,
                get = function()
                    return spell[sourceSameKey]
                end,
                set = function(_, v)
                    spell[sourceSameKey] = v
                end,
            },
            copySameBtn = {
                type = "execute",
                dialogControl = "UCB_Button",
                name = function()
                    return "Copy from " .. GetSpellLabel(spell[sourceSameKey])
                end,
                order = 2,
                width = 1.6,
                func = function()
                    local sourceIndex = spell[sourceSameKey]
                    local sourceSpell = sourceIndex and cfg.styleSpells[sourceIndex]
                    if not sourceSpell then return end

                    local src = GetSpellStyleTable(sourceSpell, targetStyleType)
                    local dst = GetSpellStyleTable(spell, targetStyleType)
                    wipe(dst)
                    for k, v in pairs(DeepCopy(src)) do
                        dst[k] = v
                    end
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },

            gapRow1 = {
                type = "description",
                name = "",
                order = 2.5,
                width = "full",
            },

            copyOppositeSelect = {
                type = "select",
                name = targetStyleType == "cast" and "Copy from instant spell" or "Copy from cast spell",
                order = 3,
                width = 1.6,
                values = function()
                    return BuildSpellValues(cfg, indexedSpellStyle, oppositeStyleType, targetStyleType)
                end,
                get = function()
                    return spell[sourceOtherKey]
                end,
                set = function(_, v)
                    spell[sourceOtherKey] = v
                end,
            },
            copyOppositeBtn = {
                type = "execute",
                dialogControl = "UCB_Button",
                name = function()
                    local typeName = oppositeStyleType == "cast"
                        and UIOptions.ColorText(UIOptions.turquoise, "Cast")
                        or UIOptions.ColorText(UIOptions.turquoise, "Instant")

                    return "Copy from " .. typeName .. ": " .. GetSpellLabel(spell[sourceOtherKey])
                end,
                order = 4,
                width = 1.6,
                func = function()
                    local sourceIndex = spell[sourceOtherKey]
                    local sourceSpell = sourceIndex and cfg.styleSpells[sourceIndex]
                    if not sourceSpell then return end

                    local src = GetSpellStyleTable(sourceSpell, oppositeStyleType)
                    local dst = GetSpellStyleTable(spell, targetStyleType)
                    wipe(dst)
                    for k, v in pairs(DeepCopy(src)) do
                        dst[k] = v
                    end
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },

            gapRow2 = {
                type = "description",
                name = "",
                order = 4.5,
                width = "full",
            },

            copyMainSelect = {
                type = "select",
                name = "Copy from main style",
                order = 5,
                width = 1.6,
                values = function()
                    return GetMainStyleValues(bigCFG)
                end,
                get = function()
                    return spell[sourceMainKey] or "general"
                end,
                set = function(_, v)
                    spell[sourceMainKey] = v
                end,
            },
            copyMainBtn = {
                type = "execute",
                dialogControl = "UCB_Button",
                name = function()
                    return "Copy from " .. GetMainLabel(spell[sourceMainKey] or "general")
                end,
                order = 6,
                width = 1.6,
                func = function()
                    local sourceKey = spell[sourceMainKey] or "general"
                    local src = GetMainStyleTable(bigCFG, sourceKey)
                    local dst = GetSpellStyleTable(spell, targetStyleType)
                    if type(src) ~= "table" then return end

                    wipe(dst)
                    for k, v in pairs(DeepCopy(src)) do
                        dst[k] = v
                    end
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },

            gapRow3 = {
                type = "description",
                name = "",
                order = 6.5,
                width = "full",
            },

            resetBtn = {
                type = "execute",
                dialogControl = "UCB_Button",
                name = function()
                    local shown = targetStyleType == "cast"
                        and UIOptions.ColorText(UIOptions.turquoise, "Cast")
                        or UIOptions.ColorText(UIOptions.turquoise, "Instant")
                    return "Reset " .. shown .. " style"
                end,
                order = 7,
                width = 1.4,
                func = function()
                    local dst = GetSpellStyleTable(spell, targetStyleType)
                    ResetStyleTable(dst)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
        },
    }
end

local function BuildSpellStyle(args, unit, cfg, bigCFG, class, indexedSpellStyle)
    if #cfg.styleSpells == 0 then
        args.styleSection.args.spellStyleGroup = nil
        return
    end

    if not indexedSpellStyle then
        indexedSpellStyle = 1
    end

    cfg._setyleSpellsIndex = indexedSpellStyle
    local spellStyle = cfg.styleSpells[indexedSpellStyle]
    EnsureSpellDefaults(spellStyle)

    if spellStyle._uiSelectedStyleType == nil then
        spellStyle._uiSelectedStyleType = "cast"
    end

    args.styleSection.args.spellStyleGroup = {
        type = "group",
        name = "Edit style options",
        inline = false,
        order = 2,
        hidden = function() return not cfg.useStyleSpell end,
        args = {
            header = {
                type = "header",
                dialogControl = "UCB_Heading",
                name = function()
                    local shown = spellStyle and spellStyle.enable and UIOptions.ColorText(UIOptions.green, "Enabled")
                        or UIOptions.ColorText(UIOptions.red, "Disabled")

                    return "Spell "
                        .. UIOptions.ColorText(UIOptions.turquoise, (spellStyle.name or "Unknown"))
                        .. " - ("
                        .. UIOptions.ColorText(UIOptions.turquoise, tostring(spellStyle.id or ""))
                        .. ") ("
                        .. shown
                        .. ")"
                end,
                order = 0.1,
            },

            quickButtons = {
                type = "group",
                name = "Quick navigation",
                order = 0.2,
                inline = true,
                args = {
                    back = {
                        type = "execute",
                        dialogControl = "UCB_Button",
                        name = "Back to table",
                        order = 1,
                        func = function()
                            if class ~= UCB.className then
                                UCB:SelectGroup({ "classSettings", "otherClasses", "class_" .. class, "styleSection" }, unit)
                            else
                                UCB:SelectGroup({ "classSettings", "class_" .. class, "styleSection" }, unit)
                            end
                        end,
                    },
                },
            },

            enableSpellStyle = {
                type = "toggle",
                dialogControl = "UCB_CheckBox",
                name = "Enable style for this spell",
                order = 1,
                width = 1.4,
                get = function()
                    return spellStyle.enable
                end,
                set = function(_, v)
                    spellStyle.enable = v
                    CASTBAR_API:UpdateCastbar(unit)
                    BuildSpellStyle(args, unit, cfg, bigCFG, class, indexedSpellStyle)
                end,
            },

            instantGCDButton = {
                type = "execute",
                dialogControl = "UCB_Button",
                name = "Instant GCD settings",
                order = 1.5,
                width = 1.4,
                hidden = function()
                    return not spellStyle.enable
                end,
                func = function()
                    GoToInstantGCD(unit)
                end,
            },

            typeFlags = {
                type = "group",
                name = "",
                order = 2,
                inline = true,
                disabled = function()
                    return not spellStyle.enable
                end,
                args = {
                    enableCast = {
                        type = "toggle",
                        dialogControl = "UCB_CheckBox",
                        name = "Enable cast",
                        order = 1,
                        width = 1.1,
                        get = function()
                            return spellStyle.enableCast
                        end,
                        set = function(_, v)
                            spellStyle.enableCast = v

                            if not spellStyle.enableCast and not spellStyle.enableInstant then
                                spellStyle.enableCast = true
                            end

                            if spellStyle.useSameStyle and spellStyle.sameStyleType == "cast" and not spellStyle.enableCast then
                                spellStyle.useSameStyle = false
                            end

                            CASTBAR_API:UpdateCastbar(unit)
                            BuildSpellStyle(args, unit, cfg, bigCFG, class, indexedSpellStyle)
                        end,
                    },
                    enableInstant = {
                        type = "toggle",
                        dialogControl = "UCB_CheckBox",
                        name = "Enable instant",
                        order = 2,
                        width = 1.1,
                        disabled = function()
                            return not IsInstantGCDEnabled(bigCFG)
                        end,
                        get = function()
                            return spellStyle.enableInstant
                        end,
                        set = function(_, v)
                            spellStyle.enableInstant = v

                            if not spellStyle.enableCast and not spellStyle.enableInstant then
                                spellStyle.enableCast = true
                            end

                            if spellStyle.useSameStyle and spellStyle.sameStyleType == "instant" and not spellStyle.enableInstant then
                                spellStyle.useSameStyle = false
                            end

                            CASTBAR_API:UpdateCastbar(unit)
                            BuildSpellStyle(args, unit, cfg, bigCFG, class, indexedSpellStyle)
                        end,
                    },
                },
            },

            sameStyleRow = {
                type = "group",
                name = "",
                order = 3,
                inline = true,
                disabled = function()
                    return not spellStyle.enable
                end,
                args = {
                    useSameStyle = {
                        type = "toggle",
                        dialogControl = "UCB_CheckBox",
                        name = "Use same type",
                        order = 1,
                        width = 1.1,
                        get = function()
                            return spellStyle.useSameStyle
                        end,
                        set = function(_, v)
                            spellStyle.useSameStyle = v

                            if spellStyle.useSameStyle then
                                local sameType = spellStyle.sameStyleType or "cast"
                                if sameType == "instant" and not spellStyle.enableInstant then
                                    spellStyle.sameStyleType = "cast"
                                elseif sameType == "cast" and not spellStyle.enableCast then
                                    spellStyle.sameStyleType = spellStyle.enableInstant and "instant" or "cast"
                                end
                            end

                            CASTBAR_API:UpdateCastbar(unit)
                            BuildSpellStyle(args, unit, cfg, bigCFG, class, indexedSpellStyle)
                        end,
                    },
                    sameStyleType = {
                        type = "select",
                        name = "Type",
                        order = 2,
                        width = 1.1,
                        hidden = function()
                            return not spellStyle.useSameStyle
                        end,
                        values = function()
                            local vals = {}
                            if spellStyle.enableCast then
                                vals.cast = "Cast"
                            end
                            if spellStyle.enableInstant then
                                vals.instant = "Instant"
                            end
                            if not vals.cast and not vals.instant then
                                vals.cast = "Cast"
                            end
                            return vals
                        end,
                        get = function()
                            return spellStyle.sameStyleType or "cast"
                        end,
                        set = function(_, v)
                            spellStyle.sameStyleType = v or "cast"
                            CASTBAR_API:UpdateCastbar(unit)
                            BuildSpellStyle(args, unit, cfg, bigCFG, class, indexedSpellStyle)
                        end,
                    },
                },
            },

            spellStyleSelection = {
                type = "select",
                name = "Select spell style to edit",
                order = 4,
                width = 1.3,
                values = function()
                    local vals = {}
                    for i, spell in ipairs(cfg.styleSpells) do
                        vals[i] = (spell.name or "Unknown") .. " (" .. tostring(spell.id or "") .. ")"
                    end
                    return vals
                end,
                get = function()
                    return indexedSpellStyle
                end,
                set = function(_, v)
                    BuildSpellStyle(args, unit, cfg, bigCFG, class, v)
                end,
            },

            gap1 = {
                type = "description",
                name = "",
                order = 4.5,
                width = "full",
            },

            activeCopyGroup = {
                type = "group",
                name = "Copy settings",
                order = 5,
                inline = true,
                args = CreateCopySettingsGroup(unit, cfg, bigCFG, indexedSpellStyle, spellStyle._uiSelectedStyleType or "cast").args,
            },

            gapBeforeEditorHeader = {
                type = "description",
                name = "",
                order = 5.05,
                width = "full",
            },

            switchStyleEditorType = {
                type = "execute",
                dialogControl = "UCB_Button",
                name = function()
                    local currentType = spellStyle._uiSelectedStyleType or "cast"
                    if currentType == "cast" then
                        return "Switch to " .. UIOptions.ColorText(UIOptions.turquoise, "Instant")
                    end
                    return "Switch to " .. UIOptions.ColorText(UIOptions.turquoise, "Cast")
                end,
                order = 5.1,
                width = 1.3,
                func = function()
                    local currentType = spellStyle._uiSelectedStyleType or "cast"
                    if currentType == "cast" then
                        spellStyle._uiSelectedStyleType = "instant"
                    else
                        spellStyle._uiSelectedStyleType = "cast"
                    end
                    BuildSpellStyle(args, unit, cfg, bigCFG, class, indexedSpellStyle)
                end,
            },

            styleEditorHeader = {
                type = "header",
                dialogControl = "UCB_Heading",
                name = function()
                    local currentType = spellStyle._uiSelectedStyleType or "cast"
                    local shown = currentType == "instant" and "Instant" or "Cast"
                    return "Now editing: " .. UIOptions.ColorText(UIOptions.turquoise, shown)
                end,
                order = 5.2,
            },

            gapStyleEditor = {
                type = "description",
                name = "",
                order = 5.3,
                width = "full",
            },

            castGroup = {
                type = "group",
                name = "Cast",
                order = 6,
                inline = true,
                hidden = function()
                    return (spellStyle._uiSelectedStyleType or "cast") ~= "cast"
                end,
                disabled = function()
                    return not IsStyleTypeEnabled(spellStyle, "cast")
                end,
                args = {
                    gap1 = {
                        type = "description",
                        name = "",
                        order = 1,
                        width = "full",
                    },
                    styleWindow = {
                        type = "group",
                        name = "Cast style",
                        order = 2,
                        inline = true,
                        args = UIStructures:BuildStyleWindow(GetDisplayedStyleTable(spellStyle, "cast"), unit),
                    },
                },
            },

            instantGroup = {
                type = "group",
                name = "Instant",
                order = 7,
                inline = true,
                hidden = function()
                    return (spellStyle._uiSelectedStyleType or "cast") ~= "instant"
                end,
                args = {
                    instantDisabledText = {
                        type = "description",
                        order = 0.5,
                        width = "full",
                        hidden = function()
                            return IsInstantGCDEnabled(bigCFG)
                        end,
                        name = UIOptions.ColorText(
                            UIOptions.red,
                            "In order to edit instant cast, go back to the Instant GCD settings and enable quick cast."
                        ),
                    },
                    instantDisabledBtn = {
                        type = "execute",
                        dialogControl = "UCB_Button",
                        name = "Go to Instant GCD settings",
                        order = 0.6,
                        width = 1.6,
                        hidden = function()
                            return IsInstantGCDEnabled(bigCFG)
                        end,
                        func = function()
                            GoToInstantGCD(unit)
                        end,
                    },
                    gap1 = {
                        type = "description",
                        name = "",
                        order = 1,
                        width = "full",
                    },
                    styleWindow = {
                        type = "group",
                        name = "Instant style",
                        order = 2,
                        inline = true,
                        disabled = function()
                            return not IsInstantGCDEnabled(bigCFG) or not IsStyleTypeEnabled(spellStyle, "instant")
                        end,
                        args = UIStructures:BuildStyleWindow(GetDisplayedStyleTable(spellStyle, "instant"), unit),
                    },
                },
            },
        },
    }
end

local function BuildAbilityRows(args, mainGrp, cfg, unit, class, bigCFG)
    local list = cfg.styleSpells

    mainGrp.args.contentGrp.args.spellTable.args.rows.args = {}
    local rowsArgs = mainGrp.args.contentGrp.args.spellTable.args.rows.args

    for i, spell in ipairs(list) do
        EnsureSpellDefaults(spell)

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
                    dialogControl = "UCB_CheckBox",
                    name = "",
                    order = 7,
                    width = 0.30,
                    get = function()
                        return list[i] and (list[i].enable ~= false)
                    end,
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
                    dialogControl = "UCB_Button",
                    name = "Settings",
                    order = 9,
                    width = 0.60,
                    func = function()
                        BuildSpellStyle(args, unit, cfg, bigCFG, class, i)
                        GoToStyle(unit, class)
                    end,
                },

                v5 = { type = "description", name = "|", order = 10, width = 0.05 },

                remove = {
                    type = "execute",
                    dialogControl = "UCB_Button",
                    name = "Remove",
                    order = 11,
                    width = 0.60,
                    func = function()
                        table.remove(list, i)
                        if #cfg.styleSpells == 0 or cfg._setyleSpellsIndex == i then
                            BuildSpellStyle(args, unit, cfg, bigCFG, class)
                        end
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
            buttonsAll = {
                type = "group",
                name = "Quick navigation",
                order = 0.5,
                inline = true,
                hidden = function()
                    return bigCFG.styleCastType.useGeneralStyle
                end,
                args = STYLE_API:createQuickButtons(unit, { "general", "normal", "channel", "empowered" }),
            },

            buttonsGeneral = {
                type = "group",
                name = "Quick navigation",
                order = 0.5,
                inline = true,
                hidden = function()
                    return not bigCFG.styleCastType.useGeneralStyle
                end,
                args = STYLE_API:createQuickButtons(unit, { "general" }),
            },

            useStyleSpell = {
                type = "toggle",
                dialogControl = "UCB_CheckBox",
                name = "Use specific spell styles",
                desc = "If enabled, the cast bar will use the style settings of a specific spell instead of the general cast type style settings.",
                order = 1,
                width = 1.2,
                get = function()
                    return cfg.useStyleSpell
                end,
                set = function(_, value)
                    cfg.useStyleSpell = value
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },

            contentGrp = {
                type = "group",
                name = "",
                order = 2,
                inline = true,
                --disabled = function() return not cfg.useStyleSpell end,
                args = {
                    spellSelectGroup = UIStructures:createSelectBlock(cfg, 1),

                    addSpell = {
                        type = "group",
                        name = "Add Spell",
                        inline = true,
                        order = 2,
                        disabled = function() return not cfg.useStyleSpell end,
                        args = {
                            spellId = {
                                type = "input",
                                dialogControl = "UCB_EditBox",
                                name = "Add by Spell ID",
                                order = 2,
                                width = 1.5,
                                get = function()
                                    return tostring(cfg._abilityAddStyle or "")
                                end,
                                set = function(_, v)
                                    cfg._abilityAddStyle = v
                                end,
                            },

                            v1 = { type = "description", name = "", order = 2.5, width = 0.2 },

                            addBtn = {
                                type = "execute",
                                dialogControl = "UCB_Button",
                                name = "Add Spell ID",
                                order = 3,
                                width = 1.5,
                                func = function()
                                    if not cfg._abilityAddStyle or cfg._abilityAddStyle == "" then return end

                                    local added = AddSpellByID(cfg._abilityAddStyle, cfg)
                                    cfg._abilityAddStyle = ""

                                    if added then
                                        BuildAbilityRows(args, mainGrp, cfg, unit, class, bigCFG)
                                        BuildSpellStyle(args, unit, cfg, bigCFG, class, #cfg.styleSpells)
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
                        disabled = function()
                            return not cfg.useStyleSpell or #cfg.styleSpells == 0
                        end,
                        args = {
                            tableHeader = {
                                type = "group",
                                name = "",
                                inline = true,
                                order = 1,
                                args = {
                                    h_icon = { type = "description", name = "Icon", order = 1, width = 0.30 },
                                    v1 = { type = "description", name = "|", order = 2, width = 0.05 },
                                    h_name = { type = "description", name = "Name", order = 3, width = 1 },
                                    v2 = { type = "description", name = "|", order = 4, width = 0.05 },
                                    h_id = { type = "description", name = "ID", order = 5, width = 0.40 },
                                    v3 = { type = "description", name = "|", order = 6, width = 0.05 },
                                    h_en = { type = "description", name = "Enable", order = 7, width = 0.30 },
                                    v4 = { type = "description", name = "|", order = 8, width = 0.05 },
                                    h_st = { type = "description", name = "Settings", order = 9, width = 0.60 },
                                    v5 = { type = "description", name = "|", order = 10, width = 0.05 },
                                    h_rm = { type = "description", name = "Remove", order = 11, width = 0.60 },
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
                    },
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

    cfg.styleSpells = cfg.styleSpells or {}
    for _, spell in ipairs(cfg.styleSpells) do
        EnsureSpellDefaults(spell)
    end

    args.styleSection = {
        type = "group",
        name = "Per-spell style settings",
        order = 1,
        args = {
            mainGroup = buildMainGroup(args, cfg, unit, class, bigCFG),
            spellStyleWindow = nil,
        },
    }

    BuildSpellStyle(args, unit, cfg, bigCFG, class)
end