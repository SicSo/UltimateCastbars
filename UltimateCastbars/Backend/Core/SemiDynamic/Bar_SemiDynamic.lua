local ADDON_NAME, UCB = ...

UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.tags     = UCB.tags     or {}
UCB.Preview_API = UCB.Preview_API or {}
UCB.GeneralCore_Helpers = UCB.GeneralCore_Helpers or {}
UCB.Latency = UCB.Latency or {}
UCB.UIOptions = UCB.UIOptions or {}

local CASTBAR_API = UCB.CASTBAR_API
local tags = UCB.tags
local BarUpdate_API = UCB.BarUpdate_API
local Preview_API = UCB.Preview_API
local GeneralHelpers = UCB.GeneralCore_Helpers
local Latency = UCB.Latency
local UIOptions = UCB.UIOptions


function CASTBAR_API:PrintSpellID(mainCFG, spellID)
    if mainCFG.misc.printSpellIDMode then
        local info = C_Spell.GetSpellInfo(spellID)
        local spellName = info and info.name or "Unknown"
        print("Casting: "..UIOptions.ColorText(UIOptions.turquoise, spellName).." (Spell ID: "..UIOptions.ColorText(UIOptions.turquoise, spellID)..")")
    end
end

-- Tries to stop previous casts
function CASTBAR_API:StopPrevCast(unit, bar, castGUID, spellID, castBarID)
    if not bar then bar = UCB.castBar[unit] end
    if bar.flags.castActive then
        if bar.flags.prevType == "normal" then
            CASTBAR_API:OnUnitSpellcastStop(unit, castGUID, spellID, castBarID)
        elseif bar.flags.prevType == "channel" then
            CASTBAR_API:OnUnitSpellcastChannelStop(unit, castGUID, spellID, castBarID)
        elseif bar.flags.prevType == "empowered" then
            CASTBAR_API:OnUnitSpellcastEmpowerStop(unit, castGUID, spellID, castBarID)
        end
    end
end

function CASTBAR_API:InitCastbarVal(status, castType, resumeCast, vars, cfg)
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

function CASTBAR_API:HideCastbar(bar, unit, vars, cfg, starting_alpha)
    local unintCFG = cfg.uninterruptible
    local notIntr = vars and vars.nIntr  -- secret boolean

    local alphaUnint = 1
    local alphaKick = 1
   
    if unintCFG.disableBarUnKick or unintCFG.changeAlphaBarUnKick then
        local spellID, kickDur = GeneralHelpers:GetKickTimer(unit)
        if not spellID or not kickDur then
            return
        end
        local kickReady = kickDur:IsZero()   -- secret boolean
        if unintCFG.disableBarUnKick then
            alphaKick = GeneralHelpers:KickAlpha(notIntr, kickReady, true)
            bar.group:SetAlpha(alphaKick)
        end
        if unintCFG.changeAlphaBarUnKick and not unintCFG.disableBarUnKick then
            alphaKick = GeneralHelpers:KickAlpha(notIntr, kickReady, true, unintCFG.alphaBarUnKick)
            if unintCFG.includeIconAlphaUnKick then
                bar.group:SetAlpha(alphaKick)
            else
                bar:SetAlpha(alphaKick)
            end
        end
    end

    if unintCFG.disableBarUnInt or unintCFG.changeAlphaBarUnint then
         if unintCFG.disableBarUnInt then
            alphaUnint = C_CurveUtil.EvaluateColorValueFromBoolean(notIntr, 0, alphaKick)
            bar.group:SetAlpha(alphaUnint)
        end
        if unintCFG.changeAlphaBarUnint and not unintCFG.disableBarUnInt then
             alphaUnint = C_CurveUtil.EvaluateColorValueFromBoolean(notIntr, unintCFG.alphaBarUnint, alphaKick)
             if unintCFG.includeIconAlphaUnint then
                bar.group:SetAlpha(alphaUnint)
             else
                bar:SetAlpha(alphaUnint)
             end
        end
    end
end


function CASTBAR_API:MirrorBar(cfg, bar, castType)
    local mirror = cfg.otherFeatures.mirrorBar[castType]
    bar.flags.mirrored = mirror

    -- Show/hide mirror frame
    bar.mirrorStatus:SetShown(mirror)
    bar.mirror_frames.unInterrupted:SetShown(mirror and cfg.uninterruptible.showUninterruptibleFill)
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

function CASTBAR_API:AssignQueueWindow(unit, cfg, typeCast)
    local bar = UCB.castBar[unit]
    if not bar.queueWindowOverlay then return end

    local otherCFG = cfg.otherFeatures
    local queueWindowOverlay = bar.queueWindowOverlay
    local overlayFrame = bar.frames.overlay
    local inverted = otherCFG.invertBar[typeCast]
    local mirror = otherCFG.mirrorBar[typeCast]

    local switch = (inverted or mirror) and not (inverted and mirror)  -- if either is true, but not both
    local queWindow = BarUpdate_API.queueWindow / 1000

    if otherCFG.showQueueWindow[typeCast] and queWindow < tags.var[unit].dTime then
        
        local px = cfg.general.actualBarWidth * (queWindow / tags.var[unit].dTime)
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

 function CASTBAR_API:AssignLatencyWindow(bar, cfg, castType, latency, vars)
    local latencyOverlay = bar.latencyOverlay
    if not latencyOverlay then return end
    if latency == nil then latencyOverlay:Hide() return end

    local unit = "player"
    local otherCFG = cfg.otherFeatures
    local latencyCFG = otherCFG.latency
    local overlayFrame = bar.frames.overlay
    local inverted = otherCFG.invertBar[castType]
    local mirror = otherCFG.mirrorBar[castType]

    local switch = (inverted or mirror) and not (inverted and mirror)  -- if either is true, but not both

    if latencyCFG.useWorldLatency then
        latency = Latency.worldLatency
    end
    vars.latency = latency  -- store latency in vars for tag access
    local disaplyLatency = math.min(latency, latencyCFG.maxLatency / 1000) -- cap latency to maxLatency setting (converted to seconds)

    if latencyCFG.enabled and latencyCFG.show[castType] and disaplyLatency < tags.var[unit].dTime then
        local px = cfg.general.actualBarWidth * (disaplyLatency / tags.var[unit].dTime)
        latencyOverlay:SetWidth(px)
        latencyOverlay:ClearAllPoints()

        if (not switch and castType ~= "channel") or (castType == "channel" and switch) then
            latencyOverlay:SetPoint("TOPRIGHT", overlayFrame, "TOPRIGHT", 0, 0)
            latencyOverlay:SetPoint("BOTTOMRIGHT", overlayFrame, "BOTTOMRIGHT", 0, 0)
        else
            latencyOverlay:SetPoint("TOPLEFT", overlayFrame, "TOPLEFT", 0, 0)
            latencyOverlay:SetPoint("BOTTOMLEFT", overlayFrame, "BOTTOMLEFT", 0, 0)
        end

        latencyOverlay:Show()
    else
        latencyOverlay:Hide()
    end
    
end

function CASTBAR_API:SemiColourUpdate(unit, bar, cfg)
    local tex = bar.status:GetStatusBarTexture()
    local mtex = bar.mirrorStatus.tex
    local doMirror = bar.flags.mirrored
    local colourMode = bar._colourMode
    local canGradient = tex and tex.SetGradient
    local status = bar.status
    local bgColourMode = bar._bgColourMode

    if UCB:IsPlayer(unit) then
        if colourMode == "single" then
            local r, g, b, a = bar._r, bar._g, bar._b, bar._a
            status:SetStatusBarColor(r, g, b, a)
            if doMirror then mtex:SetVertexColor(r, g, b, a) end
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
        -- Statusbar
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
                local r, g, b, a, RGBA
                if UnitIsPlayer(unit) then
                    local _, classFile = UnitClass(unit)
                    local classColourVal = UCB.UIOptions.classColoursList[classFile]
                    RGBA = classColourVal.RGBA
                else
                    local defaultEnemyColour = bar._enemyColour
                    RGBA = defaultEnemyColour.RGBA
                end
                r, g, b, a = RGBA.r, RGBA.g, RGBA.b ,RGBA.a
                status:SetStatusBarColor(r, g, b, a)
                if doMirror then mtex:SetVertexColor(r, g, b, a) end
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

        -- Background
        if not UCB:IsPlayer(unit) and bgColourMode == "class" then
            local r, g, b, a, col1, RGBA
            if UnitIsPlayer(unit) then
                local _, classFile = UnitClass(unit)
                local classColourVal = UCB.UIOptions.classColoursList[classFile]
                RGBA = classColourVal.RGBA
                a = (bar._bgAlpha.use and bar._bgAlpha.alpha or 1)
                --col1 = classColourVal.COL
            else
                local defaultEnemyColour = bar._bgEnemyColour
                RGBA = defaultEnemyColour
                a = (bar._bgAlpha.use and bar._bgAlpha.alpha or RGBA.a)
                --col1 = defaultEnemyColour.COL
            end
            r, g, b = RGBA.r, RGBA.g, RGBA.b
            bar.bg:SetVertexColor(r, g, b, a)
        end
    end
end

function CASTBAR_API:InterruptibleTick(bar, unit, bar_status, vars, cfg, castType)
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

    local spellID, kickDur = GeneralHelpers:GetKickTimer(unit)
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

function CASTBAR_API:SpellFilterClass(unit, spellID, cfg)
    if not UCB:IsPlayer(unit) then
        return true
    end

    local classCFG = cfg.CLASSES[UCB.className]

    if not classCFG then
        return true
    end
    return CASTBAR_API:SpellFilter(spellID, classCFG)
end

function CASTBAR_API:SpellFilter(spellID, cfg)

    local blacklistWhitelist = cfg.blacklistWhitelist

    if not blacklistWhitelist.enableAbilityFilter then
        return true
    end

    local inWhiteList = blacklistWhitelist._whiteListSpellIDs[spellID]
    local inBlackList = blacklistWhitelist._blackListSpellIDs[spellID]

    if blacklistWhitelist.blackList then
        if inBlackList then
            return false
        else
            return true
        end
    else
        if inWhiteList then
            return true
        else
            return false
        end
    end
end

function CASTBAR_API:ApplyStyle(bar, unit, cfg, spellID, castType, bar_status)

    local styleCFG = cfg.styleCastType.general
    local otherCFG = cfg.otherFeatures

    local applied = false
    if UCB:IsPlayer(unit) then
        local classCFG = cfg.CLASSES[UCB.className]
        local spellStyling = classCFG.spellStyling

        if spellStyling.useStyleSpell then
            if spellStyling._customSpellStyles and spellStyling._customSpellStyles[spellID] then
                styleCFG = spellStyling._customSpellStyles[spellID]
                BarUpdate_API:RefreshBarStyleOnly(unit, styleCFG)
                BarUpdate_API:UpdateStyle(unit, false, spellID, styleCFG)
                applied = true
            end
        end
    end

    if not applied then
        local castTypeStyleCFG = cfg.styleCastType
        if not castTypeStyleCFG.useGeneralStyle then
            styleCFG = castTypeStyleCFG[castType]
            BarUpdate_API:RefreshBarStyleOnly(unit, styleCFG)
            BarUpdate_API:UpdateStyle(unit, false, castType, styleCFG)
        end
    end

    if styleCFG.effects.spark.enable then

        local spark = bar.effects.spark
        local driver = bar.effects.sparkDriver

        bar.effects.spark:Show()
        spark:ClearAllPoints()

        if otherCFG.mirrorBar[castType] then
            driver:Show()
            driver:SetMinMaxValues(bar_status:GetMinMaxValues())
            driver:SetValue(bar_status:GetValue())
            spark:SetPoint("CENTER", driver:GetStatusBarTexture(), "RIGHT", 0, 0)
        else
            driver:Hide()
            spark:SetPoint("CENTER", bar_status:GetStatusBarTexture(), "RIGHT", 0, 0)
        end
    end

    bar.cfg_style = styleCFG
end


----------------------------------------------------------------- CASTBAR UPDATE FUNCTIONS -----------------------------------------------------------------
function CASTBAR_API:CastSetup(unit, castGUID, spellID, castBarID, resumeCast, castType, latency)
    -- Print spellID 
    local mainCFG = UCB.GetValueConfig()
    CASTBAR_API:PrintSpellID(mainCFG, spellID)

    local cfg = mainCFG[unit]

    -- Spell filter
    if not CASTBAR_API:SpellFilterClass(unit, spellID, cfg) then
        UCB.usePetForPlayer = false
        return false, nil, nil, nil
    end

    -- Stop preview
    if Preview_API.previewActive and Preview_API.previewActive[unit] then
        Preview_API:HidePreviewCastBar(unit)
    end

    local bar = UCB.castBar[unit]
    CASTBAR_API:StopPrevCast(unit, bar, nil, nil, nil)

    -- Hide Background
    local otherCFG = cfg.otherFeatures
    if otherCFG.permanentBackgrodund.enable and otherCFG.permanentBackgrodund.hideWhenCasting then
        bar.background_frame:Hide()
    end

    -- Stop view of cancelled/interrupted casts
    CASTBAR_API:StopFrameTimer(UCB.castBar[unit], "cancelled")
    CASTBAR_API:StopFrameTimer(UCB.castBar[unit], "interrupted")

    bar.current_spellID = spellID
    bar.current_castGUID = castGUID
    bar.current_castBarID = castBarID

    -- Update internal vars with spellInfo
    local icon_texture = tags:updateVars(unit, castType, spellID, cfg, latency)
    local vars = tags.var[unit]
    if UCB:IsPlayer(unit) then
        -- Spell filter unint (make the spell int to avoid any unint effects)
        if not CASTBAR_API:SpellFilter(spellID, cfg.uninterruptible) then
            vars.nIntr = false
        end
    end

    -- Failsafe
    if not vars.durationObject then
        return
    end

    -- Set text, icon, queue window
    tags:setTextSameState(bar, "semiDynamic", unit, castType, false)
    tags:setTextSameState(bar, "dynamic", unit, castType, true)
    
    bar.icon:SetTexture(icon_texture)

    if UCB:IsPlayer(unit) then
        CASTBAR_API:AssignQueueWindow(unit, cfg, castType)
        CASTBAR_API:AssignLatencyWindow(bar, cfg, castType, latency, vars)
    end

    local bar_status = bar.status
    bar_status:SetMinMaxValues(0, vars.dTime)
    CASTBAR_API:MirrorBar(cfg, bar, castType)
    CASTBAR_API:InitCastbarVal(bar_status, castType, resumeCast, vars, otherCFG)

    -- Set style based on cast type
    CASTBAR_API:ApplyStyle(bar, unit, cfg, spellID, castType, bar_status)

    CASTBAR_API:UninterruptibleCast(bar, bar_status, vars)

    CASTBAR_API:InterruptibleTick(bar, unit, bar_status, vars, cfg, castType)

    return true, cfg, bar, vars
end

function CASTBAR_API:CastOnUpdateSetup(bar, unit, cfg, vars, castType, spellID, CastbarOnUpdate)
    bar.gate_effects:SetAlpha(1)
    bar.group:SetAlpha(1)
    bar:SetAlpha(1)
    bar._ucbUnit = unit
    bar._ucbCfg = cfg
    bar._ucbCastType = castType
    bar._ucbVars = vars
    bar._ucbSpellID = spellID
    if bar.flags.effects.spark then bar.effects.spark:Show() end
    bar:SetScript("OnUpdate", CastbarOnUpdate)
    bar.group:Show()
    bar.flags.prevType = castType
    bar.flags.castActive = true

    CASTBAR_API:HideCastbar(bar, unit, vars, cfg)
end


function CASTBAR_API:CastUpdate(unit, castGUID, spellID, castBarID, castType, latency)
    local cfg = UCB.GetValueConfig(unit)

    -- Spell filter
    if not CASTBAR_API:SpellFilterClass(unit, spellID, cfg) then
        return false
    end

    local bar = UCB.castBar[unit]

    bar.current_spellID = spellID
    bar.current_castGUID = castGUID
    bar.current_castBarID = castBarID

    local icon_texture = tags:updateVars(unit, castType, spellID, cfg, latency)
    local vars = tags.var[unit]

    -- Failsafe
    if not vars.durationObject then
        return
    end

    -- Set text, icon, queue window
    tags:setTextSameState(bar, "semiDynamic", unit, castType, false)
    tags:setTextSameState(bar, "dynamic", unit, castType, true)

    bar.icon:SetTexture(icon_texture)

    if UCB:IsPlayer(unit) then
        CASTBAR_API:AssignQueueWindow(unit, cfg, castType)
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
    return true
end