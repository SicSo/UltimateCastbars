local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local OtherFeatures_API = UCB.OtherFeatures_API



function OtherFeatures_API:getSpellQueCVAR()
    local val = tonumber(C_CVar.GetCVar("SpellQueueWindow"))
    return tonumber(val)
end
function OtherFeatures_API:setSpellQueCVAR(val)
    C_CVar.SetCVar("SpellQueueWindow", tostring(val))
end



