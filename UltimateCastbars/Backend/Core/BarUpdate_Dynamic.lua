local _, UCB = ...

UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.UNINTERRUPTIBLE = UCB.UNINTERRUPTIBLE or {}

local BarUpdate_API = UCB.BarUpdate_API
local UNINTERRUPTIBLE = UCB.UNINTERRUPTIBLE

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
        cc = cfg.style.enemyColour
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
    local mtex = bar._mirrorTex
    local doMirror = bar._mirrored and mtex

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
function BarUpdate_API:SyncMirror(bar)
    if not bar._mirrored then return end
    local status = bar.status and bar.status:GetStatusBarTexture()
    if not status then return end
    bar.mirrorFrame:SetWidth(status:GetWidth())
    bar.unInterruptedMirrorFrame:SetWidth(status:GetWidth())
    bar.untilKickMirrorFrame:SetWidth(status:GetWidth())
end

function BarUpdate_API:AssignColours(unit, bar, cfg, colourMode, castType, durationObject, inverted)
    if castType == "empowered" and cfg.CLASSES.EVOKER.enableEmpowerEffects then
        local tex = bar._tex or bar.status:GetStatusBarTexture()
        bar._tex = tex
        local mtex = bar._mirrorTex or bar.mirrorFrame:GetStatusBarTexture()
        bar._mirrorTex = mtex
        local doMirror = bar._mirrored and mtex
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
