local ADDON_NAME, UCB = ...

UCB.CASTBAR_API = UCB.CASTBAR_API or {}

local CASTBAR_API = UCB.CASTBAR_API

function CASTBAR_API:OnUnitChange(unit)
    if unit == "player" then return end
    local bar = UCB.castBar[unit]
    if not bar then return end
    local resumeCast = true

    -- Hide any previous casts
    CASTBAR_API:StopPrevCast(unit, bar, nil, nil)
    
    -- Look for current casts
    local name, _, _, _, _, _, _, _ = UnitCastingInfo(unit)
	if(name) then
		CASTBAR_API:OnUnitSpellcastStart(unit, nil, nil, resumeCast)
	else
		local name, _, _, _, _, _, _, _, isEmpowered, _, _ = UnitChannelInfo(unit)
        if (name) then
            if(isEmpowered) then
                CASTBAR_API:OnUnitSpellcastEmpowerStart(unit, nil, nil, resumeCast)
            else
                CASTBAR_API:OnUnitSpellcastChannelStart(unit, nil, nil, resumeCast)
            end
        end
	end
end