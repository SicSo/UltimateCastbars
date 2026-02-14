local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local BarUpdate_API = UCB.BarUpdate_API
local OtherFeatures_API = UCB.OtherFeatures_API

local LSM  = UCB.LSM

-- Registry: classToken -> function(cfgGetter) -> argsTable
Opt.ClassExtraBuilders = Opt.ClassExtraBuilders or {}



local function BuildChannelSettings(unit, class)
    local bigCFG = GetCfg(unit)
    local cfg = bigCFG.CLASSES[class]


    local channelSettings = {
        type = "group",
        name = "Channeling Class Settings (overrides main settings)",
        inline = true,
        order = 3,
        disabled = function() return not cfg.showChannelTicks or not bigCFG.otherFeatures.showChannelTicks or cfg.useMainSettingsChannel end,
        args = {
            channelTickInfo = {
                type = "description",
                name = "These options control the appearance of tick markers shown during channeled spells. For tick timings, use the next section.",
                order = 1,
                width = "full",
            },
            channelTickColour = {
                type = "color",
                name = "Tick Colour",
                desc = "Colour used for tick markers during channeled spells.",
                hasAlpha = true,
                order = 2,
                get = function()
                    local c = cfg.channelTickColour
                    return c.r, c.g, c.b, c.a
                end,
                set = function(_, r,g,b,a)
                    cfg.channelTickColour = {r=r,g=g,b=b,a=a}
                    CASTBAR_API:UpdateCastbar(unit)
                end,
                
            },
            channelTickWidth = {
                type = "range",
                name = "Tick Width",
                desc = "Thickness of tick markers during channeled spells.",
                min = UIOptions.channelTickWidthMin, max = UIOptions.channelTickWidthMax, step = 0.5,
                width = 1.5,
                order = 3,
                get = function() return tonumber(cfg.channelTickWidth) end,
                set = function(_, val)
                    cfg.channelTickWidth = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            tickTexture = {
                type = "group",
                name = "Tick Texture",
                inline = true,
                order = 4,
                args = {
                    useTickTexture = {
                        type  = "toggle",
                        name  = "Use texture for ticks",
                        order = 1,
                        get   = function() return cfg.useTickTexture end,
                        set   = function(_, val)
                            cfg.useTickTexture = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    tickTextureName = {
                        type          = "select",
                        dialogControl = "LSM30_Statusbar",
                        name          = "Tick texture",
                        order         = 2,
                        disabled      = function() return not cfg.useTickTexture end,
                        values        = function() return LSM:HashTable(LSM.MediaType.STATUSBAR) end,
                        get           = function() return cfg.tickTextureName end,
                        set           = function(_, val)
                            cfg.tickTextureName = val
                            cfg.tickTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, val)
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                }
            }
            
        },
    }
    return channelSettings
end


local function BuildRows(channelTable, cfg, unit)
    channelTable.args.rows.args = {}
    -- Build rows from cfg.channeledSpels (each entry uses lowercase keys)
    local rowsArgs = channelTable.args.rows.args
    for i, spell in ipairs(cfg.channeledSpels) do
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

                ticks = {
                    type = "range",
                    name = "",
                    order = 7,
                    width = 0.90,
                    min = UCB.UIOptions.channelTickNumMin, max = UCB.UIOptions.channelTickNumMax, step = 1,
                    get = function() return tonumber(cfg.channeledSpels[i].ticks or 1) end,
                    set = function(_, v) cfg.channeledSpels[i].ticks = v end,
                },
                v4 = { type = "description", name = "|", order = 8, width = 0.05 },

                enable = {
                    type = "toggle",
                    name = "",
                    order = 9,
                    width = 0.30,
                    get = function() return cfg.channeledSpels[i].enable ~= false end,
                    set = function(_, v) cfg.channeledSpels[i].enable = v end,
                },
                v5 = { type = "description", name = "|", order = 10, width = 0.05 },

                remove = {
                    type = "execute",
                    name = "Remove",
                    order = 11,
                    width = 0.60,
                    func = function()
                        table.remove(cfg.channeledSpels, i)
                        CASTBAR_API:UpdateCastbar(unit)
                        BuildRows(channelTable, cfg, unit)
                    end,
                },
            },
        }
    end
end

local function BuildChannelTable(args, unit, class)
    local bigCFG = GetCfg(unit)
    local cfg = bigCFG.CLASSES[class]

    -- temp fields for the "add" row
    cfg._channelAdd = cfg._channelAdd or ""
    cfg._channelSelect = cfg._channelSelect or ""

    local function AddSpellByID(id)
        id = tonumber(id)
        if not id then return end

        local spellInfo = C_Spell.GetSpellInfo(id)
        local name, icon
        if not spellInfo then
            name = "Unknown"
            icon = 134400 -- fallback icon
        end
        name = spellInfo and spellInfo.name or name
        icon = spellInfo and spellInfo.originalIconID or icon

        for _, spellInfo in ipairs(cfg.channeledSpels) do
            if spellInfo.id == id then
                --UIOptions.Print("Spell ID "..id.." is already in the channel spells list.")
                return false
            end
        end

        table.insert(cfg.channeledSpels, {
            icon = icon,
            name = name,
            id = id,
            ticks = 3,
            enable = true,
        })

        return true
    end

    local channelTable

    channelTable = {
        type = "group",
        name = "Channeling Spells",
        inline = true,
        order = 4,
        disabled = function() return not cfg.showChannelTicks or not bigCFG.otherFeatures.showChannelTicks end,
        args = {
            selectGroup = {
                type = "group",
                name = "Select Spell",
                inline = true,
                order = 1,
                args = {
                    selectedSpell = {
                        type = "header",
                        name = function ()
                            local spellInfo = C_Spell.GetSpellInfo(cfg._channelSelect)
                            if spellInfo then
                                return "Selected: "..UIOptions.ColorText(UIOptions.turquoise, spellInfo.name.." ("..cfg._channelSelect..")")
                            else
                                return "Selected: "..UIOptions.ColorText(UIOptions.red, "None")
                            end
                        end,
                        order = 1,
                        width = "full",
                    },

                    spellDescription = {
                        type = "description",
                        name = function ()
                            local id = tonumber(cfg._channelSelect)
                            local tooltip = (id and id >= -2147483648 and id <= 2147483647) and C_TooltipInfo.GetSpellByID(id) or nil
                            local spellDesc = tooltip and tooltip.lines and tooltip.lines[4] and tooltip.lines[4].leftText or "No description available." 
                            return spellDesc
                        end,
                        order = 2,
                        width = "full",
                    },
                    slectedSpellId = {
                        type = "input",
                        name = "Selected Spell ID",
                        order = 3,
                        width = 1.5,
                        get = function() return tostring(cfg._channelSelect or "") end,
                        set = function(_, v) end,
                    },
                    v1 = { type = "description", name = "", order = 3.5, width = 0.2 },


                    spellSelect = {
                        type = "select",
                        name = "Channel Spells",
                        desc = "",
                        order = 4,
                        width = 1.5,
                        values = function ()
                            local list = {}
                            for _, spellID in ipairs(UCB.allSpellTypes.channel or {}) do
                                local spellName = C_Spell.GetSpellInfo(spellID).name
                                if spellName then
                                    list[spellID] = spellName.." - "..spellID
                                end
                            end
                            return list
                        end,
                        get = function() return cfg._channelSelect end,
                        set = function(_, v) cfg._channelSelect = v end,
                    },

                },
            },
            addRow = {
                type = "group",
                name = "Add Spell by ID",
                inline = true,
                order = 2,
                args = {
                    spellId = {
                        type = "input",
                        name = "Spell ID",
                        order = 3,
                        width = 1.5,
                        get = function() return tostring(cfg._channelAdd or "") end,
                        set = function(_, v) cfg._channelAdd = v end,
                    },

                    v1 = { type = "description", name = "", order = 3.5, width = 0.2 },

                    addBtn = {
                        type = "execute",
                        name = "Add Spell",
                        order = 4,
                        width = 1.5,
                        func = function()
                            if not cfg._channelAdd or cfg._channelAdd == "" then return end
                            local added = AddSpellByID(cfg._channelAdd)
                            cfg._channelAdd = ""
                            if added then
                                BuildRows(channelTable, cfg, unit)
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
                order = 4,
                args = {
                    h_icon = { type = "description", name = "Icon",  order = 1, width = 0.30 },
                    v1    = { type = "description", name = "|",     order = 2, width = 0.05 },
                    h_name = { type = "description", name = "Name",  order = 3, width = 1 },
                    v2    = { type = "description", name = "|",     order = 4, width = 0.05 },
                    h_id   = { type = "description", name = "ID",    order = 5, width = 0.40 },
                    v3    = { type = "description", name = "|",     order = 6, width = 0.05 },
                    h_ticks= { type = "description", name = "Ticks", order = 7, width = 0.90 },
                    v4    = { type = "description", name = "|",     order = 8, width = 0.05 },
                    h_en   = { type = "description", name = "Enable",order = 9, width = 0.30 },
                    v5    = { type = "description", name = "|",     order = 10, width = 0.05 },
                    h_rm   = { type = "description", name = "Remove",order = 11, width = 0.60 },
                },
            },

            rows = {
                type = "group",
                name = "",
                inline = true,
                order = 5,
                args = {},
            },
        },
    }
    BuildRows(channelTable, cfg, unit)
    return channelTable
end

local function BuildChannelSectionPlayer(args, unit, class)
    local bigCFG = GetCfg(unit)
    local cfg = bigCFG.CLASSES[class]
    

    args.channelSection = {
        type = "group",
        name = "Channeling Spells",
        order = 3,
        args = {
            titleWarning = {
                type = "header",
                name = UIOptions.ColorText(UIOptions.red, "To use the channeling options, you need to enable them in the Other Features section first.") ,
                order = 0.5,
                width = "full",
                hidden = function() return bigCFG.otherFeatures.showChannelTicks end,
            },
            channelToogle = {
                type  = "toggle",
                name  = "Enable channeling options",
                order = 1,
                width = 1.5,
                get   = function() return cfg.showChannelTicks end,
                set   = function(_, val) 
                    cfg.showChannelTicks = val 
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
                disabled = function() return not bigCFG.otherFeatures.showChannelTicks end,
            },
            useMainSettings = {
                type  = "toggle",
                name  = "Use Other Features settings for channeling",
                order = 2,
                width = 1.5,
                get   = function() return cfg.useMainSettingsChannel end,
                set   = function(_, val)
                cfg.useMainSettingsChannel = val 
                CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return not cfg.showChannelTicks or not bigCFG.otherFeatures.showChannelTicks end,
            },
            channelSettings = BuildChannelSettings(unit, class),
            channelTable = BuildChannelTable(args, unit, class),
        },
    }
end

local function BuildChannelSpecSettings(args, unit, class)
    local bigCFG = GetCfg(unit)
    local cfg = bigCFG.CLASSES[class]
    local specs = cfg.specs
    local spec_data = UCB.specs[class].specs

    local channelTable

    channelTable = {
        type = "group",
        name = "Channeling Spells",
        inline = true,
        order = 4,
        disabled = function() return not cfg.showChannelTicks or not bigCFG.otherFeatures.showChannelTicks end,
        args = {
            tickGrpoup = {
                type = "group",
                name = "Channel Tick Settings by Spec",
                inline = true,
                order = 1,
                args = {
                    classTickGrp = {
                        type = "group",
                        name = "Class-wide settings",
                        inline = true,
                        order = 1,
                        args = {
                            enableTick = {
                                type = "toggle",
                                name = function() return "Enable ticks for ".. UCB.UIOptions.ColorText(UCB.UIOptions.classColoursList[class].HEX, class) end,
                                order = 1,
                                width = 2,
                                get = function() return cfg.enableTick end,
                                set = function(_, val) 
                                    cfg.enableTick = val 
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            tickNumber = {
                                type = "range",
                                name = function() return "Number of ticks for "..UCB.UIOptions.ColorText(UCB.UIOptions.classColoursList[class].HEX, class) end,
                                order = 2,
                                width = 1.5,
                                min = UCB.UIOptions.channelTickNumMin, max = UCB.UIOptions.channelTickNumMax, step = 1,
                                get = function() return tonumber(cfg.tickNumber) end,
                                set = function(_, val) 
                                    cfg.tickNumber = val 
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                                disabled = function() return not cfg.enableTick end,
                            },
                        },
                    },
                    --[[
                    specTickGrp = {
                        type = "group",
                        name = "Spec-specific settings",
                        inline = true,
                        order = 2,
                        args = {},
                    }
                    --]]
                },
            },
        }
    }
    --[[
    for specID, specInfo in pairs(specs) do
        channelTable.args.tickGrpoup.args.specTickGrp.args["spec"..specID] = {
            type = "group",
            name = function() return spec_data[specID] end,
            inline = true,
            order = specID,
            args = {
                enableTick = {
                    type = "toggle",
                    name = function() return "Enable ticks for "..UCB.UIOptions.ColorText(UCB.UIOptions.classColoursList[class].HEX, spec_data[specID]).." (overrides class-wide)" end,
                    order = 1,
                    width = 2,
                    get = function() return specInfo.enableTick end,
                    set = function(_, val) 
                        specInfo.enableTick = val 
                        CASTBAR_API:UpdateCastbar(unit)
                    end,
                },
                tickNumber = {
                    type = "range",
                    name = function () return"Number of ticks for "..UCB.UIOptions.ColorText(UCB.UIOptions.classColoursList[class].HEX, spec_data[specID]) end,
                    order = 2,
                    width = 1.5,
                    min = UCB.UIOptions.channelTickNumMin, max = UCB.UIOptions.channelTickNumMax, step = 1,
                    get = function() return tonumber(specInfo.tickNumber) end,
                    set = function(_, val) 
                        specInfo.tickNumber = val 
                        CASTBAR_API:UpdateCastbar(unit)
                    end,
                    disabled = function() return not specInfo.enableTick end,
                },
            },
        }
    end
    --]]
    return channelTable
end

local function BuildChannelSectionNonPlayer(args, unit, class)
    local bigCFG = GetCfg(unit)
    local cfg = bigCFG.CLASSES[class]

    args.channelSection = {
        type = "group",
        name = "Channeling Spells",
        order = 3,
        args = {
            titleWarning = {
                type = "header",
                name = UIOptions.ColorText(UIOptions.red, "To use the channeling options, you need to enable them in the Other Features section first.") ,
                order = 0.5,
                width = "full",
                hidden = function() return bigCFG.otherFeatures.showChannelTicks end,
            },
            channelToogle = {
                type  = "toggle",
                name  = "Enable channeling options",
                order = 1,
                width = 1.5,
                get   = function() return cfg.showChannelTicks end,
                set   = function(_, val) 
                    cfg.showChannelTicks = val 
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
                disabled = function() return not bigCFG.otherFeatures.showChannelTicks end,
            },
            useMainSettings = {
                type  = "toggle",
                name  = "Use Other Features settings for channeling",
                order = 2,
                width = 1.5,
                get   = function() return cfg.useMainSettingsChannel end,
                set   = function(_, val)
                cfg.useMainSettingsChannel = val 
                CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function() return not cfg.showChannelTicks or not bigCFG.otherFeatures.showChannelTicks end,
            },
            channelSettings = BuildChannelSettings(unit, class),
            channelTable = BuildChannelSpecSettings(args, unit, class),
        },
    }
end


Opt.ClassExtraBuilders["*"] = function(unit, classToken)
    local args = {}
    if unit == "player" then
        BuildChannelSectionPlayer(args, unit, classToken)
    else
        BuildChannelSectionNonPlayer(args, unit, classToken)
    end
    return args
end



-- Public builder
function Opt.BuildGeneralSettingsClass(unit, class, opts)
    opts = opts or {}
    local args = {}
    BuildChannelSectionPlayer(args, unit, class)

    return args
end


