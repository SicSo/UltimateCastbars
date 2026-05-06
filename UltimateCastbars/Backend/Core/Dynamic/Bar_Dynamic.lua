local _, UCB = ...

UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.GeneralCore_Helpers = UCB.GeneralCore_Helpers or {}

local CASTBAR_API = UCB.CASTBAR_API
local GeneralHelpers = UCB.GeneralCore_Helpers

local OMBRE_STOPS = {
    {p=0.10, r=1,   g=0,   b=0},   -- Red
    {p=0.20, r=1,   g=0.5, b=0},   -- Orange
    {p=0.30, r=1,   g=1,   b=0},   -- Yellow
    {p=0.40, r=0,   g=1,   b=0},   -- Green
    {p=0.60, r=0,   g=0.5, b=1},   -- Blue
    {p=0.80, r=0.5, g=0,   b=1},   -- Purple
    {p=1.00, r=1,   g=1,   b=1},   -- Class color (patched)
}

-- !!!!!!!!!!!!!!!!!!!!!!! DYNAMIC UPDATE FUNCTION !!!!!!!!!!!!!!!!!!!!!!!!
local function EnsureOmbreCurve(unit, bar, cfg)
    local cc
    if UnitIsPlayer(unit) then
        local _, classFile = UnitClass(unit)
        local classColourVal = UCB.UIOptions.classColoursList[classFile]
        cc = classColourVal.RGBA
    else
        cc = bar._enemyColour.RGBA
    end
    local needsRebuild = false

    if bar._ombreCCr ~= cc.r or bar._ombreCCg ~= cc.g or bar._ombreCCb ~= cc.b then
        bar._ombreCCr, bar._ombreCCg, bar._ombreCCb = cc.r, cc.g, cc.b
        local last = OMBRE_STOPS[#OMBRE_STOPS]
        last.r, last.g, last.b = cc.r, cc.g, cc.b
        needsRebuild = true
    end

    local curve = bar._ombreCurve
    if not curve then
        curve = C_CurveUtil.CreateColorCurve()
        curve:SetType(Enum.LuaCurveType.Linear)
        bar._ombreCurve = curve
        needsRebuild = true
    end

    if needsRebuild then
        curve:ClearPoints()
        for i = 1, #OMBRE_STOPS do
            local stop = OMBRE_STOPS[i]
            curve:AddPoint(stop.p, CreateColor(stop.r, stop.g, stop.b, 1)) -- 0..1
        end
    end

    return curve
end

local function ombreColours(unit, bar, cfg, durationObject, inverted)
    local status = bar.status
    local tex = bar._tex or status:GetStatusBarTexture()
    bar._tex = tex
    local mtex = bar.mirrorStatus.tex
    local doMirror = bar.flags.mirrored

    local curve = EnsureOmbreCurve(unit, bar, cfg)

    local colour
    if durationObject and durationObject.EvaluateElapsedPercent and durationObject.EvaluateRemainingPercent then
        colour = inverted and durationObject:EvaluateRemainingPercent(curve) or durationObject:EvaluateElapsedPercent(curve)
    --else
    --    local percent = 1
    --    if duration and duration > 0 then
    --        percent = (elapsedSinceStart or 0) / duration
    --    end
    --    if percent <= 0.10 then percent = 0.10 end
    --    if percent >= 1.00 then percent = 1.00 end
    --    colour = curve:Evaluate(percent)
    end

    if not colour then return end
    local r, g, b, a = colour:GetRGBA()
    if not a then a = 1 end

    -- no arithmetic on secret values
    status:SetStatusBarColor(r, g, b, a)
    if tex and tex.SetVertexColor then
        tex:SetVertexColor(r, g, b, a)
        if doMirror then mtex:SetVertexColor(r, g, b, a) end
    end
end

-- !!!!!!!!!!!!!!!!!!!!!!! DYNAMIC UPDATE FUNCTION !!!!!!!!!!!!!!!!!!!!!!!!
local function SyncMirror(bar)
    if not bar.flags.mirrored then return end
    local status = bar.status:GetStatusBarTexture()
    bar.mirrorStatus:SetWidth(status:GetWidth())
    bar.mirror_frames.unInterrupted:SetWidth(status:GetWidth())
    bar.mirror_frames.untilKick:SetWidth(status:GetWidth())
end

local function AssignColours(unit, bar, cfg, colourMode, castType, durationObject, inverted)
    if castType == "empowered" and cfg.CLASSES.EVOKER.enableEmpowerEffects then
        local tex = bar._tex or bar.status:GetStatusBarTexture()
        bar._tex = tex
        local mtex = bar.mirrorStatus.tex
        local doMirror = bar.flags.mirrored
        local curve = bar.empoweredColourCurve
        if not curve then return end

        local colour = inverted and durationObject:EvaluateRemainingPercent(curve) or durationObject:EvaluateElapsedPercent(curve)
        local r, g, b, a = colour:GetRGBA()
        tex:SetVertexColor(r, g, b, a)
        if doMirror then mtex:SetVertexColor(r, g, b, a) end
    elseif colourMode == "ombre" then
        return ombreColours(unit, bar, cfg, durationObject, inverted)
    end
end


-- Shows bar ONLY when: cast is interruptible AND kick is ready.
-- Call this from your per-frame update while a cast is active.
local function UpdateShowWhenKickAvailable(bar, unit, vars, cfg, castType)
    local unIntCFG = cfg.uninterruptible
    if not unIntCFG.disableBarUnKick and not unIntCFG.showUntilKickTick and not unIntCFG.dynamicKickAlphaBar then
        return
    end
    if not bar or not vars then return end

    local _, kickDur = GeneralHelpers:GetKickTimer(unit)
    if not kickDur then return end
    local notIntr   = vars and vars.nIntr
    local kickReady = kickDur:IsZero()

    -- Hide the bar
    if unIntCFG.disableBarUnKick then
        local alpha = GeneralHelpers:KickAlpha(notIntr, kickReady, true)
        if unIntCFG.disableBarUnInt or unIntCFG.changeAlphaBarUnint then
            if unIntCFG.disableBarUnInt then
                alpha = GeneralHelpers:SecretToA_B(notIntr, 0, alpha)
            else
                alpha = GeneralHelpers:SecretToA_B(notIntr, unIntCFG.alphaBarUnint, alpha)
                if not unIntCFG.includeIconAlphaUnint then
                    bar:SetAlpha(alpha)
                    return
                end
            end
        end
        bar.group:SetAlpha(alpha)
        return
    end

    -- Change alpha of the bar
    if unIntCFG.changeAlphaBarUnKick and unIntCFG.dynamicKickAlphaBar then
        local alpha = GeneralHelpers:KickAlpha(notIntr, kickReady, true, unIntCFG.alphaBarUnKick)
        -- Only chnage alpha based on kick ready
        if unIntCFG.includeIconAlphaUnKick then
            bar.group:SetAlpha(alpha)
        else
            bar:SetAlpha(alpha)
        end

        if unIntCFG.disableBarUnInt or unIntCFG.changeAlphaBarUnint then
            if unIntCFG.disableBarUnInt then -- 
                alpha = GeneralHelpers:SecretToA_B(notIntr, 0, alpha)
                bar.group:SetAlpha(alpha)
            else
                alpha = GeneralHelpers:SecretToA_B(notIntr, unIntCFG.alphaBarUnint, alpha)
                if unIntCFG.includeIconAlphaUnint then
                   bar.group:SetAlpha(alpha)
                else
                   bar:SetAlpha(alpha)
                end
            end
        end
        
     end

     -- Show fill bar
    if unIntCFG.showUntilKickTick then
        local alpha = GeneralHelpers:KickAlpha(notIntr, kickReady, false)
        if cfg.otherFeatures.mirrorBar[castType] then
            bar.mirror_frames.untilKick:SetAlpha(alpha)
        else
            bar.frames.untilKick.status:SetAlpha(alpha)
        end
     end
end

-- !!!!!!!!!!!!!!!!!!!!!!! DYNAMIC UPDATE FUNCTION !!!!!!!!!!!!!!!!!!!!!!!!
function CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, case, castType, vars)
    local durationObject = vars.durationObject
    if not durationObject then return end

    local status = bar.status
    local status_uint = bar.frames.unInterrupted.status
    local status_untilKick = bar.frames.untilKick.status
    local inverted = cfg.otherFeatures.invertBar[castType]

    local progress
    local remaining = durationObject:GetRemainingDuration()
    local elapsedTime = durationObject:GetElapsedDuration()
    -- progress for the bar fill
    local isChannel = (castType == "channel")
    local useElapsed = (not inverted and not isChannel) or (inverted and isChannel)
    if useElapsed then
        progress = elapsedTime
    else
        progress = remaining
    end

    status_uint:SetValue(progress)
    status_untilKick:SetValue(progress)
    status:SetValue(progress)
    --if bar.flags.effects.spark then
    --    bar.effects.sparkDriver:SetValue(progress)
    --end
    
    if bar.flags.effects.spark and bar.flags.mirrored then
        if useElapsed then
            bar.effects.sparkDriver:SetValue(remaining)
        else
            bar.effects.sparkDriver:SetValue(elapsedTime)
        end
    end

    -- Set dynamic texts
    UCB.tags:ApplyTextState(bar, case, "dynamic", unit, remaining, elapsedTime)

    -- Look for mirror bar updates
    SyncMirror(bar)

    -- Set dynamic colours
    if castType == "empowered" or bar._colourMode == "ombre" then
        local mirror = cfg.otherFeatures.mirrorBar[castType]
        local switch = (inverted or mirror) and not (inverted and mirror)  -- if either is true, but not both
        AssignColours(unit, bar, cfg, bar._colourMode, castType, durationObject, switch)
    end

    -- Show bar if kick is ready
    UpdateShowWhenKickAvailable(bar, unit, vars, cfg, castType)
    return remaining
end