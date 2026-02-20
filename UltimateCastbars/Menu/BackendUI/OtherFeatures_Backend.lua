local _, UCB = ...

UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}

local OtherFeatures_API = UCB.OtherFeatures_API

function OtherFeatures_API:getSpellQueCVAR()
    local val = tonumber(C_CVar.GetCVar("SpellQueueWindow"))
    return tonumber(val)
end
function OtherFeatures_API:setSpellQueCVAR(val)
    C_CVar.SetCVar("SpellQueueWindow", tostring(val))
end



