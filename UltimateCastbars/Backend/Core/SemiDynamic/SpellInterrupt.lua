local ADDON_NAME, UCB = ...

UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.tags     = UCB.tags     or {}
UCB.GeneralCore_Helpers = UCB.GeneralCore_Helpers or {}
UCB.Latency = UCB.Latency or {}

local CASTBAR_API = UCB.CASTBAR_API
local tags = UCB.tags
local GeneralHelpers = UCB.GeneralCore_Helpers
local Latency = UCB.Latency


local function DesignBar(status, frame_status, cfg, castType, cancelled)
    local currentCFG
    if cancelled then
        currentCFG = cfg.otherFeatures.cancelledEffect
     else
        currentCFG = cfg.otherFeatures.interruptedEffect
    end
    local colour = currentCFG.frameColour[castType]
    frame_status:SetStatusBarColor(colour.r, colour.g, colour.b, colour.a)
    if currentCFG.useSameTextureAsMain[castType] then
        frame_status:SetStatusBarTexture(status:GetStatusBarTexture():GetTextureFileID())
    else
        frame_status:SetStatusBarTexture(currentCFG.frameTexture[castType])
    end
    return currentCFG.displayTimer[castType]
end

function CASTBAR_API:StopFrameTimer(bar, type)
    if not bar.flags.cancelledOrInterrupted then return end
    if not bar then return end

    local frame = bar.frames[type]
    if not frame then return end

    tags:hideTextFromEffect(bar, type)

    -- cancel pending hide timer if any
    if frame.hideTimer then
        frame.hideTimer:Cancel()
        frame.hideTimer = nil
    end

    bar.frames.overlay:Show()
    bar.frames.underlay:Show()

    frame:Hide()
    bar.group:Hide()
end

function CASTBAR_API:ShowFrameTimer(bar, unit, type, duration, alpha)
  bar.flags.cancelledOrInterrupted = true
  local frame = bar.frames[type]

    if type == "cancelled" then
        bar.gate_effects:SetAlpha(alpha)
    end

    frame:Show()
    bar.group:Show()


  -- if you show it again, cancel any previous hide timer
  if frame.hideTimer then
    frame.hideTimer:Cancel()
    frame.hideTimer = nil
  end

  bar.status:SetValue(0)
  bar.frames.unInterrupted.status:SetValue(0)
  bar.frames.untilKick.status:SetValue(0)

  bar.frames.overlay:Hide()
  bar.frames.underlay:Hide()

  local cfg = UCB.GetValueConfig(unit)
  CASTBAR_API:HideCastbar(bar, unit, tags.var[unit], cfg)

    -- Hide Background
    local otherFeaturesCFG = cfg.otherFeatures
    if otherFeaturesCFG.permanentBackgrodund.enable and otherFeaturesCFG.permanentBackgrodund.hideWhenCasting then
        bar.background_frame:Hide()
    end

  --UCB.LA:Animate(bar.group, "headShake", {duration = 1.0})

  frame.hideTimer = C_Timer.NewTimer(duration, function()
    frame.hideTimer = nil
    frame:Hide()
    bar.group:Hide()
    local otherFeaturesCFG = cfg.otherFeatures
    if otherFeaturesCFG.permanentBackgrodund.enable and otherFeaturesCFG.permanentBackgrodund.hideWhenCasting then
        bar.background_frame:Show()
    end
  end)
end


local function CancelledCast(unit, castType, castGUID, spellID, interruptedBy, castBarID, complete)
    local cfg = UCB.GetValueConfig(unit)
    local cfgCancelled = cfg.otherFeatures.cancelledEffect

    -- Spell filter
    if UCB:IsPlayer(unit) then 
        if not CASTBAR_API:SpellFilter(spellID, cfgCancelled) then
            return 
        end
    end

    local bar = UCB.castBar[unit]
    local frame = bar.frames.cancelled

    local alpha
    if castType == "empowered" then
        alpha = GeneralHelpers:NotSecretTo0_1(complete)
    elseif castType == "channel" then
        local channelLatency = -1
        if  UCB:IsPlayer(unit) and Latency.latency then
            channelLatency = Latency.latency
        end
        if cfgCancelled.useManualChannelError then
            channelLatency = cfgCancelled.channelError/1000
        end

        local durationObject = tags.var[unit].durationObject
        local curve = C_CurveUtil.CreateCurve()
        curve:AddPoint(0.0, 0.0)

        if channelLatency ~= -1 then
            curve:AddPoint(channelLatency,  0)
            curve:AddPoint(channelLatency + 0.0000001,  1.0)
        else
            curve:AddPoint(0.0000001,  1.0)
        end
        alpha = durationObject:EvaluateRemainingDuration(curve)
    else
        alpha = 1
        if UCB:IsPlayer(unit) and Latency.latency then
            local durationObject = tags.var[unit].durationObject
            if durationObject:GetRemainingDuration() <= Latency.latency then
                alpha = 0
            end
        end
    end
    local timer = DesignBar(bar.status, frame.status, cfg, castType, true)
    tags:ShowEffectTags(bar, "cancelled", castType, unit)
    CASTBAR_API:ShowFrameTimer(bar, unit, "cancelled", timer, alpha)
end

local function InterruptedCast(unit, castType, castGUID, spellID, interruptedBy, castBarID)
    local interruptedByUnit = UnitNameFromGUID(interruptedBy)
    local _, class = GetPlayerInfoByGUID(interruptedBy)
    local colour = {r = 1, g = 1, b = 1, a=0}
    if class ~= nil then
        colour = C_ClassColor.GetClassColor(class)
    end
    tags.var[unit].kName = interruptedByUnit
    tags.var[unit].kColour = colour
    local bar = UCB.castBar[unit]
    local frame = bar.frames.interrupted
    local timer = DesignBar(bar.status, frame.status, UCB.GetValueConfig(unit), castType, false)
    tags:ShowEffectTags(bar, "interrupted", castType, unit)
    CASTBAR_API:ShowFrameTimer(bar, unit, "interrupted", timer)
end


function CASTBAR_API:OnCastInterrupt(unit, castGUID, spellID, interruptedBy, castBarID)
    if not castBarID then return end
    local show = CASTBAR_API:OnUnitSpellcastStop(unit, castGUID, spellID, castBarID)
    if not show then return end
    local cfg = UCB.GetValueConfig(unit)
    local castType = "normal"
    if (interruptedBy) then
        if cfg.otherFeatures.interruptedEffect.enableEffect[castType] then
            InterruptedCast(unit, castType, castGUID, spellID, interruptedBy, castBarID)
        end
    else
        if cfg.otherFeatures.cancelledEffect.enableEffect[castType] then
            CancelledCast(unit, castType, castGUID, spellID, interruptedBy, castBarID)
        end
    end
end

function CASTBAR_API:OnChannelInterrupt(unit, castGUID, spellID, interruptedBy, castBarID)
    if not castBarID then return end
    local show = CASTBAR_API:OnUnitSpellcastChannelStop(unit, castGUID, spellID, castBarID)
    if not show then return end
    local cfg = UCB.GetValueConfig(unit)
    local castType = "channel"
    if (interruptedBy) then
        if cfg.otherFeatures.interruptedEffect.enableEffect[castType] then
            InterruptedCast(unit, castType, castGUID, spellID, interruptedBy, castBarID)
        end
    else
        if cfg.otherFeatures.cancelledEffect.enableEffect[castType] then
            CancelledCast(unit, castType, castGUID, spellID, interruptedBy, castBarID)
        end
    end
end

function CASTBAR_API:OnEmpowerInterrupt(unit, castGUID, spellID, complete, interruptedBy, castBarID)
    if not castBarID then return end
    local show = CASTBAR_API:OnUnitSpellcastEmpowerStop(unit, castGUID, spellID, castBarID)
    if not show then return end
    local cfg = UCB.GetValueConfig(unit)
    local castType = "empowered"
    if (interruptedBy) then
        if cfg.otherFeatures.interruptedEffect.enableEffect[castType] then
            InterruptedCast(unit, castType, castGUID, spellID, interruptedBy, castBarID)
        end
    else
        if cfg.otherFeatures.cancelledEffect.enableEffect[castType] then
            CancelledCast(unit, castType, castGUID, spellID, interruptedBy, castBarID, complete)
        end
    end
end


