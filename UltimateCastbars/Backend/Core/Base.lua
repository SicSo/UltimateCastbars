local ADDON_NAME, UCB = ...

UCB.CFG_API  = UCB.CFG_API  or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.tags     = UCB.tags     or {}
UCB.Preview_API = UCB.Preview_API or {}
UCB.UNINTERRUPTIBLE = UCB.UNINTERRUPTIBLE or {}

local CFG_API = UCB.CFG_API
local CASTBAR_API = UCB.CASTBAR_API
local tags = UCB.tags
local BarUpdate_API = UCB.BarUpdate_API
local Preview_API = UCB.Preview_API
local UNINTERRUPTIBLE = UCB.UNINTERRUPTIBLE

local function UpdateSequence(unit)

    BarUpdate_API:UpdateBarIcon(unit)
    BarUpdate_API:UpdateVisibility(unit)
    BarUpdate_API:UpdateColours(unit)
    BarUpdate_API:UpdateStyle(unit)
    BarUpdate_API:UpdateText(unit)
    BarUpdate_API:UpdateUninterruptable(unit)
    BarUpdate_API:UpdateUnkickable(unit)
    BarUpdate_API:UpdateOtherFeatures(unit)
    BarUpdate_API:UpdateOthers(unit)

end

local function CreateCastBar(unit)
    -- Create castbar
    local anchor = UIParent

    -- Group frame = the thing you anchor (represents bar+icon combined)
    local group = CreateFrame("Frame", ADDON_NAME .. "_" .. unit .. "CastGroup", anchor)
    UCB.castBarGroup[unit] = group

    -- Bar frame lives inside group (keep your name)
    local bar = CreateFrame("Frame", ADDON_NAME .. "_" .. unit:sub(1,1):upper() .. unit:sub(2) .. "CastBar", group, "BackdropTemplate")
    UCB.castBar[unit] = bar
    bar.group = group  -- handy reference

    -- Status bar (fill bar)
    bar.status = CreateFrame("StatusBar", nil, bar, "BackdropTemplate")
    bar.status:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    bar.status:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)


    bar.overlayFrame = CreateFrame("Frame", nil, bar)
    bar.overlayFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    bar.overlayFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

    bar.underlayFrame = CreateFrame("Frame", nil, bar)
    bar.underlayFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    bar.underlayFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

    bar.textFrame = CreateFrame("Frame", nil, bar)
    bar.textFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    bar.textFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

    bar.mirrorFrame = CreateFrame("Frame", nil, bar)
    bar.mirrorFrame:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
    bar.mirrorFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    bar.mirrorFrame:SetWidth(0)
    bar.mirrorFrame:SetClipsChildren(true)
    bar.mirrorFrame:Hide()

    bar.unInterruptedFrame = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    bar.unInterruptedFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    bar.unInterruptedFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

    bar.unInterruptedMirrorFrame = CreateFrame("Frame", nil, bar)
    bar.unInterruptedMirrorFrame:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
    bar.unInterruptedMirrorFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    bar.unInterruptedMirrorFrame:SetWidth(0)
    bar.unInterruptedMirrorFrame:SetClipsChildren(true)
    bar.unInterruptedMirrorFrame:Hide()

    bar.untilKickFrame = CreateFrame("Frame", nil, bar)
    bar.untilKickFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    bar.untilKickFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

    bar.untilKickMirrorFrame = CreateFrame("Frame", nil, bar)
    bar.untilKickMirrorFrame:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
    bar.untilKickMirrorFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    bar.untilKickMirrorFrame:SetWidth(0)
    bar.untilKickMirrorFrame:SetClipsChildren(true)
    bar.untilKickMirrorFrame:Hide()

    bar.iconFrame = CreateFrame("Frame", nil, group, "BackdropTemplate")
    bar.icon = bar.iconFrame:CreateTexture(nil, "ARTWORK")
    bar.icon:SetAllPoints()
    bar.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

    UpdateSequence(unit)

    bar.group:Hide()
end


local function DeleteCastBar(unit)
    if UCB.castBar and UCB.castBar[unit] then
        UCB.castBar[unit].group:Hide()
        UCB.castBar[unit]:SetScript("OnUpdate", nil)
        UCB.castBar[unit] = nil
    end
end


function CASTBAR_API:AssignQueueWindow(typeCast)
    local unit  = "player"
    local bar = UCB.castBar[unit]
    if not bar.queueWindowOverlay then return end

    local bigCFG = CFG_API.GetValueConfig(unit)
    local cfg = bigCFG.otherFeatures
    local queueWindowOverlay = bar.queueWindowOverlay
    local overlayFrame = bar.overlayFrame
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


-- Castbar entry functionality
function CASTBAR_API:UpdateCastbar(unit)
    --print("Castbar update")
    if not UCB.castBar then return end
    local cfg = CFG_API.GetValueConfig(unit)
    -- Castbar should be disabled
    if cfg.enabled == false then
        if UCB.castBar[unit] ~= nil then
            DeleteCastBar(unit)
        end
    -- Castbar should be enabled
    else
        -- Castbar doesn't exist yet
        if UCB.castBar[unit] == nil then
            CreateCastBar(unit)
        -- Castbar exists, update layout
        else
            local bar = UCB.castBar[unit]
            if cfg.enabled == false then
                if bar then
                    bar:Hide()
                end
                return
            end
            UpdateSequence(unit)
        end
    end
end


function CASTBAR_API:SemiColourUpdate(unit, bar)
    local tex = bar.status:GetStatusBarTexture()
    local mtex = bar._mirrorTex
    local doMirror = bar._mirrored and mtex
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

-- Tries to stop previous casts
local function StopPrevCast(unit, bar, castGUID, spellID)
    if bar.activeCast then
        if bar._prevType == "normal" then
            CASTBAR_API:OnUnitSpellcastStop(unit, castGUID, spellID)
        elseif bar._prevType == "channel" then
            CASTBAR_API:OnUnitSpellcastChannelStop(unit, castGUID, spellID)
        elseif bar._prevType == "empowered" then
            CASTBAR_API:OnUnitSpellcastEmpowerStop(unit, castGUID, spellID)
        end
    end
end

function CASTBAR_API:MirrorBar(cfg, bar, castType)
    local mirror = cfg.otherFeatures.mirrorBar[castType]
    bar._mirrored = mirror
    bar.mirrorFrame:SetShown(bar._mirrored)
    bar.unInterruptedMirrorFrame:SetShown(bar._mirrored and cfg.uninterruptible.showUninterruptible and cfg.uninterruptible.showUninterruptibleFill)
    bar.untilKickMirrorFrame:SetShown(bar._mirrored and cfg.uninterruptible.showUntilKickTick)
    local status = bar.status and bar.status --bar.status:GetStatusBarTexture()
    local unint_status = bar.unInterruptedFrame and bar.unInterruptedFrame.status
    local untilKick_status = bar.untilKickFrame and bar.untilKickFrame.status
    if status then status:SetAlphaFromBoolean(not bar._mirrored) end
    if unint_status then unint_status:SetAlphaFromBoolean(not bar._mirrored) end
    if untilKick_status then untilKick_status:SetAlphaFromBoolean(not bar._mirrored) end
end

function CASTBAR_API:UninterruptibleCast(bar, bar_status, vars)
    local uint = vars.nIntr
    local frame = bar.unInterruptedFrame
    local mirrorFrame = bar.unInterruptedMirrorFrame
    local status = frame.status
    mirrorFrame:SetAlphaFromBoolean(uint)
    frame:SetAlphaFromBoolean(uint)
    status:SetMinMaxValues(bar_status:GetMinMaxValues())
    status:SetValue(bar_status:GetValue())
end

local function KickTickAlpha(notInterruptibleSecretBool, kickReadySecretBool)
    if C_CurveUtil then
        local alphaWhenIntr = C_CurveUtil.EvaluateColorValueFromBoolean(kickReadySecretBool, 0, 1)
        return C_CurveUtil.EvaluateColorValueFromBoolean(notInterruptibleSecretBool, 0, alphaWhenIntr)
    end
    -- fallback: just show (can't safely evaluate secrets without C_CurveUtil)
    return 1
end

function CASTBAR_API:InterruptibleTick(bar, bar_status, vars, cfg, castType)
    local status = bar
    local unIntCFG = cfg.uninterruptible
    local otherCFG = cfg.otherFeatures

    if not (unIntCFG and unIntCFG.showKickTick) then
        if status.interruptMarkerPoint then status.interruptMarkerPoint:Hide() end
        if status.interruptMarker then status.interruptMarker:Hide() end
        if status.interruptPositioner then status.interruptPositioner:Hide() end
        if status.untilKickBar then status.untilKickBar:Hide() end
        return
    end

    local castDuration = vars and vars.durationObject
    if not castDuration then
        if status.interruptMarkerPoint then status.interruptMarkerPoint:Hide() end
        status.interruptMarker:Hide()
        status.interruptPositioner:Hide()
        if status.untilKickBar then status.untilKickBar:Hide() end
        return
    end

    local spellID, kickDur = UNINTERRUPTIBLE:GetKickTimer()
    if not spellID or not kickDur then
        if status.interruptMarkerPoint then status.interruptMarkerPoint:Hide() end
        status.interruptMarker:Hide()
        status.interruptPositioner:Hide()
        if status.untilKickBar then status.untilKickBar:Hide() end
        return
    end

    local notIntr   = vars and vars.nIntr
    local kickReady = kickDur:IsZero()
    local alpha = KickTickAlpha(notIntr, kickReady)

    local minVal, maxVal = bar_status:GetMinMaxValues()
    bar.kickTickFrozen = kickDur:GetRemainingDuration()

    status.interruptMarker:SetMinMaxValues(minVal, maxVal)
    status.interruptMarker:SetValue(bar.kickTickFrozen)

    local inverted = otherCFG.invertBar[castType]
    local mirrored = otherCFG.mirrorBar[castType]
    local switch = (inverted or mirrored) and not (inverted and mirrored) -- XOR

    -- UNTIL-KICK BAR: moves like cast, but only visible up to frozen kick point
    local frame = bar.untilKickFrame
    local mirrorFrame = bar.untilKickMirrorFrame
    if frame.status and unIntCFG.showUntilKickTick then
        frame.status:SetMinMaxValues(minVal, maxVal)
        frame.status:SetValue(bar_status:GetValue())
        --kick_frame.status:SetReverseFill(switch and true or false)
        frame.status:Show()
        mirrorFrame:Show()
    else
        if frame.status then frame.status:Hide() end
        mirrorFrame:Hide()
    end
    frame:SetAlpha(alpha)
    mirrorFrame:SetAlpha(alpha)

    if frame.bg and unIntCFG.showUntilKickTickBackground then
        frame.bg:Show()
    elseif 
        frame.bg then frame.bg:Hide() 
    end
    frame.bg:SetAlpha(alpha)

    status.interruptMarker:SetOrientation("HORIZONTAL")
    status.interruptMarker:SetRotatesTexture(false)

    local markerTex = status.interruptMarker:GetStatusBarTexture()

    status.interruptMarkerPoint:ClearAllPoints()

    if switch then
        -- RIGHT -> LEFT
        status.interruptMarker:SetReverseFill(true)
        status.interruptMarkerPoint:SetPoint("RIGHT", markerTex, "LEFT", 0, 0)
    else
        -- LEFT -> RIGHT
        status.interruptMarker:SetReverseFill(false)
        status.interruptMarkerPoint:SetPoint("LEFT", markerTex, "RIGHT", 0, 0)
    end

    status.interruptMarker:Show()
    status.interruptMarkerPoint:Show()
    if status.interruptPositioner then status.interruptPositioner:Hide() end

    status.interruptMarker:SetAlpha(alpha)
    status.interruptMarkerPoint:SetAlpha(alpha)
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

    local spellID, kickDur = UNINTERRUPTIBLE:GetKickTimer()
    if not spellID or not kickDur then
        return
    end
    local kickReady = kickDur:IsZero()   -- secret boolean
    a = Alpha_ShowOnlyWhenKickReady(notIntr, kickReady)
    if cfg.uninterruptible.disableBarUnKick then
        bar.group:SetAlpha(a)
    end
end

-- Shows bar ONLY when: cast is interruptible AND kick is ready.
-- Call this from your per-frame update while a cast is active.
local function UpdateShowWhenKickAvailable(bar, vars, cfg, castType)
    local unIntCFG = cfg.uninterruptible
    if not unIntCFG.disableBarUnKick and not unIntCFG.showUntilKickTick then
        return
    end
    if not bar or not vars then return end

    local _, kickDur = UNINTERRUPTIBLE:GetKickTimer()
    local notIntr   = vars and vars.nIntr
    local kickReady = kickDur:IsZero()
    local alpha = KickTickAlpha(notIntr, kickReady)

    if unIntCFG.disableBarUnKick then
         bar.group:SetAlpha(alpha)
         return
    end
    if unIntCFG.showUntilKickTick then
        if cfg.otherFeatures.mirrorBar[castType] then
            bar.untilKickMirrorFrame:SetAlpha(alpha)
        else
            bar.untilKickFrame.status:SetAlpha(alpha)
        end
     end
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
    bar._prevType = castType
    bar.castActive = true

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

-- !!!!!!!!!!!!!!!!!!!!!!! DYNAMIC UPDATE FUNCTION !!!!!!!!!!!!!!!!!!!!!!!!
function CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, castType, vars)
    local durationObject = vars.durationObject
    if not durationObject then return end

    local status = bar.status
    local status_uint = bar.unInterruptedFrame.status
    local status_untilKick = bar.untilKickFrame.status
    local inverted = cfg.otherFeatures.invertBar[castType]

    local progress
    local remaining = durationObject:GetRemainingDuration()
    local elapsedTime = durationObject:GetElapsedDuration()
    -- progress for the bar fill
    local isChannel = (castType == "channel")
    if (not inverted and not isChannel) or (inverted and isChannel) then
        progress = elapsedTime
    else
        progress = remaining
    end

    status_uint:SetValue(progress)
    status_untilKick:SetValue(progress)
    status:SetValue(progress)
    -- Set dynamic texts
    UCB.tags:ApplyTextState(bar, "dynamic", unit, remaining, elapsedTime)

    -- Look for mirror bar updates
    BarUpdate_API:SyncMirror(bar)

    -- Set dynamic colours
    local colourMode = cfg.style.colourMode
    if castType == "empowered" or colourMode == "ombre" then
        local mirror = cfg.otherFeatures.mirrorBar[castType]
        local switch = (inverted or mirror) and not (inverted and mirror)  -- if either is true, but not both
        BarUpdate_API:AssignColours(unit, bar, cfg, colourMode, castType, durationObject, switch)
    end

    -- Show bar if kick is ready
    UpdateShowWhenKickAvailable(bar, vars, cfg, castType)
    return remaining
end