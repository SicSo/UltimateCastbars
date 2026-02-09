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

local function GoToClassChannel(ct)
    -- adjust these paths if your tree differs
    if ct ~= UCB.className then
        UCB.ACD:SelectGroup("UCB", "classSettings", "otherClasses", "class_" .. ct, "channelSection")
    else
        UCB.ACD:SelectGroup("UCB", "classSettings", "class_" .. ct, "channelSection")
    end
end

local function BuildOthersGroup(classToken, order)
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
                            GoToClassChannel(classToken)
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
    out.others = BuildOthersGroup(classToken, maxOrder + 100)

    return out
end
