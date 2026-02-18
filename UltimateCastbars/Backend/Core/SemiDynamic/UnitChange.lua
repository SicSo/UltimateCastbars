local ADDON_NAME, UCB = ...

UCB.CASTBAR_API = UCB.CASTBAR_API or {}

local CASTBAR_API = UCB.CASTBAR_API

function CASTBAR_API:OnUnitChange(unit)
    if unit == "player" then return end
    local bar = UCB.castBar[unit]
    if not bar then return end
    local resumeCast = true

    -- Hide any previous casts
    if bar.flags.prevType ~= nil and bar.flags.castActive then
        if bar.flags.prevType == "normal" then
            CASTBAR_API:OnUnitSpellcastStop(unit)
        elseif bar.flags.prevType == "channel" then
            CASTBAR_API:OnUnitSpellcastChannelStop(unit)
        elseif bar.flags.prevType == "empowered" then
            CASTBAR_API:OnUnitSpellcastEmpowerStop(unit)
        end
    end
    
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