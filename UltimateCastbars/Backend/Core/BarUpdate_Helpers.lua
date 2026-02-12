local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}
UCB.tags = UCB.tags or {}
UCB.Text_API = UCB.Text_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
--local CFG_API.GetValueConfig = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local BarUpdate_API = UCB.BarUpdate_API
local OtherFeatures_API = UCB.OtherFeatures_API
local Text_API = UCB.Text_API

local LSM  = UCB.LSM

----------------------------------------HELPER----------------------------------------
local floor = math.floor

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
local function ombreColours(bar, percent)
    local status = bar.status
    local tex = bar._tex or status:GetStatusBarTexture()
    bar._tex = tex

    -- Patch last stop only if class colour changed
    local cc = UCB.classColour
    if bar._ombreCCr ~= cc.r or bar._ombreCCg ~= cc.g or bar._ombreCCb ~= cc.b then
        bar._ombreCCr, bar._ombreCCg, bar._ombreCCb = cc.r, cc.g, cc.b
        local last = OMBRE_STOPS[#OMBRE_STOPS]
        last.r, last.g, last.b = cc.r, cc.g, cc.b
    end

    -- Clamp percent just in case
    if percent <= 0.10 then
        -- before first stop, treat as first stop colour
        percent = 0.10
    elseif percent >= 1.0 then
        percent = 1.0
    end

    -- Find interval (linear scan is fine for 7 stops; branchy but cheap)
    local stops = OMBRE_STOPS
    local prev = stops[1]
    local next = stops[2]

    for i = 2, #stops do
        next = stops[i]
        if percent <= next.p then
            prev = stops[i - 1]
            break
        end
    end

    local range = next.p - prev.p
    local rel = (percent - prev.p) / (range ~= 0 and range or 1)

    local r = prev.r + (next.r - prev.r) * rel
    local g = prev.g + (next.g - prev.g) * rel
    local b = prev.b + (next.b - prev.b) * rel

    -- Quantize to 0..255 so we can early-out if visually identical
    local ri = floor(r * 255 + 0.5)
    local gi = floor(g * 255 + 0.5)
    local bi = floor(b * 255 + 0.5)

    if bar._ombreRi == ri and bar._ombreGi == gi and bar._ombreBi == bi then
        return
    end
    bar._ombreRi, bar._ombreGi, bar._ombreBi = ri, gi, bi

    -- Convert back to 0..1 floats
    r, g, b = ri / 255, gi / 255, bi / 255

    status:SetStatusBarColor(r, g, b, 1)

    if tex and tex.SetGradient then
        -- Reuse CreateColor object(s) instead of allocating every call
        local c1 = bar._ombreC1
        if not c1 then
            c1 = CreateColor(r, g, b, 1)
            bar._ombreC1 = c1
        elseif c1.SetRGBA then
            c1:SetRGBA(r, g, b, 1)
        else
            -- If no SetRGBA, recreate only when colour changed (we're already in "changed" path)
            c1 = CreateColor(r, g, b, 1)
            bar._ombreC1 = c1
        end

        tex:SetGradient("HORIZONTAL", c1, c1)
    end
end

----------------------------------------MAIN----------------------------------------
function BarUpdate_API:UpdateText(unit)
    local bar = UCB.castBar[unit]
    local cfg = CFG_API.GetValueConfig(unit).text
    local generalCFG = cfg.generalValues
    local generalFont, generalFontSize, generalColour = generalCFG.font, generalCFG.textSize, generalCFG.colour
    local generalOutlineTags, generalShadow = Text_API:OutlineFlags(generalCFG.outline)
    local generalShadowOffset, generalShadowColour = generalCFG.shadowOffset, generalCFG.shadowColour
    local globalFont = LSM:GetDefault("font") or GameFontHighlightSmall:GetFont()

    --if not bar.texts then bar.texts = {} end
    if bar.texts then
        for k, v in pairs(bar.texts) do
            v:Hide()
        end
    end
    bar.texts = {}

    for _, tagStates in pairs(cfg.tagList) do
        for key, tagOptions in pairs(tagStates) do
            if tagOptions.show then
                if not bar.texts[key] then
                    bar.texts[key] = bar.status:CreateFontString(nil, tagOptions.frameStrata, "GameFontHighlightSmall")
                end
                UCB.tags:updateTagText(key, tagOptions, cfg)

                local usedFont, usedFontSize, usedColour = generalFont, generalFontSize, generalColour
                local usedOutline, usedShadow, usedShadowOffset, usedShadowColour = generalOutlineTags, generalShadow, generalShadowOffset, generalShadowColour
                if not generalCFG.useGeneralFont then
                    usedFont = tagOptions.font
                elseif generalCFG.useGlobalFont then
                    usedFont = globalFont
                end
                if not generalCFG.useGeneralTextSize then
                    usedFontSize = tagOptions.textSize
                end
                if not generalCFG.useGeneralColour then
                    usedColour = tagOptions.colour
                end
                if not generalCFG.useGeneralOutline then
                    usedOutline, usedShadow = Text_API:OutlineFlags(tagOptions.outline)
                    usedShadowOffset = tagOptions.shadowOffset
                    usedShadowColour = tagOptions.shadowColour
                end

                local fs = bar.texts[key]
                fs:SetJustifyH(tagOptions.justify)
                fs:SetPoint(tagOptions.anchorFrom, bar.status, tagOptions.anchorTo, tagOptions.textOffsetX, tagOptions.textOffsetY)
                fs:SetFont(usedFont, usedFontSize, unpack(usedOutline))
                if usedShadow then
                    fs:SetShadowColor(usedShadowColour.r, usedShadowColour.g, usedShadowColour.b, usedShadowColour.a)
                    fs:SetShadowOffset(usedShadowOffset, -usedShadowOffset)
                else
                    fs:SetShadowOffset(0, 0)
                end
                fs:SetTextColor(usedColour.r, usedColour.g, usedColour.b, usedColour.a)
                fs:Show()
                tagOptions._compiled = UCB.tags:compileFormula(tagOptions._formula, tagOptions._limits)
            elseif bar.texts[key] then
                bar.texts[key]:Hide()
            end
        end
    end

    -- static update (should use compiled ops inside setTextSameState)
    UCB.tags:setTextSameState(cfg, bar, "static", unit)
end


function BarUpdate_API:UpdateVisibility(unit)
    local bar = UCB.castBar[unit]
    local cfg = CFG_API.GetValueConfig(unit).visibility
    bar:SetFrameStrata(cfg.frameStrata)
    bar:SetFrameLevel(cfg.frameLevel)
    bar.iconFrame:SetFrameStrata(cfg.frameStrata)
    bar.iconFrame:SetFrameLevel(cfg.frameLevel + 1)  -- icon above bar
end



local function ClampNonNeg(x)
    return (x and x > 0) and x or 0
end

local function EnsureRectBorder(holder, key, frameLevelDelta)
    holder[key] = holder[key] or CreateFrame("Frame", nil, holder)
    local f = holder[key]
    f:SetFrameLevel(holder:GetFrameLevel() + frameLevelDelta)
    f:ClearAllPoints()
    f:SetAllPoints(holder)

    if not f.top then
        f.top    = f:CreateTexture(nil, "OVERLAY")
        f.bottom = f:CreateTexture(nil, "OVERLAY")
        f.left   = f:CreateTexture(nil, "OVERLAY")
        f.right  = f:CreateTexture(nil, "OVERLAY")
    end
    return f
end

local function ApplyRectBorder(holder, key, target, texture, colour, baseThickness, offsets, frameLevelDelta)
    local f = EnsureRectBorder(holder, key, frameLevelDelta)

    local t = baseThickness or 0
    -- Visible thickness per side = baseThickness - offsetSide (clamped)
    local tL = ClampNonNeg(t + offsets.left)
    local tR = ClampNonNeg(t + offsets.right)
    local tT = ClampNonNeg(t + offsets.top)
    local tB = ClampNonNeg(t + offsets.bottom)

    local function setup(tex)
        tex:SetTexture(texture)
        tex:SetVertexColor(colour.r, colour.g, colour.b, colour.a)
        tex:SetHorizTile(true)
        tex:SetVertTile(true)
        tex:Show()
    end

    if tT <= 0 then f.top:Hide() else setup(f.top) end
    if tB <= 0 then f.bottom:Hide() else setup(f.bottom) end
    if tL <= 0 then f.left:Hide() else setup(f.left) end
    if tR <= 0 then f.right:Hide() else setup(f.right) end

    -- LEFT: outside, full height of target (not part of outside corner squares)
    if tL > 0 then
        f.left:ClearAllPoints()
        f.left:SetPoint("TOPRIGHT",    target, "TOPLEFT",    0, 0)
        f.left:SetPoint("BOTTOMRIGHT", target, "BOTTOMLEFT", 0, 0)
        f.left:SetWidth(tL)
    end

    -- RIGHT: outside, full height of target
    if tR > 0 then
        f.right:ClearAllPoints()
        f.right:SetPoint("TOPLEFT",    target, "TOPRIGHT",    0, 0)
        f.right:SetPoint("BOTTOMLEFT", target, "BOTTOMRIGHT", 0, 0)
        f.right:SetWidth(tR)
    end

    -- TOP: outside, full width INCLUDING side thickness (fills corners)
    if tT > 0 then
        f.top:ClearAllPoints()
        f.top:SetPoint("BOTTOMLEFT",  target, "TOPLEFT",  -tL, 0)
        f.top:SetPoint("BOTTOMRIGHT", target, "TOPRIGHT",  tR, 0)
        f.top:SetHeight(tT)
    end

    -- BOTTOM: outside, full width INCLUDING side thickness (fills corners)
    if tB > 0 then
        f.bottom:ClearAllPoints()
        f.bottom:SetPoint("TOPLEFT",  target, "BOTTOMLEFT",  -tL, 0)
        f.bottom:SetPoint("TOPRIGHT", target, "BOTTOMRIGHT",  tR, 0)
        f.bottom:SetHeight(tB)
    end

    f:Show()
end


local function HideRectBorder(holder, key)
    local f = holder[key]
    if f then f:Hide() end
end

function BarUpdate_API:UpdateBorderBar(unit)
    local bar = UCB.castBar[unit]
    local cfg = CFG_API.GetValueConfig(unit).style
    if not bar then return end

    if not cfg.showBorder then
        HideRectBorder(bar, "_rectBorder")
        return
    end

    ApplyRectBorder(
        bar,
        "_rectBorder",
        bar,                 -- target region to border
        cfg.textureBorder,   -- strip texture
        cfg.borderColour,
        cfg.borderThickness,
        {
            left   = cfg.borderOffsetLeft,
            right  = cfg.borderOffsetRight,
            top    = cfg.borderOffsetTop,
            bottom = cfg.borderOffsetBottom,
        },
        -1
    )
end


function BarUpdate_API:UpdateIconBorder(unit)
    local bar = UCB.castBar[unit]
    local cfg = CFG_API.GetValueConfig(unit).style
    if not bar or not bar.iconFrame then return end

    if not cfg.showBorderIcon then
        HideRectBorder(bar.iconFrame, "_rectBorder")
        return
    end

    local texture, colour, thickness, offs
    if cfg.syncBorderIcon then
        texture   = cfg.textureBorder
        colour    = cfg.borderColour
        thickness = cfg.borderThickness
        -- if you want icon to use icon offsets even when synced, keep these:
        offs = {
            left   = cfg.borderOffsetLeftIcon,
            right  = cfg.borderOffsetRightIcon,
            top    = cfg.borderOffsetTopIcon,
            bottom = cfg.borderOffsetBottomIcon,
        }
        -- If instead you want synced to use the BAR offsets, swap to cfg.borderOffsetLeft/Right/Top/Bottom
    else
        texture   = cfg.textureBorderIcon
        colour    = cfg.borderColourIcon
        thickness = cfg.borderThicknessIcon
        offs = {
            left   = cfg.borderOffsetLeftIcon,
            right  = cfg.borderOffsetRightIcon,
            top    = cfg.borderOffsetTopIcon,
            bottom = cfg.borderOffsetBottomIcon,
        }
    end

    ApplyRectBorder(
        bar.iconFrame,
        "_rectBorder",
        bar.iconFrame,
        texture,
        colour,
        thickness,
        offs,
        -3
    )
end

function BarUpdate_API:UpdateStyle(unit)
    local bar = UCB.castBar[unit]
    local bigCFG = CFG_API.GetValueConfig(unit)
    local cfg = bigCFG.style

    -- Bar style
    bar.status:SetStatusBarTexture(cfg.texture)

    -- Background
    if not bar.bg then
        bar.bg = bar.status:CreateTexture(nil, "BACKGROUND", nil, 1)
        bar.bg:SetAllPoints()
    end
    if cfg.showBackground then
        bar.bg:SetTexture(cfg.textureBack)
        bar.bg:SetVertexColor(cfg.bgColour.r, cfg.bgColour.g, cfg.bgColour.b, cfg.bgColour.a)
        --bar.bg:SetColorTexture(cfg.bgColour.r, cfg.bgColour.g, cfg.bgColour.b, cfg.bgColour.a)
        bar.bg:Show()
    elseif bar.bg then
        bar.bg:Hide()
    end

    --Bar border
    BarUpdate_API:UpdateBorderBar(unit)

    -- Icon border
    BarUpdate_API:UpdateIconBorder(unit)
end


function BarUpdate_API:UpdateOtherFeatures(unit)
    local bar = UCB.castBar[unit]
    local cfg = CFG_API.GetValueConfig(unit).otherFeatures

    if cfg.showQueueWindow.normal or  cfg.showQueueWindow.channel or cfg.showQueueWindow.empowered then
        if not bar.queueWindowOverlay then
            bar.queueWindowOverlay = bar.status:CreateTexture(nil, "OVERLAY", nil, 7)
        end
        -- CVAR
        if cfg.queueMatchCVAR then
            BarUpdate_API.queueWindow = OtherFeatures_API:getSpellQueCVAR()
        else
            BarUpdate_API.queueWindow = cfg.queueWindow
        end
        -- Texture and colour
        if cfg.useQueueTexture then
            bar.queueWindowOverlay:SetTexture(cfg.queueTexture)
            bar.queueWindowOverlay:SetVertexColor(cfg.queueWindowColour.r, cfg.queueWindowColour.g, cfg.queueWindowColour.b, cfg.queueWindowColour.a)
        else
            bar.queueWindowOverlay:SetVertexColor(1, 1, 1, 1)
            bar.queueWindowOverlay:SetColorTexture(cfg.queueWindowColour.r, cfg.queueWindowColour.g, cfg.queueWindowColour.b, cfg.queueWindowColour.a)
        end
        bar.queueWindowOverlay:Show()
    elseif bar.queueWindowOverlay then
        bar.queueWindowOverlay:Hide()
    end
end


function BarUpdate_API:UpdateColours(unit)
    local bar = UCB.castBar[unit]

    local cfg = CFG_API.GetValueConfig(unit).style

    local colourMode = cfg.colourMode

    -- Build the static palette (1 colour or 2-colour gradient)
    local colours
    if colourMode == "class" then
        colours = { UCB.classColour }
    else
        -- "custom" (or anything not class): either single or gradient depending on cfg
        if cfg.gradientEnable then
            colours = { cfg.customColour, cfg.customColour2 }
        else
            colours = { cfg.customColour }
        end
    end
    BarUpdate_API.barColour = colours

    local n = #colours

    if n == 1 then
        local c = colours[1]
        local r, g, b, a = c.r, c.g, c.b, c.a

        bar._colourMode = "single"
        bar._r, bar._g, bar._b, bar._a = r, g, b, a

        local col1 = bar._c1
        if not col1 then
            col1 = CreateColor(r, g, b, a)
            bar._c1 = col1
        elseif col1.SetRGBA then
            col1:SetRGBA(r, g, b, a)
        end

        bar._c1 = col1

        return
    end

    -- n == 2
    local c1, c2 = colours[1], colours[2]
    local r1, g1, b1, a1 = c1.r, c1.g, c1.b, c1.a
    local r2, g2, b2, a2 = c2.r, c2.g, c2.b, c2.a

    bar._colourMode = "gradient"
    bar._r1, bar._g1, bar._b1, bar._a1 = r1, g1, b1, a1
    bar._r2, bar._g2, bar._b2, bar._a2 = r2, g2, b2, a2

    local col1 = bar._c1
    if not col1 then
        col1 = CreateColor(r1, g1, b1, a1)
        bar._c1 = col1
    elseif col1.SetRGBA then
        col1:SetRGBA(r1, g1, b1, a1)
    end
    bar.c1 = col1

    local col2 = bar._c2
    if not col2 then
        col2 = CreateColor(r2, g2, b2, a2)
        bar._c2 = col2
    elseif col2.SetRGBA then
        col2:SetRGBA(r2, g2, b2, a2)
    end
    bar._c2 = col2
end


function BarUpdate_API:UpdateOthers(unit)
    local cfg = CFG_API.GetValueConfig(unit)

    local classCFG = cfg.CLASSES[UCB.className]
    classCFG._channelingSpellIDs = {}
    if classCFG and classCFG.channeledSpels then
        for _, spellCfg in pairs(classCFG.channeledSpels) do
            if spellCfg.enable then
                classCFG._channelingSpellIDs[spellCfg.id] = spellCfg.ticks
            end
        end
    end

    -- Predecide tick settings her
    local otherCFG = cfg.otherFeatures
    if not classCFG.useMainSettingsChannel then
        otherCFG._tickWidth  = classCFG.channelTickWidth
        otherCFG._tickColour = classCFG.channelTickColour
        otherCFG._useTickTexture = classCFG.useTickTexture
        otherCFG._tickTexture = classCFG.tickTexture
    else
        otherCFG._tickWidth  = otherCFG.channelTickWidth
        otherCFG._tickColour = otherCFG.channelTickColour
        otherCFG._useTickTexture = otherCFG.useTickTexture
        otherCFG._tickTexture = otherCFG.tickTexture
    end

end


-- !!!!!!!!!!!!!!!!!!!!!!! DYNAMIC UPDATE FUNCTION !!!!!!!!!!!!!!!!!!!!!!!!
function BarUpdate_API:AssignColours(bar, colourMode, castType, colourProgress)
     if castType == "empowered" then
        local tex = bar._tex or bar.status:GetStatusBarTexture()
        bar._tex = tex
        local colour = bar.empoweredColourCurve:Evaluate(colourProgress)
        local r, g, b, a = colour:GetRGBA()
        tex:SetVertexColor(r, g, b, a)
    else
        if colourMode == "ombre" then
            return ombreColours(bar, colourProgress)
        end
    end
end
