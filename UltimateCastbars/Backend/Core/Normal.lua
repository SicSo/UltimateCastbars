local ADDON_NAME, UCB = ...

UCB.CFG_API  = UCB.CFG_API  or {}
UCB.tags     = UCB.tags     or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.Preview_API = UCB.Preview_API or {}

local CFG_API = UCB.CFG_API
local tags = UCB.tags
local CASTBAR_API = UCB.CASTBAR_API
local Preview_API = UCB.Preview_API

local castType = "normal"

local function CastbarOnUpdate(bar, elapsed)
    local unit = bar._ucbUnit
    local cfg  = bar._ucbCfg
    local castType = bar._ucbCastType
    local remainig = UCB.CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, castType)
    if remainig < -0.01 then
        CASTBAR_API:OnUnitSpellcastStop(unit)
    end
end

function CASTBAR_API:OnUnitSpellcastStart(unit, castGUID, spellID)
    if Preview_API.previewActive and Preview_API.previewActive[unit] then
        Preview_API:HidePreviewCastBar(unit)
    end

    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]

    -- Update internal vars with spellInfo
    local icon_texture = tags:updateVars(unit, castType)
    local vars = tags.var[unit]

    -- Failsafe
    if not vars.sName or not vars.sTime or not vars.eTime then
        return
    end

    -- Set text, icon, queue window
    local textCFG = cfg.text
    tags:setTextSameState(textCFG, bar, "semiDynamic", unit, castType, false)
    tags:setTextSameState(textCFG, bar, "dynamic", unit, castType, true)
    
    bar.icon:SetTexture(icon_texture)
    CASTBAR_API:AssignQueueWindow(unit, castType)

    CASTBAR_API:SemiColourUpdate(bar)
    bar.status:SetMinMaxValues(0, math.max(vars.dTime, 0.001))
    local inverted = cfg.otherFeatures.invertBar[castType]
    if inverted then
        bar.status:SetValue(math.max(vars.dTime, 0.001))
    else
        bar.status:SetValue(0)
    end
    bar._ucbUnit = unit
    bar._ucbCfg = cfg
    bar._ucbCastType = castType
    bar:SetScript("OnUpdate", CastbarOnUpdate)
    bar.group:Show()
    bar.castActive = true
end

function CASTBAR_API:OnUnitSpellcastStop(unit, castGUID, spellID)
    -- Only hide if not casting 
    local nameCast = UnitCastingInfo(unit)
    local nameChannel = UnitChannelInfo(unit)
    if nameCast or nameChannel then return end

    local bar = UCB.castBar[unit]
    if bar and bar.castActive then
        bar.castActive = false
        bar.group:Hide()
        bar:SetScript("OnUpdate", nil)
        bar._ucbUnit, bar._ucbCfg, bar._ucbCastType = nil, nil, nil
     end
end
