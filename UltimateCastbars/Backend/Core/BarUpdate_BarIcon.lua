local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local UIOptions = UCB.UIOptions
local BarUpdate_API = UCB.BarUpdate_API
local OtherFeatures_API = UCB.OtherFeatures_API

local LSM  = UCB.LSM

----------------------------------------HELPER----------------------------------------
local function AnchorWhenReady(frameToAnchor, cfg, opts)
    cfg._anchorCustomError = false
    local maxTries = opts.maxTries or 100 -- ~10s if interval is 0.1
    local interval = opts.interval or 0.1

    local tries = 0
    local function try()
        tries = tries + 1

        local anchor
        if cfg.useDefaultAnchor or not cfg.anchorName or cfg.anchorName == "" then
        anchor = _G[cfg._defaultAnchor]
        else
        anchor = _G[cfg.anchorName]
        if not anchor then anchor = _G[cfg._defaultAnchor] end
        end

        -- If user wants a specific anchor but it isn't available yet, keep waiting
        if (not cfg.useDefaultAnchor) and cfg.anchorName and cfg.anchorName ~= "" and _G[cfg.anchorName] == nil then
        if tries < maxTries then
            C_Timer.After(interval, try)
        else
            -- give up and use UIParent
            cfg._anchorCustomError = true
            anchor = _G[cfg._defaultAnchor]
            frameToAnchor:ClearAllPoints()
            frameToAnchor:SetPoint(cfg.anchorFrom, anchor, cfg.anchorTo, cfg.offsetX, cfg.offsetY or 0)
        end
        return
        end

        frameToAnchor:ClearAllPoints()
        frameToAnchor:SetPoint(cfg.anchorFrom, anchor, cfg.anchorTo, cfg.offsetX or 0, cfg.offsetY or 0)
    end

    try()
end

local function BorderExtents(show, thickness, offL, offR, offT, offB)
  if not show or not thickness then
    return 0, 0, 0, 0
  end
  return
    (thickness + offL),
    (thickness + offR),
    (thickness + offT),
    (thickness + offB)
end

local function IsCorner(a)
  return a == "TOPLEFT" or a == "TOPRIGHT" or a == "BOTTOMLEFT" or a == "BOTTOMRIGHT"
end

local function IsHorizontal(a) -- counts toward WIDTH
  return a == "LEFT" or a == "RIGHT"
end

local function IsVertical(a) -- counts toward HEIGHT
  return a == "TOP" or a == "BOTTOM"
end

local function GetIconSize(cfg, barH, iconAnchor)
  -- Always lock to bar height for TOP/BOTTOM and CORNERS
  if cfg.syncIconBar or iconAnchor == "TOP" or iconAnchor == "BOTTOM"
     or iconAnchor == "TOPLEFT" or iconAnchor == "TOPRIGHT"
     or iconAnchor == "BOTTOMLEFT" or iconAnchor == "BOTTOMRIGHT" then
    return barH
  end
  return cfg.iconWidth or barH
end

local function GetGaps(cfg)
  -- Use iconOffsetX/Y as “gap” between icon and bar, but only when it expands the group.
  -- Negative values can mean overlap; don’t expand group for negative.
  local gx = cfg.iconOffsetX or 0
  local gy = cfg.iconOffsetY or 0
  return math.max(0, gx), math.max(0, gy)
end

local function NN(x) return (x and x > 0) and x or 0 end

local function ComputeSize2(bar, genCfg, styleCfg, syncedW, syncedH)
    genCfg._widthFrameError  = false
    genCfg._heightFrameError = false

    local iconAnchor = genCfg.iconAnchor or "LEFT"
    local showIcon   = (genCfg.showCastIcon == true)

    local incW = genCfg.includeBorderInWidth
    local incH = genCfg.includeBorderInHeight

    -- Defaults are BAR VISUAL sizes (outer) when not synced
    local defaultBarVisW = genCfg.barWidth
    local defaultBarVisH = genCfg.barHeight

    -- Desired GROUP sizes when synced
    local desiredGroupW, desiredGroupH
    if not genCfg.manualWidth then
        if syncedW then desiredGroupW = syncedW + (genCfg.widthOffset or 0)
        else genCfg._widthFrameError = true end
    end
    if not genCfg.manualHeight then
        if syncedH then desiredGroupH = syncedH + (genCfg.heightOffset or 0)
        else genCfg._heightFrameError = true end
    end

    local gapX, gapY = GetGaps(genCfg)

    -- -------------------------
    -- Border pads (outside extents)
    -- -------------------------
    local bL, bR, bT, bB = 0, 0, 0, 0
    if styleCfg and styleCfg.showBorder then
        local l, r, t, b = BorderExtents(
            true,
            styleCfg.borderThickness,
            styleCfg.borderOffsetLeft, styleCfg.borderOffsetRight,
            styleCfg.borderOffsetTop,  styleCfg.borderOffsetBottom
        )
        l, r, t, b = NN(l), NN(r), NN(t), NN(b)
        if incW then bL, bR = l, r end
        if incH then bT, bB = t, b end
    end

    -- We need an INNER bar height to size the icon correctly.
    -- Start with a first-pass barH that does NOT depend on icon size when possible.
    local barH

    if desiredGroupH then
        -- If icon is vertical, addH depends on icon size, which depends on barH.
        -- We'll do a small fixed-point solve below.
        -- For now: assume no icon contribution to height on first pass.
        barH = desiredGroupH - (bT + bB)
    else
        -- Not synced: defaults are VISUAL. Convert to inner.
        barH = defaultBarVisH - (bT + bB)
    end

    if barH < 0 then barH = 0 end

    -- -------------------------
    -- Icon pads (outside extents) and icon size (depends on INNER barH)
    -- -------------------------
    local function computeIconStuff(innerBarH)
        local iconSize = GetIconSize(genCfg, innerBarH, iconAnchor)

        local iL, iR, iT, iB = 0, 0, 0, 0
        if showIcon and styleCfg and styleCfg.showBorderIcon then
            if styleCfg.syncBorderIcon then
                local l, r, t, b = BorderExtents(
                    true,
                    styleCfg.borderThickness,
                    -- IMPORTANT: use ICON offsets here so reducing icon border affects addW/addH
                    styleCfg.borderOffsetLeftIcon,  styleCfg.borderOffsetRightIcon,
                    styleCfg.borderOffsetTopIcon,   styleCfg.borderOffsetBottomIcon
                )
                if incW then iL, iR = l, r end
                if incH then iT, iB = t, b end
            else
                local l, r, t, b = BorderExtents(
                    true,
                    styleCfg.borderThicknessIcon,
                    styleCfg.borderOffsetLeftIcon, styleCfg.borderOffsetRightIcon,
                    styleCfg.borderOffsetTopIcon,  styleCfg.borderOffsetBottomIcon
                )
                l, r, t, b = NN(l), NN(r), NN(t), NN(b)
                if incW then iL, iR = l, r end
                if incH then iT, iB = t, b end
            end
        end

        local iconVisW = iconSize + iL + iR
        local iconVisH = iconSize + iT + iB

        local addW, addH = 0, 0
        if showIcon then
            if IsHorizontal(iconAnchor) then
                addW = iconVisW + gapX
            elseif IsVertical(iconAnchor) then
                addH = iconVisH + gapY
            end
        end

        return iconSize, iL, iR, iT, iB, iconVisW, iconVisH, addW, addH
    end

    -- First pass icon computation based on first barH guess
    local iconSize, iL, iR, iT, iB, iconVisW, iconVisH, addW, addH = computeIconStuff(barH)

    -- If GROUP height is synced and icon is vertical, barH depends on addH which depends on barH.
    -- One refinement pass is usually enough because iconSize is linear in barH.
    if desiredGroupH and showIcon and IsVertical(iconAnchor) then
        local newBarH = desiredGroupH - addH - (bT + bB)
        if newBarH < 0 then newBarH = 0 end
        if newBarH ~= barH then
            barH = newBarH
            iconSize, iL, iR, iT, iB, iconVisW, iconVisH, addW, addH = computeIconStuff(barH)
        end
    else
        -- If group height isn't synced, keep the earlier barH (already derived from defaults)
        -- If icon is vertical, addH does not change barH (defaults define bar visual size)
    end

    -- Store pads for layout step
    genCfg._barPadL,  genCfg._barPadR,  genCfg._barPadT,  genCfg._barPadB  = bL, bR, bT, bB
    genCfg._iconPadL, genCfg._iconPadR, genCfg._iconPadT, genCfg._iconPadB = iL, iR, iT, iB

    -- -------------------------
    -- Solve INNER bar width/height
    -- -------------------------
    local barW

    if desiredGroupW then
        -- synced group width target:
        -- desiredGroupW = (barW + bL+bR) + addW
        barW = desiredGroupW - addW - (bL + bR)
    else
        -- not synced: defaults are BAR VISUAL size targets
        barW = defaultBarVisW - (bL + bR)
    end

    -- barH already solved above (and possibly refined for vertical icon + synced height)

    if desiredGroupH and not (showIcon and IsVertical(iconAnchor)) then
        -- for synced height when icon isn't vertical:
        barH = desiredGroupH - addH - (bT + bB)
    end

    if barW < 0 then barW = 0 end
    if barH < 0 then barH = 0 end

    genCfg.actualBarWidth  = barW
    genCfg.actualBarHeight = barH

    -- Final bar visual sizes
    local barVisW = barW + bL + bR
    local barVisH = barH + bT + bB

    -- Final group sizes
    genCfg.fullBarWidth  = desiredGroupW or (barVisW + addW)
    genCfg.fullBarHeight = desiredGroupH or (barVisH + addH)

    -- Apply
    bar:SetSize(barW, barH)
    bar.status:SetAllPoints(bar)
    bar.group:SetSize(genCfg.fullBarWidth, genCfg.fullBarHeight)
end


local function LayoutIconAndBar2(bar, cfg)
    local group = bar.group
    local iconAnchor = cfg.iconAnchor
    local showIcon = cfg.showCastIcon

    local barW = cfg.actualBarWidth
    local barH = cfg.actualBarHeight

    local iconSize = GetIconSize(cfg, barH, iconAnchor)
    local gapX, gapY = GetGaps(cfg)

    -- NEW: pads computed in ComputeSize
    local bL, bR, bT, bB = cfg._barPadL or 0, cfg._barPadR or 0, cfg._barPadT or 0, cfg._barPadB or 0
    local iL, iR, iT, iB = cfg._iconPadL or 0, cfg._iconPadR or 0, cfg._iconPadT or 0, cfg._iconPadB or 0

    -- Visual sizes (inner + pads)
    local barVisW = barW + bL + bR
    local barVisH = barH + bT + bB
    local iconVisW = iconSize + iL + iR
    local iconVisH = iconSize + iT + iB

    bar:ClearAllPoints()
    bar.iconFrame:ClearAllPoints()

    if not showIcon then
        bar.iconFrame:Hide()
        -- place bar so its OUTSIDE border fits in group
        bar:SetPoint("TOPLEFT", group, "TOPLEFT", bL, -bT)
        bar:SetSize(barW, barH)
        bar.status:SetAllPoints(bar)
        return
    end

    bar.iconFrame:SetSize(iconSize, iconSize)
    bar.iconFrame:Show()

    if iconAnchor == "LEFT" then
        -- icon visual box starts at 0, so inner icon starts at iL
        bar.iconFrame:SetPoint("LEFT", group, "LEFT", iL, 0)
        -- bar visual box starts after iconVisW + gapX, so inner bar starts at that + bL
        bar:SetPoint("LEFT", group, "LEFT", iconVisW + gapX + bL, 0)

    elseif iconAnchor == "RIGHT" then
        bar:SetPoint("LEFT", group, "LEFT", bL, 0)
        bar.iconFrame:SetPoint("RIGHT", group, "RIGHT", -iR, 0)

    elseif iconAnchor == "TOP" then
        bar.iconFrame:SetPoint("TOP", group, "TOP", 0, -iT)
        bar:SetPoint("TOP", group, "TOP", 0, -(iconVisH + gapY) + bT)

    elseif iconAnchor == "BOTTOM" then
        bar:SetPoint("TOP", group, "TOP", 0, -bT)
        bar.iconFrame:SetPoint("BOTTOM", group, "BOTTOM", 0, iB)

    else
        -- corners: keep your existing corner logic EXACTLY (per request)
        bar:SetPoint("TOPLEFT", group, "TOPLEFT", 0, 0)
        if iconAnchor == "TOPLEFT" then
            bar.iconFrame:SetPoint("BOTTOMRIGHT", bar, "TOPLEFT", cfg.iconOffsetX or 0, cfg.iconOffsetY or 0)
        elseif iconAnchor == "TOPRIGHT" then
            bar.iconFrame:SetPoint("BOTTOMLEFT", bar, "TOPRIGHT", cfg.iconOffsetX or 0, cfg.iconOffsetY or 0)
        elseif iconAnchor == "BOTTOMLEFT" then
            bar.iconFrame:SetPoint("TOPRIGHT", bar, "BOTTOMLEFT", cfg.iconOffsetX or 0, cfg.iconOffsetY or 0)
        elseif iconAnchor == "BOTTOMRIGHT" then
            bar.iconFrame:SetPoint("TOPLEFT", bar, "BOTTOMRIGHT", cfg.iconOffsetX or 0, cfg.iconOffsetY or 0)
        end
    end

    bar:SetSize(barW, barH)
    bar.status:SetAllPoints(bar)
end

local function SizeWhenReady(bar, genCfg, styleCfg, opts)
    opts = opts or {}
    local interval = opts.interval or 0.1
    local maxTries = opts.maxTries or 100
    local minW     = opts.minWidth  or 1
    local minH     = opts.minHeight or 1

    -- Apply defaults immediately (manual sizes) so bar isn't broken while waiting
    --ComputeSize(bar, genCfg, nil, nil)
    ComputeSize2(bar, genCfg, styleCfg, nil, nil)

    local needW = (not genCfg.manualWidth)  and genCfg.widthInput  and genCfg.widthInput  ~= ""
    local needH = (not genCfg.manualHeight) and genCfg.heightInput and genCfg.heightInput ~= ""

    if not needW and not needH then
        return
    end

    local tries = 0
    local function try()
        tries = tries + 1

        local syncedW, syncedH

        -- WIDTH source
        if needW then
            local fw = _G[genCfg.widthInput]
            if fw then
                local w
                if fw.GetRect then
                    local _, _, rw = fw:GetRect()
                    w = rw
                end
                if (not w) and fw.GetWidth then
                    w = fw:GetWidth()
                end
                if w and w >= minW then
                    syncedW = w
                end
            end
        end

        -- HEIGHT source
        if needH then
            local fh = _G[genCfg.heightInput]
            if fh then
                local h
                if fh.GetRect then
                    local _, _, _, rh = fh:GetRect()
                    h = rh
                end
                if (not h) and fh.GetHeight then
                    h = fh:GetHeight()
                end
                if h and h >= minH then
                    syncedH = h
                end
            end
        end

        local wReady = (not needW) or (syncedW ~= nil)
        local hReady = (not needH) or (syncedH ~= nil)

        if wReady and hReady then
            -- Ready: compute + apply using synced values
            --ComputeSize(bar, genCfg, syncedW, syncedH)
            ComputeSize2(bar, genCfg, styleCfg, syncedW, syncedH)
            return
        end

        if tries < maxTries then
            C_Timer.After(interval, try)
        else
            -- Timeout: fall back and set errors for whatever wasn't ready
            genCfg._widthFrameError  = needW and (syncedW == nil) or false
            genCfg._heightFrameError = needH and (syncedH == nil) or false
            --ComputeSize(bar, genCfg, syncedW, syncedH)
            ComputeSize2(bar, genCfg, styleCfg, syncedW, syncedH)
        end
    end

    try()
end

----------------------------------------MAIN----------------------------------------
function BarUpdate_API:UpdateBarIcon(unit)
    local bar = UCB.castBar[unit]
    local bar = UCB.castBar[unit]
    local bigCFG = CFG_API.GetValueConfig(unit)
    local genCfg = bigCFG.general
    local styleCfg = bigCFG.style

    -- Determine width and apply
    SizeWhenReady(bar, genCfg, styleCfg, {interval=0.1, maxTries=100, minWidth=1, minHeight = 1})

    -- Apply icon/bar layout (update icon)
    LayoutIconAndBar2(bar, genCfg)

    -- Determine anchor frame and attach
    AnchorWhenReady(bar.group, genCfg, {interval=0.1, maxTries=100})
end