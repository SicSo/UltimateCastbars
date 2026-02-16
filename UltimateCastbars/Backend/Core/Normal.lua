local ADDON_NAME, UCB = ...

UCB.CFG_API  = UCB.CFG_API  or {}
UCB.tags     = UCB.tags     or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.Preview_API = UCB.Preview_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local castType = "normal"

local function CastbarOnUpdate(bar, elapsed)
    local unit = bar._ucbUnit
    local cfg  = bar._ucbCfg
    local castType = bar._ucbCastType
    local vars = bar._ucbVars
    local remainig = UCB.CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, castType, vars)
    if unit == "player" and remainig < -0.001 then
        CASTBAR_API:OnUnitSpellcastStop(unit)
    end
    --if unit ~= "player" and vars.durationObject:IsZero() then
    --    print("Here")
    --    CASTBAR_API:OnUnitSpellcastStop(unit)
    --end
end

function CASTBAR_API:OnUnitSpellcastStart(unit, castGUID, spellID, resumeCast)
     local cfg, bar, vars = CASTBAR_API:CastSetup(unit, castGUID, spellID, resumeCast, castType)
    -- Set colours
    CASTBAR_API:SemiColourUpdate(unit, bar)
    CASTBAR_API:CastOnUpdateSetup(bar, unit, cfg, vars, castType, spellID, CastbarOnUpdate)
end

function CASTBAR_API:OnUnitSpellcastStop(unit, castGUID, spellID)
    -- Only hide if not casting 
    local nameCast = UnitCastingInfo(unit)
    local nameChannel = UnitChannelInfo(unit)
    if nameCast or nameChannel then return end

    local bar = UCB.castBar[unit]
    if bar and bar.castActive then
        bar.group:Hide()
        bar:SetScript("OnUpdate", nil)
        bar.castActive = false
        bar._prevType = nil
        bar._ucbUnit, bar._ucbCfg, bar._ucbCastType, bar._ucbVars,  bar._ucbSpellID = nil, nil, nil, nil, nil
     end
end
