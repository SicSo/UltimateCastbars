local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}
UCB.UIStructures = UCB.UIStructures or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local UIOptions = UCB.UIOptions
local OtherFeatures_API = UCB.OtherFeatures_API
local UIStructures = UCB.UIStructures
local LSM  = UCB.LSM

local function createPaths()
    return {
        general = {"otherFeatures"},
        channel = {"otherFeatures" , "channelTickGrp"},
        spell_que = {"otherFeatures" , "spellQueGrp"},
        latency = {"otherFeatures" , "latencyGrp"},
        mirror_inverse = {"otherFeatures" , "inversMirrorGrp"},
        interruptedEffect = {"otherFeatures" , "kickedGrp"},
        cancelledEffect = {"otherFeatures" , "cancelledGrp"},
    }
end

local function createNames()
    return {
        channel = "Channeling Options",
        spell_que = "Spell Queue",
        latency = "Latency Indicator",
        mirror_inverse = "Mirror/Inverse Bar",
        interruptedEffect = "Interrupted Effect",
        cancelledEffect = "Cancelled Effect",
    }
end



local function createQuickButtons(unit, tabs, names, paths, buttonSize)
    local buttons = {}
    for index, tab in ipairs(tabs) do
        buttons["btn_"..tab] = {
            type = "execute",dialogControl = "UCB_Button",
            name = function() return UIOptions.MakeTitle(names[tab]) end,
            desc = function() return "Jump to "..UIOptions.MakeTitle(names[tab]) end,
            width = buttonSize,
            order = index,
            func = function()
                UCB:SelectGroup(paths[tab], unit)
            end,
        }
        buttons["gap_"..tab] = {
            type = "description",
            name = "",
            order = index + 0.5,
            width = 0.2,
        }
    end
    return buttons
end



local function BuildOtherArgs(args, unit)
    local cfg = GetCFG(unit, "otherFeatures")

    args.quickButtonsPlayer = {
        type = "group",
        name = "Quick Navigation",
        inline = true,
        order = 0.1,
        hidden = function() return not UCB:IsPlayer(unit) end,
        args = createQuickButtons(unit, {"channel", "spell_que", "latency", "mirror_inverse", "interruptedEffect", "cancelledEffect"}, createNames(), createPaths(), 0.8),
    }
    args.quickButtonsOther = {
        type = "group",
        name = "Quick Navigation",
        inline = true,
        order = 0.1,
        hidden = function() return UCB:IsPlayer(unit) end,
        args = createQuickButtons(unit, {"channel", "mirror_inverse", "interruptedEffect", "cancelledEffect"}, createNames(), createPaths(), 0.8),
    }

    if UCB:IsPlayer(unit) then
        args.spellQueGrp = OtherFeatures_API:BuildSpellQueueOptions(unit, cfg)
        args.latencyGrp = OtherFeatures_API:BuildLatencyOptions(unit, cfg)
    else
        args.spellQueGrp = nil
        args.latencyGrp = nil
    end

    args.channelTickGrp = OtherFeatures_API:BuildChannelTickOptions(unit, cfg)

    args.inversMirrorGrp = OtherFeatures_API:BuildInverseMirrorOptions(unit, cfg)

    args.kickedGrp = OtherFeatures_API:BuildInterruptedOptions(unit, cfg)

    args.cancelledGrp = OtherFeatures_API:BuildCancelledOptions(unit, cfg)

    OtherFeatures_API:BuildPermanentBackgroundOptions(unit, cfg, args)

    if UCB:IsPlayer(unit) then
        args.cancelledGrp.args.filterGroup = UIStructures:BuildAbilityFilterSectionPlayer(cfg.cancelledEffect.blacklistWhitelist, unit, true, "Blacklist/Whitelist cancelled spells", 4)
    else
        args.cancelledGrp.args.filterGroup = nil
    end
end


-- Public builder
function Opt.BuildGeneralSettingsOtherFeaturesArgs(unit, opts)
    opts = opts or {}
    local args = {}

    BuildOtherArgs(args, unit)

    return args
end
