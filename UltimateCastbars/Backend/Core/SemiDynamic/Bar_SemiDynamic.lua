local ADDON_NAME, UCB = ...

UCB.CFG_API  = UCB.CFG_API  or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.tags     = UCB.tags     or {}
UCB.Preview_API = UCB.Preview_API or {}
UCB.GeneralCore_Helpers = UCB.GeneralCore_Helpers or {}

local CFG_API = UCB.CFG_API
local CASTBAR_API = UCB.CASTBAR_API
local tags = UCB.tags
local BarUpdate_API = UCB.BarUpdate_API
local Preview_API = UCB.Preview_API
local GeneralHelpers = UCB.GeneralCore_Helpers


-- Tries to stop previous casts
local function StopPrevCast(unit, bar, castGUID, spellID)
    if bar.activeCast then
        if bar.flags.prevType == "normal" then
            CASTBAR_API:OnUnitSpellcastStop(unit, castGUID, spellID)
        elseif bar.flags.prevType == "channel" then
            CASTBAR_API:OnUnitSpellcastChannelStop(unit, castGUID, spellID)
        elseif bar.flags.prevType == "empowered" then
            CASTBAR_API:OnUnitSpellcastEmpowerStop(unit, castGUID, spellID)
        end
    end
end

local function InitCastbarVal(status, castType, resumeCast, vars, cfg)
    local minVal = 0
    local maxVal = vars.dTime
    -- Resume sets value to current point
    if resumeCast then
        minVal = vars.durationObject:GetElapsedDuration()
        maxVal = vars.durationObject:GetRemainingDuration()
    end
    -- Channels are inverted, so flip min and max
    if castType == "channel" then
        minVal, maxVal = maxVal, minVal
    end

    -- Set initial value based on invert
    local inverted = cfg.invertBar[castType]
    if inverted then
        status:SetValue(maxVal)
    else
        status:SetValue(minVal)
    end
end

local function Alpha_ShowOnlyWhenKickReady(notInterruptibleSecretBool, kickReadySecretBool)
    if not C_CurveUtil then
        return 1 -- safest fallback if curve util isn't available
    end
    -- kickReady=true -> 1, false -> 0
    local aKick = C_CurveUtil.EvaluateColorValueFromBoolean(kickReadySecretBool, 1, 0)
    -- notInterruptible=true -> 0, false -> aKick
    return C_CurveUtil.EvaluateColorValueFromBoolean(notInterruptibleSecretBool, 0, aKick)
end

local function HideCastbar(bar, vars, cfg)
    local notIntr = vars and vars.nIntr  -- secret boolean
    local a = 1
    if C_CurveUtil then
        a = C_CurveUtil.EvaluateColorValueFromBoolean(notIntr, 0, 1)
    end
    if cfg.uninterruptible.disableBarUnInt then
        bar.group:SetAlpha(a)
    end

    local spellID, kickDur = GeneralHelpers:GetKickTimer()
    if not spellID or not kickDur then
        return
    end
    local kickReady = kickDur:IsZero()   -- secret boolean
    a = Alpha_ShowOnlyWhenKickReady(notIntr, kickReady)
    if cfg.uninterruptible.disableBarUnKick then
        bar.group:SetAlpha(a)
    end
end


function CASTBAR_API:MirrorBar(cfg, bar, castType)
    local mirror = cfg.otherFeatures.mirrorBar[castType]
    bar.flags.mirrored = mirror

    -- Show/hide mirror frame
    bar.mirrorStatus:SetShown(mirror)
    bar.mirror_frames.unInterrupted:SetShown(mirror and cfg.uninterruptible.showUninterruptible and cfg.uninterruptible.showUninterruptibleFill)
    bar.mirror_frames.untilKick:SetShown(mirror and cfg.uninterruptible.showUntilKickTick)

    -- Show/Hide Status if mirrored
    bar.status:SetAlphaFromBoolean(not mirror)
    bar.frames.unInterrupted.status:SetAlphaFromBoolean(not mirror)
    bar.frames.untilKick.status:SetAlphaFromBoolean(not mirror)
end

function CASTBAR_API:UninterruptibleCast(bar, bar_status, vars)
    local uint = vars.nIntr
    local frame = bar.frames.unInterrupted
    local iconFrame = bar.unintIconFrame
    local mirrorFrame = bar.mirror_frames.unInterrupted
    local status = frame.status
    mirrorFrame:SetAlphaFromBoolean(uint)
    frame:SetAlphaFromBoolean(uint)
    if status:IsShown() then
        bar_status:SetAlpha(GeneralHelpers:NotSecretTo0_1(uint))
    end
    iconFrame:SetAlphaFromBoolean(uint)
    status:SetMinMaxValues(bar_status:GetMinMaxValues())
    status:SetValue(bar_status:GetValue())
end

function CASTBAR_API:AssignQueueWindow(typeCast)
    local unit  = "player"
    local bar = UCB.castBar[unit]
    if not bar.queueWindowOverlay then return end

    local bigCFG = CFG_API.GetValueConfig(unit)
    local cfg = bigCFG.otherFeatures
    local queueWindowOverlay = bar.queueWindowOverlay
    local overlayFrame = bar.frames.overlay
    local inverted = cfg.invertBar[typeCast]
    local mirror = cfg.mirrorBar[typeCast]

    local switch = (inverted or mirror) and not (inverted and mirror)  -- if either is true, but not both

    if cfg.showQueueWindow[typeCast] then
        local queWindow = BarUpdate_API.queueWindow / 1000
        local px = bigCFG.general.actualBarWidth * (queWindow / tags.var[unit].dTime)
        queueWindowOverlay:SetWidth(px)
        queueWindowOverlay:ClearAllPoints()
        if (not switch and typeCast ~= "channel") or (typeCast == "channel" and switch) then
            queueWindowOverlay:SetPoint("TOPRIGHT", overlayFrame, "TOPRIGHT", 0, 0)
            queueWindowOverlay:SetPoint("BOTTOMRIGHT", overlayFrame, "BOTTOMRIGHT", 0, 0)
        else
            queueWindowOverlay:SetPoint("TOPLEFT", overlayFrame, "TOPLEFT", 0, 0)
            queueWindowOverlay:SetPoint("BOTTOMLEFT", overlayFrame, "BOTTOMLEFT", 0, 0)
        end
        queueWindowOverlay:Show()
    else
        queueWindowOverlay:Hide()
    end
end

function CASTBAR_API:SemiColourUpdate(unit, bar)
    local tex = bar.status:GetStatusBarTexture()
    local mtex = bar.mirrorStatus.tex
    local doMirror = bar.flags.mirrored
    local colourMode = bar._colourMode
    local canGradient = tex and tex.SetGradient
    local status = bar.status

    if unit == "player" then 
        if colourMode == "single" then
            local r, g, b, a = bar._r, bar._g, bar._b, bar._a
            local col1 = bar._c1
            status:SetStatusBarColor(r, g, b, a)
            if doMirror then mtex:SetVertexColor(r, g, b, a) end
            if canGradient then
                tex:SetGradient("HORIZONTAL", col1, col1)
                if doMirror then mtex:SetGradient("HORIZONTAL", col1, col1) end
            end
        elseif colourMode == "gradient" then
            local r1, g1, b1, a1 = bar._r1, bar._g1, bar._b1, bar._a1
            local col1 = bar._c1
            local col2 = bar._c2
            status:SetStatusBarColor(r1, g1, b1, a1)
            if canGradient then
                tex:SetGradient("HORIZONTAL", col1, col2)
                if doMirror then mtex:SetGradient("HORIZONTAL", col2, col1) end
            end
        end
    else
        if colourMode == "single" then
            if bar._colourType == "custom" then
                local r, g, b, a = bar._r, bar._g, bar._b, bar._a
                local col1 = bar._c1
                status:SetStatusBarColor(r, g, b, a)
                if doMirror then mtex:SetVertexColor(r, g, b, a) end
                if canGradient then
                    tex:SetGradient("HORIZONTAL", col1, col1)
                    if doMirror then mtex:SetGradient("HORIZONTAL", col1, col1) end
                end
            else
                local r, g, b, a, col1, RGBA
                if UnitIsPlayer(unit) then
                    local _, classFile = UnitClass(unit)
                    local classColourVal = UCB.UIOptions.classColoursList[classFile]
                    RGBA = classColourVal.RGBA
                    col1 = classColourVal.COL
                else
                    local defaultEnemyColour = bar._enemyColour
                    RGBA = defaultEnemyColour.RGBA
                    col1 = defaultEnemyColour.COL
                end
                r, g, b, a = RGBA.r, RGBA.g, RGBA.b ,RGBA.a
                status:SetStatusBarColor(r, g, b, a)
                if doMirror then mtex:SetVertexColor(r, g, b, a) end
                if canGradient then
                    tex:SetGradient("HORIZONTAL", col1, col1)
                    if doMirror then mtex:SetGradient("HORIZONTAL", col1, col1) end
                end
            end
        elseif colourMode == "gradient" then
            local r1, g1, b1, a1 = bar._r1, bar._g1, bar._b1, bar._a1
            local col1 = bar._c1
            local col2 = bar._c2
            status:SetStatusBarColor(r1, g1, b1, a1)
            if doMirror then mtex:SetVertexColor(r1, g1, b1, a1) end
            if canGradient then
                tex:SetGradient("HORIZONTAL", col1, col2)
                if doMirror then mtex:SetGradient("HORIZONTAL", col2, col1) end
            end
        end
    end
end

function CASTBAR_API:InterruptibleTick(bar, bar_status, vars, cfg, castType)
    local unIntCFG = cfg.uninterruptible
    local otherCFG = cfg.otherFeatures

    if not (unIntCFG and unIntCFG.showKickTick) then
        bar.interruptMarkerPoint:Hide()
        bar.interruptMarker:Hide()
        bar.interruptPositioner:Hide()
        bar.frames.untilKick:Hide()
        return
    end

    local castDuration = vars and vars.durationObject
    if not castDuration then
        bar.interruptMarkerPoint:Hide()
        bar.interruptMarker:Hide()
        bar.interruptPositioner:Hide()
        bar.frames.untilKick:Hide()
        return
    end

    local spellID, kickDur = GeneralHelpers:GetKickTimer()
    if not spellID or not kickDur then
        bar.interruptMarkerPoint:Hide()
        bar.interruptMarker:Hide()
        bar.interruptPositioner:Hide()
        bar.frames.untilKick:Hide()
        return
    end

    local notIntr   = vars and vars.nIntr
    local kickReady = kickDur:IsZero()
    local alpha = GeneralHelpers:KickAlpha(notIntr, kickReady, false)

    local minVal, maxVal = bar_status:GetMinMaxValues()
    bar.kickTickFrozen = kickDur:GetRemainingDuration()

    bar.interruptMarker:SetMinMaxValues(minVal, maxVal)
    bar.interruptMarker:SetValue(bar.kickTickFrozen)

    local inverted = otherCFG.invertBar[castType]
    local mirrored = otherCFG.mirrorBar[castType]
    local switch = (inverted or mirrored) and not (inverted and mirrored) -- XOR

    -- UNTIL-KICK BAR: moves like cast, but only visible up to frozen kick point
    local frame = bar.frames.untilKick
    local mirrorFrame = bar.mirror_frames.untilKick
    if unIntCFG.showUntilKickTick then
        frame.status:SetMinMaxValues(minVal, maxVal)
        frame.status:SetValue(bar_status:GetValue())
        --kick_frame.status:SetReverseFill(switch and true or false)
        frame.status:Show()
        mirrorFrame:Show()
    else
        frame.status:Hide()
        mirrorFrame:Hide()
    end
    frame:SetAlpha(alpha)
    mirrorFrame:SetAlpha(alpha)

    if unIntCFG.showUntilKickTickBackground then
        frame.bg:SetMinMaxValues(minVal, maxVal)
        frame.bg:SetValue(bar.kickTickFrozen)
        frame.bg:Show()
    else
        frame.bg:Hide()
    end
    frame.bg:SetAlpha(alpha)

    bar.interruptMarker:SetOrientation("HORIZONTAL")
    bar.interruptMarker:SetRotatesTexture(false)

    local markerTex = bar.interruptMarker:GetStatusBarTexture()

    bar.interruptMarkerPoint:ClearAllPoints()
    if switch then
        -- RIGHT -> LEFT
        frame.bg:SetReverseFill(true)
        bar.interruptMarker:SetReverseFill(true)
        bar.interruptMarkerPoint:SetPoint("RIGHT", markerTex, "LEFT", 0, 0)
    else
        -- LEFT -> RIGHT
        frame.bg:SetReverseFill(false)
        bar.interruptMarker:SetReverseFill(false)
        bar.interruptMarkerPoint:SetPoint("LEFT", markerTex, "RIGHT", 0, 0)
    end

    bar.interruptMarker:Show()
    bar.interruptMarkerPoint:Show()
    bar.interruptPositioner:Hide()

    bar.interruptMarker:SetAlpha(alpha)
    bar.interruptMarkerPoint:SetAlpha(alpha)
end


----------------------------------------------------------------- CASTBAR UPDATE FUNCTIONS -----------------------------------------------------------------
function CASTBAR_API:CastSetup(unit, castGUID, spellID, resumeCast, castType)
    if Preview_API.previewActive and Preview_API.previewActive[unit] then
        Preview_API:HidePreviewCastBar(unit)
    end

    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]
    StopPrevCast(unit, bar, castGUID, spellID)

    -- Update internal vars with spellInfo
    local icon_texture = tags:updateVars(unit, castType, spellID, cfg)
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

    local bar_status = bar.status
    bar_status:SetMinMaxValues(0, vars.dTime)
    local otherCFG = cfg.otherFeatures
    CASTBAR_API:MirrorBar(cfg, bar, castType)
    InitCastbarVal(bar_status, castType, resumeCast, vars, otherCFG)

    CASTBAR_API:UninterruptibleCast(bar, bar_status, vars)

    CASTBAR_API:InterruptibleTick(bar, bar_status, vars, cfg, castType)

    return cfg, bar, vars
end

function CASTBAR_API:CastOnUpdateSetup(bar, unit, cfg, vars, castType, spellID, CastbarOnUpdate)
    bar.group:SetAlpha(1)
    bar._ucbUnit = unit
    bar._ucbCfg = cfg
    bar._ucbCastType = castType
    bar._ucbVars = vars
    bar._ucbSpellID = spellID
    bar:SetScript("OnUpdate", CastbarOnUpdate)
    bar.group:Show()
    bar.flags.prevType = castType
    bar.flags.castActive = true

    HideCastbar(bar, vars, cfg)
end


function CASTBAR_API:CastUpdate(unit, castGUID, spellID, castType)
    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]

    local icon_texture = tags:updateVars(unit, castType, spellID, cfg)
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

    bar.status:SetMinMaxValues(0, vars.dTime)
    local otherCFG = cfg.otherFeatures
    CASTBAR_API:MirrorBar(cfg, bar, castType)
    
    -- Set value based on invert and cast type (channel or not)
    local minVal = 0
    local maxVal = vars.dTime
    if castType == "channel" then
        minVal, maxVal = maxVal, minVal
    end
    local inverted = otherCFG.invertBar[castType]
    if inverted then
        bar.status:SetValue(maxVal)
    else
        bar.status:SetValue(minVal)
    end
end