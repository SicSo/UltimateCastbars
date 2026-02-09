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


-----------------------------------------------------------------------
-- EVOKER: wrapper group + extras
-----------------------------------------------------------------------
local function GetRGBA(t, fallback)
    if type(t) ~= "table" then t = fallback end
    if type(t) ~= "table" then return 1,1,1,1 end
    if t.r then return t.r or 1, t.g or 1, t.b or 1, t.a or 1 end
    return t[1] or 1, t[2] or 1, t[3] or 1, t[4] or 1
end

local function SetRGBA(store, r, g, b, a)
    store.r, store.g, store.b, store.a = r, g, b, a
end


-------------------------------------------------------------------
-- Build Empower Colours rows (3 columns) as its own inline group args
-------------------------------------------------------------------
local function BuildEmpowerColoursArgs(unit)
    local cfg = GetCfg(unit).CLASSES.EVOKER

    local out = {
        header = {
            type = "description",
            name = "Left = Tick  |  Middle = Segment Background  |  Right = Segment Castbar Colour",
            order = 1,
            width = "full",
        },
        enableBarTextures = {
            type = "toggle",
            name = "Enable segment tick textures",
            order = 2,
            width = "full",
            get = function() return cfg.showEmpowerTickTexture end,
            set = function(_, val)
                cfg.showEmpowerTickTexture = (val == true)
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },
        enableBackTextures = {
            type = "toggle",
            name = "Enable segment background textures",
            order = 3,
            width = "full",
            get = function() return cfg.showEmpowerSegmentTexture end,
            set = function(_, val)
                cfg.showEmpowerSegmentTexture = (val == true)
                CASTBAR_API:UpdateCastbar(unit)
            end,
        },

    }

    -- LibSharedMedia statusbar list (texture dropdown)
    local statusbarValues = (LSM and LSM.HashTable) and LSM:HashTable("statusbar") or {}

    -- Rows: Stage 0-1 .. 4-5 (5 rows)
    for stage = 1, 5 do
        local rowKey = "row" .. stage
        out[rowKey] = {
            type = "group",
            name = "Stage " .. (stage - 1) .. "-" .. stage,
            inline = true,
            order = 10 + stage,
            args = {},
        }
        local row = out[rowKey].args

        -- Column 1: Tick (no tick for stage 0-1, so spacer on row 1)
        if stage ~= 1 then
            row["tick" .. stage] = {
                type = "color",
                name = "Tick",
                hasAlpha = true,
                width = "third",
                order = 1,
                get = function()
                    cfg.empowerStageTickColours[stage - 1] = cfg.empowerStageTickColours[stage - 1] or {1,1,1,1}
                    return GetRGBA(cfg.empowerStageTickColours[stage - 1], {1,1,1,1})
                end,
                set = function(_, r, g, b, a)
                    cfg.empowerStageTickColours[stage - 1] = cfg.empowerStageTickColours[stage - 1] or {}
                    SetRGBA(cfg.empowerStageTickColours[stage - 1], r, g, b, a)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            }
        else
            row.tickSpacer = {
                type = "description",
                name = " ",
                width = "third",
                order = 1,
            }
        end

        -- Column 2: Segment background colour
        row["segBack" .. stage] = {
            type = "color",
            name = "Background",
            hasAlpha = true,
            width = "third",
            order = 2,
            get = function()
                cfg.empowerSegBackColours[stage] = cfg.empowerSegBackColours[stage] or {1,1,1,1}
                return GetRGBA(cfg.empowerSegBackColours[stage], {1,1,1,1})
            end,
            set = function(_, r, g, b, a)
                cfg.empowerSegBackColours[stage] = cfg.empowerSegBackColours[stage] or {}
                SetRGBA(cfg.empowerSegBackColours[stage], r, g, b, a)
                CASTBAR_API:UpdateCastbar(unit)
            end,
        }

        -- Column 3: Segment castbar colour
        row["segCast" .. stage] = {
            type = "color",
            name = "Castbar",
            hasAlpha = true,
            width = "third",
            order = 3,
            get = function()
                cfg.empowerBarColours[stage] = cfg.empowerBarColours[stage] or {1,1,1,1}
                return GetRGBA(cfg.empowerBarColours[stage], {1,1,1,1})
            end,
            set = function(_, r, g, b, a)
                cfg.empowerBarColours[stage] = cfg.empowerBarColours[stage] or {}
                SetRGBA(cfg.empowerBarColours[stage], r, g, b, a)
                CASTBAR_API:UpdateCastbar(unit)
            end,
        }
        if stage ~= 1 then
            -- NEW: per-tick castbar texture select
            row["segCastTex" .. stage] = {
                type = "select",
                name = "Tick Texture",
                dialogControl = "LSM30_Statusbar",
                values = statusbarValues,
                order = 4,
                --width = "half",
                hidden = function() return not cfg.showEmpowerTickTexture end,
                get = function()
                    return cfg.empowerTickTexturesNames[stage]
                end,
                set = function(_, v)
                    cfg.empowerTickTexturesNames[stage] = v
                    cfg.empowerTickTextures[stage] = LSM:Fetch(LSM.MediaType.STATUSBAR, v)
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            }
        else
            row.segCastTexSpacer = {
                type = "description",
                name = " ",
                --width = "half",
                order = 5,
                hidden = function() return not cfg.showEmpowerTickTexture end,
            }
        end
        -- NEW: per-stage background texture select
        row["segBackTex" .. stage] = {
            type = "select",
            name = "Background Texture",
            dialogControl = "LSM30_Statusbar",
            values = statusbarValues,
            order = 5,
            --width = "half",
            hidden = function() return not cfg.showEmpowerSegmentTexture end,
            get = function()
                -- default to whatever LSM considers "Blizzard" if unset; you can choose another default
                return cfg.empowerSegmentTexturesNames[stage]
            end,
            set = function(_, v)
                cfg.empowerSegmentTextures[stage] = LSM:Fetch(LSM.MediaType.STATUSBAR, v)
                CASTBAR_API:UpdateCastbar(unit)
            end,
        }
    end

    return out
end


 -------------------------------------------------------------------
-- Build Empower spell list as ONE line description (icons + names)
-------------------------------------------------------------------
local function BuildEmpowerSpellLineArgs()
    local empoweredSpellIDs = {
        359073, -- Eternity Surge
        357208, -- Fire Breath
        355936, -- Dream Breath
        367226, -- Spirit Bloom
        396286, -- Upheaval
    }
    local parts = {}
    for _, spellID in ipairs(empoweredSpellIDs) do
        local info = (C_Spell and C_Spell.GetSpellInfo) and C_Spell.GetSpellInfo(spellID) or nil
        local name = (info and info.name) or ("SpellID " .. tostring(spellID))
        local icon = (info and info.iconID) or 134400
        parts[#parts + 1] = ("|T%d:16:16:0:0|t %s"):format(icon, name)
    end
    return {
        line = {
            type = "description",
            name = table.concat(parts, "      "),
            order = 1,
            width = "full",
        },
    }
end



Opt.ClassExtraBuilders.EVOKER = function(unit)
    local cfg = GetCfg(unit).CLASSES.EVOKER

    -------------------------------------------------------------------
    -- WRAPPER GROUP: this gives the “boxed background” look
    -------------------------------------------------------------------
    return {
        evokerPanel = {
            type = "group",
            name = "Evoker Settings",
            inline = true,
            order = 1,
            args = {
                -- ---------------- Disintegrate ----------------
                disintegrateHeader = {
                    type = "header",
                    name = "Disintegrate Ticks",
                    order = 1,
                },
                disintegrateInfo = {
                    type = "description",
                    name = "Disintegrate ticks can be determined dynamically (based on Xepheris WA and addon logic) or statically (specified by the use in Channeling Spells). Enabling dynamic ticks is recommended for accuracy, especially with chaining. Disabling this does not by default assign ticks, for that you need use Channeling Spells.",
                    order = 2,
                    width = "full",
                },
                disintegrateDynamicTicks = {
                    type = "toggle",
                    name = "  Dynamic Disintegrate Ticks (recommended)",
                    desc = "When enabled, tick count is determined and placed dynamically based on Xepheris WA and addon logic.",
                    order = 3,
                    width = "full",
                    image = 4622451,
                    get = function()
                        return cfg.disintegrateDynamicTicks
                    end,
                    set = function(_, val)
                        cfg.disintegrateDynamicTicks = val
                        CASTBAR_API:UpdateCastbar(unit)
                    end,
                },
                -- ---------------- Empower ----------------
                empowerHeader = {
                    type = "header",
                    name = "Empower spell settings",
                    order = 4,
                },
                empowerSpellList = {
                    type = "group",
                    name = "",
                    inline = true,
                    order = 5,
                    args = BuildEmpowerSpellLineArgs(),
                },
                empowerTickWidth = {
                    type = "range",
                    name = "Empower Tick Width",
                    desc = "Width of each tick mark on the Empowered Cast Bar.",
                    width = "full",
                    min = 0.5, max = 30, step = 0.5,
                    order = 6,
                    get = function()
                        return cfg.empowerTickWidth
                    end,
                    set = function(_, v)
                        cfg.empowerTickWidth = v
                        CASTBAR_API:UpdateCastbar(unit)
                    end,
                },
                empowerColours = {
                    type = "group",
                    name = "Empower Cast Colours",
                    inline = true,
                    order = 7,
                    args = BuildEmpowerColoursArgs(unit),
                },
            },
        },
    }
end
