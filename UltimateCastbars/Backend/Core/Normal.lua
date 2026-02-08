local ADDON_NAME, UCB = ...

UCB.CFG_API  = UCB.CFG_API  or {}
UCB.tags     = UCB.tags     or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}


local CFG_API = UCB.CFG_API
local tags = UCB.tags
local CASTBAR_API = UCB.CASTBAR_API


local castType = "normal"

function CASTBAR_API:OnUnitSpellcastStart(unit, castGUID, spellID)
    if UCB.Preview_API.previewActive and UCB.Preview_API.previewActive[unit] then
        UCB.Preview_API:HidePreviewCastBar(unit)
    end

    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]

    -- Update internal vars with spellInfo
    local icon_texture = tags:updateVars(unit, castType)
    -- Failsafe
    if not tags.var[unit].sName or not tags.var[unit].sTime or not tags.var[unit].eTime then
        if bar then bar:Hide() end
        return
    end

    -- Set text, icon, queue window
    UCB.tags:setTextSameState(cfg.text, bar, "semiDynamic", unit, castType, false)
    UCB.tags:setTextSameState(cfg.text, bar, "dynamic", unit, castType, true)
    
    bar.icon:SetTexture(icon_texture)
    UCB.CASTBAR_API:AssignQueueWindow(unit, castType)

    CASTBAR_API:SemiColourUpdate(bar)
    bar.status:SetMinMaxValues(0, math.max(tags.var[unit].dTime, 0.001))
    bar:SetScript("OnUpdate", function(bar, elapsed) UCB.CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, castType) end)
    bar.group:Show()
end

function CASTBAR_API:OnUnitSpellcastStop(unit, castGUID, spellID)
    -- Only hide if not casting 
    local nameCast = UnitCastingInfo(unit)
    local nameChannel = UnitChannelInfo(unit)
    if nameCast or nameChannel then return end

    UCB.castBar[unit].group:Hide()
    UCB.castBar[unit]:SetScript("OnUpdate", nil)
end
