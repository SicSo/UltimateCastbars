local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.FrameStyle_API = UCB.FrameStyle_API or {}
UCB.tags = UCB.tags or {}

local GetCFG = UCB.GetValueConfig
local BarUpdate_API = UCB.BarUpdate_API
local FrameStyle_API = UCB.FrameStyle_API

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

local function SafeNumber(v, fallback)
    if type(v) == "number" then return v end
    return fallback or 0
end

local function CopyColour(c)
    if not c then return nil end
    return {
        r = c.r or 1,
        g = c.g or 1,
        b = c.b or 1,
        a = c.a or 1,
    }
end

local function EnsureTexture(frame, key, layer, subLevel)
    frame[key] = frame[key] or frame:CreateTexture(nil, layer or "BACKGROUND", nil, subLevel or 0)
    return frame[key]
end

local function ResolveColourWithAlpha(colour, useCustomAlpha, alphaOverride)
    if not colour then
        return { r = 1, g = 1, b = 1, a = 1 }
    end

    return {
        r = colour.r or 1,
        g = colour.g or 1,
        b = colour.b or 1,
        a = useCustomAlpha and (alphaOverride or 1) or (colour.a or 1),
    }
end

local function GetBorderOffsets(cfg, suffix)
    suffix = suffix or ""
    return {
        left   = SafeNumber(cfg["borderOffsetLeft" .. suffix], 0),
        right  = SafeNumber(cfg["borderOffsetRight" .. suffix], 0),
        top    = SafeNumber(cfg["borderOffsetTop" .. suffix], 0),
        bottom = SafeNumber(cfg["borderOffsetBottom" .. suffix], 0),
    }
end

local function ResolveBackgroundBaseColour(unit, styleCfg)
    if not styleCfg then return nil end

    if styleCfg.bgColourMode == "custom" then
        return styleCfg.bgColour
    end

    if styleCfg.bgColourMode == "enemy" and not UCB:IsPlayer(unit) and styleCfg.bgEnemyColour then
        return styleCfg.bgEnemyColour
    end

    return UCB.charColour and UCB.charColour.RGBA or styleCfg.bgColour
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

----------------------------------------GENERIC FRAME STYLE API----------------------------------------
function FrameStyle_API:GetFrameStyleSettings(unit, cfg, opts)
    if not cfg then return nil end
    opts = opts or {}

    local borderSuffix = opts.borderSuffix or ""
    local baseBgColour = opts.bgColour or ResolveBackgroundBaseColour(unit, cfg)

    return {
        background = {
            show = cfg.showBackground == true,
            texture = cfg.textureBack,
            colourMode = cfg.bgColourMode,
            colour = CopyColour(baseBgColour),
            useCustomAlpha = cfg.bgUseCustomAlpha == true,
            alpha = SafeNumber(cfg.bgAlpha, 1),
        },
        border = {
            show = cfg.showBorder == true,
            texture = cfg.textureBorder,
            colour = CopyColour(cfg.borderColour),
            thickness = SafeNumber(cfg.borderThickness, 0),
            fillCorners = cfg.borderFillCorners == true,
            offsets = GetBorderOffsets(cfg, borderSuffix),
        },
    }
end

function FrameStyle_API:GetBackgroundAndBorderSettings(unit, cfg, opts)
    return self:GetFrameStyleSettings(unit, cfg, opts)
end

function FrameStyle_API:ApplyBackground(targetFrame, settings, bgTarget, texKey)
    if not targetFrame or not settings or not settings.background then return end

    local bgCfg = settings.background
    local tex = EnsureTexture(targetFrame, texKey or "_styledBackground", "BACKGROUND", 0)
    bgTarget = bgTarget or targetFrame

    tex:ClearAllPoints()
    tex:SetAllPoints(bgTarget)

    if not bgCfg.show then
        tex:Hide()
        return tex
    end

    if bgCfg.texture then
        tex:SetTexture(bgCfg.texture)
    end

    local c = ResolveColourWithAlpha(bgCfg.colour, bgCfg.useCustomAlpha, bgCfg.alpha)
    tex:SetVertexColor(c.r, c.g, c.b, c.a)
    tex:Show()

    return tex
end

function FrameStyle_API:ApplyBorder(holder, settings, target, key, frameLevelDelta)
    if not holder or not settings or not settings.border then return end

    local borderCfg = settings.border
    target = target or holder
    key = key or "_rectBorder"

    if not borderCfg.show then
        BarUpdate_API:HideRectBorder(holder, key)
        return
    end

    BarUpdate_API:ApplyRectBorder(
        holder,
        key,
        target,
        borderCfg.texture,
        borderCfg.colour,
        borderCfg.thickness,
        borderCfg.offsets,
        frameLevelDelta or 1,
        borderCfg.fillCorners
    )
end

function FrameStyle_API:ApplyFrameStyle(targetFrame, unit, cfg, opts)
    if not targetFrame or not cfg then return end
    opts = opts or {}

    local settings = self:GetFrameStyleSettings(unit, cfg, opts)
    if not settings then return end

    self:ApplyBackground(
        targetFrame,
        settings,
        opts.backgroundTarget,
        opts.backgroundKey
    )

    self:ApplyBorder(
        opts.borderHolder or targetFrame,
        settings,
        opts.borderTarget or targetFrame,
        opts.borderKey,
        opts.borderFrameLevelDelta
    )

    return settings
end

----------------------------------------BORDER HELPERS----------------------------------------
function BarUpdate_API:ApplyRectBorder(holder, key, target, texture, colour, baseThickness, offsets, frameLevelDelta, makeCorners)
    local f = EnsureRectBorder(holder, key, frameLevelDelta)
    offsets = offsets or { left = 0, right = 0, top = 0, bottom = 0 }

    local t = baseThickness or 0
    local tL = ClampNonNeg(t + (offsets.left or 0))
    local tR = ClampNonNeg(t + (offsets.right or 0))
    local tT = ClampNonNeg(t + (offsets.top or 0))
    local tB = ClampNonNeg(t + (offsets.bottom or 0))

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

    if tL > 0 then
        f.left:ClearAllPoints()
        f.left:SetPoint("TOPRIGHT", target, "TOPLEFT", 0, 0)
        f.left:SetPoint("BOTTOMRIGHT", target, "BOTTOMLEFT", 0, 0)
        f.left:SetWidth(tL)
    end

    if tR > 0 then
        f.right:ClearAllPoints()
        f.right:SetPoint("TOPLEFT", target, "TOPRIGHT", 0, 0)
        f.right:SetPoint("BOTTOMLEFT", target, "BOTTOMRIGHT", 0, 0)
        f.right:SetWidth(tR)
    end

    if tT > 0 then
        f.top:ClearAllPoints()
        if makeCorners then
            f.top:SetPoint("BOTTOMLEFT", target, "TOPLEFT", -tL, 0)
            f.top:SetPoint("BOTTOMRIGHT", target, "TOPRIGHT", tR, 0)
        else
            f.top:SetPoint("BOTTOMLEFT", target, "TOPLEFT", 0, 0)
            f.top:SetPoint("BOTTOMRIGHT", target, "TOPRIGHT", 0, 0)
        end
        f.top:SetHeight(tT)
    end

    if tB > 0 then
        f.bottom:ClearAllPoints()
        if makeCorners then
            f.bottom:SetPoint("TOPLEFT", target, "BOTTOMLEFT", -tL, 0)
            f.bottom:SetPoint("TOPRIGHT", target, "BOTTOMRIGHT", tR, 0)
        else
            f.bottom:SetPoint("TOPLEFT", target, "BOTTOMLEFT", 0, 0)
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

local function UpdateBorderBar(unit, cfg, bar)
    if not bar then bar = UCB.castBar[unit] end
    if not bar then return end

    local settings = FrameStyle_API:GetFrameStyleSettings(unit, cfg)
    FrameStyle_API:ApplyBorder(bar, settings, bar, "_rectBorder", -1)
end

local function UpdateIconBorder(unit, cfg)
    local bar = UCB.castBar[unit]
    if not bar or not bar.iconFrame then return end

    local settings
    if cfg.syncBorderIcon then
        settings = FrameStyle_API:GetFrameStyleSettings(unit, cfg, { borderSuffix = "Icon" })
    else
        settings = {
            border = {
                show = cfg.showBorderIcon == true,
                texture = cfg.textureBorderIcon,
                colour = CopyColour(cfg.borderColourIcon),
                thickness = SafeNumber(cfg.borderThicknessIcon, 0),
                fillCorners = cfg.borderFillCornersIcon == true,
                offsets = GetBorderOffsets(cfg, "Icon"),
            },
        }
    end

    FrameStyle_API:ApplyBorder(bar.iconFrame, settings, bar.iconFrame, "_rectBorder", -3)
end

local function EnsureEnemyColourCached(unit, bar, styleCfg)
    if UCB:IsPlayer(unit) then return end
    local rgba = styleCfg and styleCfg.enemyColour
    if not rgba then return end

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

    cand.bgColourMode = styleCfg.bgColourMode
    cand.bgAlpha = { use = styleCfg.bgUseCustomAlpha, alpha = styleCfg.bgAlpha }
    cand.bgEnemyColour = styleCfg.bgEnemyColour

    if styleCfg.colourMode == "custom" then
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

    if styleCfg.colourMode == "class" then
        cand.colourType = "class"
        cand.mode = "single"

        if UCB:IsPlayer(unit) then
            cand.rgba1 = UCB.charColour.RGBA
            cand.col1  = UCB.charColour.COL
        else
            EnsureEnemyColourCached(unit, bar, styleCfg)
            cand.rgba1 = bar._enemyColour and bar._enemyColour.RGBA
            cand.col1  = bar._enemyColour and bar._enemyColour.COL
        end
        return cand
    end

    cand.colourType = "ombre"
    cand.mode = "ombre"

    return cand
end

local function UpdateSpark(bar, cfg)
    bar.flags.effects.spark = true
    local overlay = bar.frames.overlay
    local sparkCFG = cfg.effects.spark

    local spark = bar.effects.spark
    if not spark then
        spark = overlay:CreateTexture(nil, "OVERLAY")
        bar.effects.spark = spark
        bar.effects.sparkDriver = CreateFrame("StatusBar", nil, bar)
        local driver = bar.effects.sparkDriver
        driver:SetAllPoints(bar.status)
        driver:Hide()
        driver:SetAlpha(0)
        driver:SetStatusBarTexture(bar.status:GetStatusBarTexture():GetTexture())
    end

    spark:SetTexture(sparkCFG.texture)
    spark:SetBlendMode(sparkCFG.blendMode)

    local c = sparkCFG.colour
    spark:SetVertexColor(c.r, c.g, c.b, c.a)

    spark:SetWidth(sparkCFG.width)
    spark:SetHeight(bar:GetHeight() * sparkCFG.heightMult)

    spark:Show()
end

local function GetPermanentBackBorderInsets(permBGCfg, styleCfg)
    if not permBGCfg or not styleCfg or not styleCfg.showBorder then
        return 0, 0, 0, 0
    end

    local t = styleCfg.borderThickness or 0

    local left   = math.max(0, t + (styleCfg.borderOffsetLeft   or 0))
    local right  = math.max(0, t + (styleCfg.borderOffsetRight  or 0))
    local top    = math.max(0, t + (styleCfg.borderOffsetTop    or 0))
    local bottom = math.max(0, t + (styleCfg.borderOffsetBottom or 0))

    if not permBGCfg.includeBorderInWidth then
        left, right = 0, 0
    end
    if not permBGCfg.includeBorderInHeight then
        top, bottom = 0, 0
    end

    return left, right, top, bottom
end

----------------------------------------MAIN----------------------------------------
function BarUpdate_API:UpdateStylePermanentBack(unit)
    local bar = UCB.castBar[unit]
    if not bar or not bar.background_frame then return end

    local holder = bar.background_frame
    local cfgRoot = GetCFG(unit)
    if not cfgRoot or not cfgRoot.otherFeatures or not cfgRoot.otherFeatures.permanentBackgrodund then
        holder:Hide()
        return
    end

    local permBGCfg = cfgRoot.otherFeatures.permanentBackgrodund
    local styleCfg = permBGCfg.style

    if not permBGCfg.enable or not styleCfg then
        holder:Hide()
        return
    end

    local settings = FrameStyle_API:GetFrameStyleSettings(unit, styleCfg)
    if not settings then
        holder:Hide()
        return
    end

    holder:Show()

    -- shrink holder so the OUTSIDE border still fits inside the wanted final size
    local left, right, top, bottom = GetPermanentBackBorderInsets(permBGCfg, styleCfg)

    local base = bar.group

    if base then
        holder:ClearAllPoints()
        holder:SetPoint("TOPLEFT", base, "TOPLEFT", left, -top)
        holder:SetPoint("BOTTOMRIGHT", base, "BOTTOMRIGHT", -right, bottom)
    end

    -- Background
    if holder.bg and settings.background then
        if settings.background.show then
            if settings.background.texture then
                holder.bg:SetTexture(settings.background.texture)
            end

            local c = ResolveColourWithAlpha(
                settings.background.colour,
                settings.background.useCustomAlpha,
                settings.background.alpha
            )

            holder.bg:SetVertexColor(c.r, c.g, c.b, c.a)
            holder.bg:Show()
        else
            holder.bg:Hide()
        end
    end

    -- Border
    if settings.border and settings.border.show then
        FrameStyle_API:ApplyBorder(
            holder,
            settings,
            holder,
            "_rectBorder",
            1
        )
    else
        BarUpdate_API:HideRectBorder(holder, "_rectBorder")
    end
end

function BarUpdate_API:UpdateStyle(unit, force, type, customStyle)
    local bar = UCB.castBar[unit]
    if not bar then return end

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

    if not cfg then return end

    bar.status:SetStatusBarTexture(cfg.texture)
    bar.mirrorStatus.tex:SetTexture(cfg.texture)

    local bgSettings = FrameStyle_API:GetFrameStyleSettings(unit, cfg)

    if bgSettings and bgSettings.background and bgSettings.background.show then
        bar.bg:SetTexture(bgSettings.background.texture)
        --bar.background_frame.bg:SetTexture(bgSettings.background.texture)

        local c = ResolveColourWithAlpha(
            bgSettings.background.colour,
            bgSettings.background.useCustomAlpha,
            bgSettings.background.alpha
        )

        bar.bg:SetVertexColor(c.r, c.g, c.b, c.a)
        --bar.background_frame.bg:SetVertexColor(c.r, c.g, c.b, c.a)
        bar.bg:Show()
    else
        bar.bg:Hide()
        --bar.background_frame.bg:Hide()
    end

    if cfg.effects.spark.enable then
        UpdateSpark(bar, cfg)
    elseif bar.effects.spark then
        bar.effects.spark:Hide()
        bar.flags.effects.spark = false
    end

    UpdateBorderBar(unit, cfg)
    UpdateIconBorder(unit, cfg)
    BarUpdate_API:ApplyColour(bar, type)
end

function BarUpdate_API:BuildColourCandidates(unit)
    local bar = UCB.castBar[unit]
    if not bar then return end

    local typeList = { "general", "normal", "channel", "empowered" }
    local typeListPlayer = {}
    if UCB:IsPlayer(unit) then
        local classCFG = GetCFG(unit).CLASSES[UCB.className]
        local spellStyling = classCFG and classCFG.spellStyling
        if spellStyling and spellStyling.styleSpells then
            for _, spellStyle in ipairs(spellStyling.styleSpells) do
                if spellStyle.enable and spellStyle.id then
                    typeListPlayer[spellStyle.id] = spellStyle.style
                end
            end
        end
    end

    local store = bar._colourCandidates
    if not store then
        store = {}
        bar._colourCandidates = store
    end

    local styleGrpCFG = GetCFG(unit, "styleCastType")
    for _, typeKey in ipairs(typeList) do
        local styleCfg = styleGrpCFG and styleGrpCFG[typeKey]
        store[typeKey] = BuildCandidateFromStyle(unit, bar, styleCfg)
    end

    if UCB:IsPlayer(unit) then
        for spellID, style in pairs(typeListPlayer) do
            store[spellID] = BuildCandidateFromStyle(unit, bar, style)
        end
    end
end

local function EnsureBarColorObjects(bar)
    if not bar._c1 then bar._c1 = CreateColor(1, 1, 1, 1) end
    if not bar._c2 then bar._c2 = CreateColor(1, 1, 1, 1) end
end

function BarUpdate_API:ApplyColour(bar, typeKey)
    if not bar then return end
    local cand = bar._colourCandidates and bar._colourCandidates[typeKey]
    if not cand then return end

    bar._colourMode = cand.mode
    bar._colourType = cand.colourType
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

    local c1, c2 = cand.rgba1, cand.rgba2
    if not c1 or not c2 then return end

    bar._r1, bar._g1, bar._b1, bar._a1 = c1.r, c1.g, c1.b, c1.a
    bar._r2, bar._g2, bar._b2, bar._a2 = c2.r, c2.g, c2.b, c2.a

    if cand.col1 then bar._c1 = cand.col1 else bar._c1:SetRGBA(c1.r, c1.g, c1.b, c1.a) end
    if cand.col2 then bar._c2 = cand.col2 else bar._c2:SetRGBA(c2.r, c2.g, c2.b, c2.a) end
end