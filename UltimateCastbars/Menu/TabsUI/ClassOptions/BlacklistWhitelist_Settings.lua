local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.UIStructures = UCB.UIStructures or {}

local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local UIStructures = UCB.UIStructures


-- Registry: classToken -> function(cfgGetter) -> argsTable
Opt.ClassExtraBuilders = Opt.ClassExtraBuilders or {}

function Opt:BuildAbilityFilterSectionPlayer(args, unit, class)
    local bigCFG = GetCFG(unit)
    local cfg = bigCFG.CLASSES[class].blacklistWhitelist

    -- defaults (in case section is built before table)
    if cfg.enableAbilityFilter == nil then cfg.enableAbilityFilter = false end
    if cfg.blackList == nil then cfg.blackList = true end
    cfg.blackListSpells = cfg.blackListSpells or {}
    cfg.whiteListSpells = cfg.whiteListSpells or {}

    args.abilityFilterSection = UIStructures:BuildAbilityFilterSectionPlayer(cfg, unit, true, "Blacklist/Whitelist Spells", 10)
end

