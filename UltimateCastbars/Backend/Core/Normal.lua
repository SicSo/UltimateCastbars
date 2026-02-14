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
    if Preview_API.previewActive and Preview_API.previewActive[unit] then
        Preview_API:HidePreviewCastBar(unit)
    end

    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]
    CASTBAR_API:StopPrevCast(unit, bar, castGUID, spellID)

    -- Update internal vars with spellInfo
    local icon_texture = tags:updateVars(unit, castType, spellID)
    local vars = tags.var[unit]

    -- Failsafe
    if not vars.durationObject then
        return
    end

    -- Set text, icon, queue window
    local textCFG = cfg.text
    tags:setTextSameState(textCFG, bar, "semiDynamic", unit, castType, false)
    tags:setTextSameState(textCFG, bar, "dynamic", unit, castType, true)
    
    bar.icon:SetTexture(icon_texture)

    if unit == "player" then
        CASTBAR_API:AssignQueueWindow(castType)
    end

    CASTBAR_API:SemiColourUpdate(unit, bar)
    bar.status:SetMinMaxValues(0, vars.dTime)
    local inverted = cfg.otherFeatures.invertBar[castType]
    if resumeCast then
        if inverted then
            bar.status:SetValue(vars.durationObject:GetRemainingDuration())
        else
            bar.status:SetValue(vars.durationObject:GetElapsedDuration())
        end
    else
        if inverted then
            bar.status:SetValue(vars.dTime)
        else
            bar.status:SetValue(0)
        end
    end
    bar._ucbUnit = unit
    bar._ucbCfg = cfg
    bar._ucbCastType = castType
    bar._ucbVars = vars
    bar:SetScript("OnUpdate", CastbarOnUpdate)
    bar.group:Show()
    bar._prevType = castType
    bar.castActive = true
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
        bar._ucbUnit, bar._ucbCfg, bar._ucbCastType, bar._ucbVars = nil, nil, nil, nil
     end
end
