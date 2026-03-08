local ADDON_NAME, UCB = ...

UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.Latency = UCB.Latency or {}

local CASTBAR_API = UCB.CASTBAR_API
local Latency = UCB.Latency
local castType = "normal"

local function CastbarOnUpdate(bar, elapsed)
    local unit = bar._ucbUnit
    local cfg  = bar._ucbCfg
    local castType = bar._ucbCastType
    local vars = bar._ucbVars
    local remainig = UCB.CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, castType, vars)
    if UCB:IsPlayer(unit) and remainig < -0.001 then
        CASTBAR_API:OnUnitSpellcastStop(unit)
    end
end

---------------------------------------------------- MAIN -------------------------------------------------
function CASTBAR_API:OnUnitSpellcastStart(unit, castGUID, spellID, castBarID, resumeCast)
    if not UCB.usePetForPlayer and UCB:IsPlayer(unit, true) and Latency.sendTime then Latency.latency = GetTime() - Latency.sendTime else Latency.latency = nil end
    local show, cfg, bar, vars = CASTBAR_API:CastSetup(unit, castGUID, spellID, resumeCast, castType, Latency.latency)
    if not show then return end
    -- Set colours
    CASTBAR_API:SemiColourUpdate(unit, bar)
    CASTBAR_API:CastOnUpdateSetup(bar, unit, cfg, vars, castType, spellID, CastbarOnUpdate)
end

function CASTBAR_API:OnUnitSpellcastStop(unit, castGUID, spellID, castBarID)
    -- Only hide if not casting 
    local nameCast = UnitCastingInfo(unit)
    local nameChannel = UnitChannelInfo(unit)
    --if nameCast or nameChannel then return end

    -- Spell filter
    local cfg = UCB.GetValueConfig(unit)
    if not CASTBAR_API:SpellFilterClass(unit, spellID, cfg) then
        return false
    end

    local bar = UCB.castBar[unit]
    if bar and bar.flags.castActive then
        bar.group:Hide()
        bar:SetScript("OnUpdate", nil)
        bar.flags.castActive = false
        bar.flags.prevType = nil
        bar.current_spellID = nil
        bar._ucbUnit, bar._ucbCfg, bar._ucbCastType, bar._ucbVars,  bar._ucbSpellID = nil, nil, nil, nil, nil
        if bar.effects.spark then bar.effects.spark:Hide() end
        return true
     end
    return false
end