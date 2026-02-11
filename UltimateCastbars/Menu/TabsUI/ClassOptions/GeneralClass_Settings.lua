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



-- Registry: classToken -> function(cfgGetter) -> argsTable
Opt.ClassExtraBuilders = Opt.ClassExtraBuilders or {}

-- Public API: called by Options.lua
local function GetMaxOrder(argsTable)
    local maxOrder = 0
    for _, opt in pairs(argsTable or {}) do
        if type(opt) == "table" and type(opt.order) == "number" then
            if opt.order > maxOrder then
                maxOrder = opt.order
            end
        end
    end
    return maxOrder
end

local function GoToClassChannel(unit, ct)
    -- adjust these paths if your tree differs
    if ct ~= UCB.className then
        UCB:SelectGroup(unit, {"classSettings", "otherClasses", "class_" .. ct, "channelSection"})
    else
        UCB:SelectGroup(unit, {"classSettings", "class_" .. ct, "channelSection"})
    end
end

local function BuildOthersGroup(unit, classToken, order)
    local finalElement = {
        type = "group",
        name = "",
        inline = true,
        order = order or 999,
        args = {
            otherOptions = {
                type = "group",
                name = "Others",
                inline = true,
                order = 1,
                args = {
                    btn_channel = {
                        type = "execute",
                        name = "Channel Spells",
                        desc = "Jump to the Channel Spells section.",
                        width = "full",
                        order = 1,
                        func = function()
                            GoToClassChannel(unit, classToken)
                        end,
                    },
                },
            },
            headerRecommendation = {
                type = "header",
                name = "If you have specific class requests or suggestions, please let me know! :)",
                order = 2,
            }
        }
    }
    return finalElement
end

function Opt.GetExtraClassArgs(classToken, unit)
    local out = {}

    -- 1) Wildcard builder (all classes)
    do
        local fn = Opt.ClassExtraBuilders and Opt.ClassExtraBuilders["*"]
        if type(fn) == "function" then
            local ok, args = pcall(fn, unit, classToken)
            if ok and type(args) == "table" then
                for k, v in pairs(args) do
                    out[k] = v
                end
            end
        end
    end

    -- 2) Per-class builder (overrides/extends wildcard)
    do
        local fn = Opt.ClassExtraBuilders and Opt.ClassExtraBuilders[classToken]
        if type(fn) == "function" then
            local ok, args = pcall(fn, unit, classToken)
            if ok and type(args) == "table" then
                for k, v in pairs(args) do
                    out[k] = v
                end
            end
        end
    end

    -- 3) Append "Others" group at the very bottom for EVERY class
    local maxOrder = GetMaxOrder(out)
    out.others = BuildOthersGroup(unit, classToken, maxOrder + 100)

    return out
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



local function GoToClass(unit, ct)
    if ct ~= UCB.className then
        UCB:SelectGroup(unit, {"classSettings", "otherClasses", "class_" .. ct})
    else
        UCB:SelectGroup(unit, {"classSettings", "class_" .. ct})
    end
end

local function BuildClassButtonMatrix(unit, classes, excludeToken, groupName, groupOrder)
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
                func = function() GoToClass(unit, ct) end,
            }
            o = o + 1
            end
        end

        return btns
        end)(),
    }
end


function Opt.BuildClassSettingsArgs(unit, opts)
    unit = unit or "player"
    opts = opts or {}

    local classArgs = Opt._classTreeArgs or {}
    wipe(classArgs)
    Opt._classTreeArgs = classArgs

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
                for k, v in pairs(extraArgs) do a[k] = v end
                return a
            end)(),
        }
    end

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
                func = function() GoToClass(unit, UCB.className) end,
            },
        },
    }

    classArgs.classMatrix = BuildClassButtonMatrix(unit, classes, UCB.className, "Other Classes", 1)

    classArgs["class_" .. UCB.className] = BuildClassGroup(UCB.className, 2)

    classArgs.otherClasses = {
        type = "group",
        name = "Other Classes",
        order = 3,
        childGroups = "tree",
        args = (function()
            local other = {}
            other.classPicker = BuildClassButtonMatrix(unit, classes, UCB.className, "Other Classes", 0)

            local order = 1
            for _, ct in ipairs(classes) do
                if ct ~= UCB.className then
                    other["class_" .. ct] = BuildClassGroup(ct, order)
                    order = order + 1
                end
            end

            return other
        end)(),
    }

    return classArgs
end
