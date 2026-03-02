local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.tags = UCB.tags or {}

local GetCFG = UCB.GetValueConfig
local BarUpdate_API = UCB.BarUpdate_API

----------------------------------------HELPER----------------------------------------
local function SetTexCoord_Default(tex)
    tex:SetTexCoord(0, 1, 0, 1)
end

-- Rotate 90° clockwise: pattern runs TOP->BOTTOM
local function SetTexCoord_Rotate90CW(tex)
    tex:SetTexCoord(
        1, 0,  -- UL
        1, 1,  -- LL
        0, 0,  -- UR
        0, 1   -- LR
    )
end

-- Rotate 90° counter-clockwise: pattern runs BOTTOM->TOP
local function SetTexCoord_Rotate90CCW(tex)
    tex:SetTexCoord(
        0, 1,  -- UL
        0, 0,  -- LL
        1, 1,  -- UR
        1, 0   -- LR
    )
end

-- Flip horizontally: makes bottom appear right->left
local function SetTexCoord_FlipH(tex)
    tex:SetTexCoord(1, 0, 0, 1)
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

function BarUpdate_API:ApplyRectBorder(holder, key, target, texture, colour, baseThickness, offsets, frameLevelDelta, makeCorners)
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

    if tT > 0 then SetTexCoord_Default(f.top) end
    if tB > 0 then SetTexCoord_FlipH(f.bottom) end
    if tL > 0 then SetTexCoord_Rotate90CCW(f.left) end
    if tR > 0 then SetTexCoord_Rotate90CW(f.right) end

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

    -- TOP
    if tT > 0 then
        f.top:ClearAllPoints()

        if makeCorners then
            -- extend to cover corner squares (current behaviour)
            f.top:SetPoint("BOTTOMLEFT",  target, "TOPLEFT",  -tL, 0)
            f.top:SetPoint("BOTTOMRIGHT", target, "TOPRIGHT",  tR, 0)
        else
            -- no corners: stop at target width, leaving gaps
            f.top:SetPoint("BOTTOMLEFT",  target, "TOPLEFT",  0, 0)
            f.top:SetPoint("BOTTOMRIGHT", target, "TOPRIGHT", 0, 0)
        end

        f.top:SetHeight(tT)
    end

    -- BOTTOM
    if tB > 0 then
        f.bottom:ClearAllPoints()

        if makeCorners then
            -- extend to cover corner squares (current behaviour)
            f.bottom:SetPoint("TOPLEFT",  target, "BOTTOMLEFT",  -tL, 0)
            f.bottom:SetPoint("TOPRIGHT", target, "BOTTOMRIGHT",  tR, 0)
        else
            -- no corners: stop at target width, leaving gaps
            f.bottom:SetPoint("TOPLEFT",  target, "BOTTOMLEFT",  0, 0)
            f.bottom:SetPoint("TOPRIGHT", target, "BOTTOMRIGHT", 0, 0)
        end

        f.bottom:SetHeight(tB)
    end

    f:Show()
end

function BarUpdate_API:HideRectBorder(holder, key)
    local f = holder[key]
    if f then f:Hide() end
end

local function UpdateBorderBar(unit, cfg)
    local bar = UCB.castBar[unit]
    if not bar then return end

    if not cfg.showBorder then
        BarUpdate_API:HideRectBorder(bar, "_rectBorder")
        return
    end

    BarUpdate_API:ApplyRectBorder(
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
        -1,
        cfg.borderFillCorners
    )
end

local function UpdateIconBorder(unit, cfg)
    local bar = UCB.castBar[unit]
    if not bar or not bar.iconFrame then return end

    if not cfg.showBorderIcon then
        BarUpdate_API:HideRectBorder(bar.iconFrame, "_rectBorder")
        return
    end

    local texture, colour, thickness, offs, fillCorners
    if cfg.syncBorderIcon then
        texture   = cfg.textureBorder
        colour    = cfg.borderColour
        thickness = cfg.borderThickness
        fillCorners = cfg.borderFillCorners
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
        fillCorners = cfg.borderFillCornersIcon
        offs = {
            left   = cfg.borderOffsetLeftIcon,
            right  = cfg.borderOffsetRightIcon,
            top    = cfg.borderOffsetTopIcon,
            bottom = cfg.borderOffsetBottomIcon,
        }
    end

    BarUpdate_API:ApplyRectBorder(
        bar.iconFrame,
        "_rectBorder",
        bar.iconFrame,
        texture,
        colour,
        thickness,
        offs,
        -3,
        fillCorners
    )
end


local function EnsureEnemyColourCached(unit, bar, styleCfg)
    if unit == "player" then return end
    local rgba = styleCfg and styleCfg.enemyColour
    if not rgba then return end

    -- rebuild only if the table identity changes (cheap)
    if not bar._enemyColour or bar._enemyColour._src ~= rgba then
        bar._enemyColour = {
            _src = rgba,
            RGBA = rgba,
            COL  = CreateColor(rgba.r, rgba.g, rgba.b, rgba.a),
        }
    end
end

local function BuildCandidateFromStyle(unit, bar, styleCfg)
    if not styleCfg then return nil end

    local cand = {}

    -- Background
    cand.bgColourMode = styleCfg.bgColourMode
    cand.bgAlpha = {use = styleCfg.bgUseCustomAlpha, alpha = styleCfg.bgAlpha}
    cand.bgEnemyColour = styleCfg.bgEnemyColour

    if styleCfg.colourMode == "class" then
        cand.colourType = "class"
        cand.mode = "single"

        if unit == "player" then
            cand.rgba1 = UCB.classColour.RGBA
            cand.col1  = UCB.classColour.COL
        else
            EnsureEnemyColourCached(unit, bar, styleCfg)
            -- If you WANT class-per-unit for nameplates etc, don’t set rgba1/col1
            -- and let your SemiColourUpdate do UnitClass/UnitIsPlayer work.
            -- If you want cheaper updates, set these and later simplify SemiColourUpdate.
            cand.rgba1 = bar._enemyColour and bar._enemyColour.RGBA
            cand.col1  = bar._enemyColour and bar._enemyColour.COL
        end
        return cand
    end

    -- custom
    cand.colourType = "custom"
    if styleCfg.gradientEnable then
        cand.mode  = "gradient"
        cand.rgba1 = styleCfg.customColour
        cand.rgba2 = styleCfg.customColour2
    else
        cand.mode  = "single"
        cand.rgba1 = styleCfg.customColour
    end

    return cand
end

----------------------------------------MAIN----------------------------------------
function BarUpdate_API:UpdateStyle(unit, force, type, customStyle)
    local bar = UCB.castBar[unit]
    local cfg

    if not customStyle then
        if not type then type = "general" end

        if bar._lastStyleType == type and not force then return end
        bar._lastStyleType = type

         cfg = GetCFG(unit, "styleCastType")[type]
    else
        if bar._lastStyleType == type and not force then return end
        bar._lastStyleType = type

        cfg = customStyle
    end
    
    -- Bar style
    bar.status:SetStatusBarTexture(cfg.texture)

    -- Mirror style
    bar.mirrorStatus.tex:SetTexture(cfg.texture)

    -- Background
    if cfg.showBackground then
        bar.bg:SetTexture(cfg.textureBack)

        local c
        if cfg.bgColourMode == "custom" then
            c = cfg.bgColour
        else
            c = UCB.classColour.RGBA
        end

        if cfg.bgUseCustomAlpha then
            bar.bg:SetVertexColor(c.r, c.g, c.b, cfg.bgAlpha)
        else
            bar.bg:SetVertexColor(c.r, c.g, c.b, c.a)
        end
        bar.bg:Show()
    else
        bar.bg:Hide()
    end
    --Bar border
    UpdateBorderBar(unit, cfg)
    -- Icon border
    UpdateIconBorder(unit, cfg)
    -- Apply colour 
    BarUpdate_API:ApplyColour(bar, type)
end

-- =========================
-- 3) store candidates on bar + retrieve via table
-- =========================
function BarUpdate_API:BuildColourCandidates(unit)
    local bar = UCB.castBar[unit]
    if not bar then return end

    local typeList = { "general", "normal", "channel", "empowered" }
    local typeListPlayer = {}
    if unit == "player" then
        local classCFG = GetCFG(unit).CLASSES[UCB.className]
        local spellStyling = classCFG and classCFG.spellStyling
        for _, spellStyle in ipairs(spellStyling.styleSpells) do
            if spellStyle.enable and spellStyle.id then
                typeListPlayer[spellStyle.id] = spellStyle.style
            end
        end
    end

    local store = bar._colourCandidates
    if not store then
        store = {}
        bar._colourCandidates = store
    end

    -- optional: clear keys not in the list? (skip for speed; just overwrite what you build)
    local styleGrpCFG = GetCFG(unit, "styleCastType")
    for _, typeKey in ipairs(typeList or {}) do
        local styleCfg = styleGrpCFG and styleGrpCFG[typeKey]
        store[typeKey] = BuildCandidateFromStyle(unit, bar, styleCfg)
    end

    if unit == "player" then
        for spellID, style in pairs(typeListPlayer) do
            store[spellID] = BuildCandidateFromStyle(unit, bar, style)
        end
    end

end

-- =========================
-- 4) apply chosen candidate to bar fields SemiColourUpdate uses
-- =========================
local function EnsureBarColorObjects(bar)
    if not bar._c1 then bar._c1 = CreateColor(1,1,1,1) end
    if not bar._c2 then bar._c2 = CreateColor(1,1,1,1) end
end

function BarUpdate_API:ApplyColour(bar, typeKey)
    local cand = bar._colourCandidates[typeKey]
    if not bar or not cand then return end

    bar._colourMode = cand.mode
    bar._colourTywe = cand.colourType
    bar._bgColourMode = cand.bgColourMode
    bar._bgAlpha = cand.bgAlpha
    bar._bgEnemyColour = cand.bgEnemyColour

    EnsureBarColorObjects(bar)

    if cand.mode == "single" then
        local c = cand.rgba1
        if not c then return end

        bar._r, bar._g, bar._b, bar._a = c.r, c.g, c.b, c.a

        if cand.col1 then
            bar._c1 = cand.col1
        else
            bar._c1:SetRGBA(c.r, c.g, c.b, c.a)
        end
        return
    end

    -- gradient
    local c1, c2 = cand.rgba1, cand.rgba2
    if not c1 or not c2 then return end

    bar._r1, bar._g1, bar._b1, bar._a1 = c1.r, c1.g, c1.b, c1.a
    bar._r2, bar._g2, bar._b2, bar._a2 = c2.r, c2.g, c2.b, c2.a

    if cand.col1 then bar._c1 = cand.col1 else bar._c1:SetRGBA(c1.r, c1.g, c1.b, c1.a) end
    if cand.col2 then bar._c2 = cand.col2 else bar._c2:SetRGBA(c2.r, c2.g, c2.b, c2.a) end
end