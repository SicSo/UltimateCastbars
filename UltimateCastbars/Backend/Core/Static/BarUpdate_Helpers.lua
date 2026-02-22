local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}
UCB.tags = UCB.tags or {}
UCB.Text_API = UCB.Text_API or {}

local GetCFG = UCB.GetValueConfig
local BarUpdate_API = UCB.BarUpdate_API
local OtherFeatures_API = UCB.OtherFeatures_API
local Text_API = UCB.Text_API

local LSM  = UCB.LSM

----------------------------------------HELPER----------------------------------------
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

local function UpdateBorderBar(unit)
    local bar = UCB.castBar[unit]
    local cfg = GetCFG(unit, "style")
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

local function UpdateIconBorder(unit)
    local bar = UCB.castBar[unit]
    local cfg = GetCFG(unit, "style")
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

local function UpdateRectBorderFromCfg(holder, target, holderKey, cfgBlock, frameLevelDelta)
    if not holder or not target or not cfgBlock then return end

    if not cfgBlock.show then
        HideRectBorder(holder, holderKey)
        return
    end

    ApplyRectBorder(
        holder,
        holderKey,
        target,
        cfgBlock.texture,
        cfgBlock.colour,
        cfgBlock.thickness,
        cfgBlock.offsets,
        frameLevelDelta or -1
    )
end

local function UpdateUninterruptibleBorder(unit)
    local bar = UCB.castBar[unit]
    if not bar then return end

    local cfg = GetCFG(unit, "uninterruptible")
    local unint_frame = bar.frames.unInterrupted
    if not unint_frame then return end

    -- If you want border to be conditional on showUninterruptible too:
    local show = cfg.showUninterruptibleBorder

    local borderBlock = {
        show      = show,
        texture   = cfg.textureBorder,
        colour    = cfg.borderColour,
        thickness = cfg.borderThickness,
        offsets   = {
            left   = cfg.borderOffsetLeft,
            right  = cfg.borderOffsetRight,
            top    = cfg.borderOffsetTop,
            bottom = cfg.borderOffsetBottom,
        },
    }

    -- Use the same holder/target = unint_frame so it borders that region.
    -- Frame level: pick something that renders above background, below text.
    -- unInterruptedFrame level is set in UpdateVisibility; border frameLevelDelta can be small negative/positive.
    UpdateRectBorderFromCfg(unint_frame, unint_frame, "_rectBorder", borderBlock, -1)

    local mirror_frame = bar.mirror_frames.unInterruptedMirrorFrame
    -- OPTIONAL: mirror border (if you want the mirrored uninterruptible to also have border)
    if mirror_frame and cfg.showUninterruptibleMirrorBorder then
        local mirrorShow = cfg.showUninterruptibleBorder
        local mirrorBlock = {
            show      = mirrorShow,
            texture   = cfg.textureBorder,
            colour    = cfg.borderColour,
            thickness = cfg.borderThickness,
            offsets   = {
                left   = cfg.borderOffsetLeft,
                right  = cfg.borderOffsetRight,
                top    = cfg.borderOffsetTop,
                bottom = cfg.borderOffsetBottom,
            },
        }
        UpdateRectBorderFromCfg(mirror_frame, mirror_frame, "_rectBorder", mirrorBlock, -1)
    elseif mirror_frame then
        HideRectBorder(mirror_frame, "_rectBorder")
    end
end

local function UpdateUninterruptibleIconBorder(unit)
    local bar = UCB.castBar[unit]
    if not bar or not bar.unintIconFrame then return end

    local cfg = GetCFG(unit, "uninterruptible")

    -- Gate: only show when uninterruptible feature is enabled (and optionally when currently shown)
    local show = cfg.showUninterruptibleBorderIcon and cfg.showUninterruptibleBorder

    local borderBlock
    if cfg.syncBorderIcon then
        borderBlock = {
            show      = show,
            texture   = cfg.textureBorder,   -- or reuse same texture as bar border
            colour    = cfg.borderColour,
            thickness = cfg.borderThickness,
            offsets   = {
                left   = cfg.borderOffsetLeftIcon,
                right  = cfg.borderOffsetRightIcon,
                top    = cfg.borderOffsetTopIcon,
                bottom = cfg.borderOffsetBottomIcon,
            },
        }
    else
        borderBlock = {
            show      = show,
            texture   = cfg.textureBorderIcon,
            colour    = cfg.borderColourIcon,
            thickness = cfg.borderThicknessIcon,
            offsets   = {
                left   = cfg.borderOffsetLeftIcon,
                right  = cfg.borderOffsetRightIcon,
                top    = cfg.borderOffsetTopIcon,
                bottom = cfg.borderOffsetBottomIcon,
            },
        }
    end

    -- icon border frame level often needs to be higher than bar border
    UpdateRectBorderFromCfg(bar.unintIconFrame, bar.unintIconFrame, "_rectBorderUnintIcon", borderBlock, -3)
end

----------------------------------------MAIN----------------------------------------
function BarUpdate_API:UpdateText(unit)
    local bar = UCB.castBar[unit]
    local cfg = GetCFG(unit, "text")
    local generalCFG = cfg.generalValues
    local generalFont, generalFontSize, generalColour = generalCFG.font, generalCFG.textSize, generalCFG.colour
    local generalOutlineTags, generalShadow = Text_API:OutlineFlags(generalCFG.outline)
    local generalShadowOffset, generalShadowColour = generalCFG.shadowOffset, generalCFG.shadowColour
    local globalFont = LSM:GetDefault("font") or GameFontHighlightSmall:GetFont()

    for k, v in pairs(bar.texts) do
        v:Hide()
    end

    local tagGroups = {
        static = {},
        semiDynamic = {},
        dynamic = {},
        unk = {},
        cancelled = {},
        interrupted = {},
    }
    UCB.tags.tagGroups[unit] = tagGroups

    local textFrame = bar.frames.text
    for key, tagOptions in pairs(cfg.textList) do
        if tagOptions.show then
            if not bar.texts[key] then
                bar.texts[key] = textFrame:CreateFontString(nil, tagOptions.frameStrata, "GameFontHighlightSmall")
            end
            UCB.tags:updateTagText(key, tagOptions, unit)

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
            fs:SetPoint(tagOptions.anchorFrom, textFrame, tagOptions.anchorTo, tagOptions.textOffsetX, tagOptions.textOffsetY)
            fs:SetFont(usedFont, usedFontSize, unpack(usedOutline))
            if usedShadow then
                fs:SetShadowColor(usedShadowColour.r, usedShadowColour.g, usedShadowColour.b, usedShadowColour.a)
                fs:SetShadowOffset(usedShadowOffset, -usedShadowOffset)
            else
                fs:SetShadowOffset(0, 0)
            end
            fs:SetTextColor(usedColour.r, usedColour.g, usedColour.b, usedColour.a)
            fs:Show()
            tagOptions._compiled = UCB.tags:compileFormula(tagOptions._formula, tagOptions._limits, tagOptions.mainType)
        elseif bar.texts[key] then
            bar.texts[key]:Hide()
        end
    end

    -- static update (should use compiled ops inside setTextSameState)
    UCB.tags:setTextSameState(bar, "static", unit)
end

function BarUpdate_API:UpdateVisibility(unit)
    local bar = UCB.castBar[unit]
    local cfg = GetCFG(unit, "visibility")
    bar:SetFrameStrata(cfg.frameStrata)
    bar:SetFrameLevel(cfg.frameLevel)
    bar.iconFrame:SetFrameStrata(cfg.frameStrata)
    bar.iconFrame:SetFrameLevel(cfg.frameLevel + 1)  -- icon above bar

    bar.frames.underlay:SetFrameLevel(cfg.frameLevel + 1) -- underlay below all
    bar.status:SetFrameLevel(cfg.frameLevel + 2)
    bar.mirrorStatus:SetFrameLevel(cfg.frameLevel + 2) -- same as status, but only shown when mirrored
    bar.frames.untilKick:SetFrameLevel(cfg.frameLevel + 3)
    bar.mirror_frames.untilKick:SetFrameLevel(cfg.frameLevel + 3)
    bar.frames.unInterrupted:SetFrameLevel(cfg.frameLevel + 4) -- same as status, but only shown when uninterruptible
    bar.mirror_frames.unInterrupted:SetFrameLevel(cfg.frameLevel + 4) -- same as status, but only shown when uninterruptible and mirrored
    bar.frames.overlay:SetFrameLevel(cfg.frameLevel + 7) -- below text
    bar.frames.cancelled:SetFrameLevel(cfg.frameLevel + 8) -- above overlay,
    bar.frames.interrupted:SetFrameLevel(cfg.frameLevel + 9) -- above overlay, below text
    bar.frames.text:SetFrameLevel(cfg.frameLevel + 10) -- text above all
end

function BarUpdate_API:UpdateUnkickable(unit)
    local bar = UCB.castBar[unit]
    if not bar then return end

    local cfg = GetCFG(unit, "uninterruptible")

    -- Hide helper bar textures
    local posTex = bar.interruptPositioner:GetStatusBarTexture()
    local markerTex = bar.interruptMarker:GetStatusBarTexture()
    if posTex then posTex:SetAlpha(0) end
    if markerTex then markerTex:SetAlpha(0) end

    if cfg.showKickTick then
        -- IMPORTANT: make it a thin vertical tick, not bar-sized
        bar.interruptMarkerPoint:SetWidth(cfg.kickTickWidth)
        bar.interruptMarkerPoint:SetHeight(bar:GetHeight())

        local color = cfg.kickTickColour
        if cfg.kickTickUseTexture then
            bar.interruptMarkerPoint:SetTexture(cfg.kickTickTexture)
            bar.interruptMarkerPoint:SetVertexColor(color.r, color.g, color.b, color.a)
        else
            bar.interruptMarkerPoint:SetTexture(nil)
            bar.interruptMarkerPoint:SetVertexColor(1, 1, 1, 1)
            bar.interruptMarkerPoint:SetColorTexture(color.r, color.g, color.b, color.a)
        end
        bar.interruptMarkerPoint:Show()
    else
        bar.interruptMarkerPoint:Hide()
    end

    bar.interruptMarker:Hide()
    bar.interruptPositioner:Hide()

    -- Visible bar "until kick"
    local kick_frame = bar.frames.untilKick
    local mirror_frame = bar.mirror_frames.untilKick

    -- Style it (texture + color)
    if cfg.showUntilKickTick then
        local c = cfg.untilKickTickColour
        local tex = cfg.untilKickTickTexture
        kick_frame.status:SetStatusBarTexture(tex)
        mirror_frame.tex:SetTexture(tex)
        kick_frame.status:SetStatusBarColor(c.r, c.g, c.b, c.a)
        mirror_frame.tex:SetVertexColor(c.r, c.g, c.b, c.a)
        kick_frame.status:Show()
    else
        kick_frame.status:Hide()
    end

    if cfg.showUntilKickTickBackground and cfg.untilKickTickBackUseTexture then
        local c = cfg.untilKickTickBackColour
        local tex = cfg.untilKickTickBackTexture
        kick_frame.bg:SetStatusBarTexture(tex)
        kick_frame.bg:SetStatusBarColor(c.r, c.g, c.b, c.a)
        kick_frame.bg:Show()
    elseif cfg.showUntilKickTickBackground then
        local c = cfg.untilKickTickBackColour
        local tex = "Interface\\Buttons\\WHITE8X8"
        kick_frame.bg:SetStatusBarTexture(tex)
        kick_frame.bg:SetStatusBarColor(c.r, c.g, c.b, c.a)
        kick_frame.bg:Show()
    else
        kick_frame.bg:Hide()
    end
end


function BarUpdate_API:UpdateUninterruptable(unit)
    local bar = UCB.castBar[unit]
    if not bar then return end
    local cfg = GetCFG(unit, "uninterruptible")
    local unint_frame = bar.frames.unInterrupted
    local mirror_frame = bar.mirror_frames.unInterrupted
    
    if cfg.showUninterruptibleFill then
        unint_frame.status:SetStatusBarTexture(cfg.fillTexture)
        unint_frame.status:SetStatusBarColor(cfg.fillColour.r, cfg.fillColour.g, cfg.fillColour.b, cfg.fillColour.a)
        mirror_frame.tex:SetTexture(cfg.fillTexture)
        mirror_frame.tex:SetVertexColor(cfg.fillColour.r, cfg.fillColour.g, cfg.fillColour.b, cfg.fillColour.a)
        unint_frame.status:Show()
    else
        bar.status:SetAlpha(1)
        unint_frame.status:Hide()
    end

    if cfg.showUninterruptibleBackground then
        local bg = unint_frame.bg
        if cfg.backgroundUseTexture then
            bg:SetTexture(cfg.backgroundTexture)
            bg:SetVertexColor(cfg.backgroundColour.r, cfg.backgroundColour.g, cfg.backgroundColour.b, cfg.backgroundColour.a)
        else
             bg:SetVertexColor(1, 1, 1, 1) -- white tint to show texture clearly
             bg:SetColorTexture(cfg.backgroundColour.r, cfg.backgroundColour.g, cfg.backgroundColour.b, cfg.backgroundColour.a)
        end
        bg:Show()
    else
        unint_frame.bg:Hide()
    end

    -- Castbar border
    UpdateUninterruptibleBorder(unit)

    -- Icon border
    -- Icon border overlay frame (tracks iconFrame exactly)
    if not bar.unintIconFrame then
        bar.unintIconFrame = CreateFrame("Frame", nil, bar.iconFrame)
        bar.unintIconFrame:SetAllPoints(bar.iconFrame)

        -- ensure it draws above iconFrame contents
        bar.unintIconFrame:SetFrameStrata(bar.iconFrame:GetFrameStrata())
        bar.unintIconFrame:SetFrameLevel(bar.iconFrame:GetFrameLevel() + 10)
    else
        -- keep it in sync if visibility/frame levels change later
        bar.unintIconFrame:SetParent(bar.iconFrame)
        bar.unintIconFrame:SetAllPoints(bar.iconFrame)
        bar.unintIconFrame:SetFrameStrata(bar.iconFrame:GetFrameStrata())
        bar.unintIconFrame:SetFrameLevel(bar.iconFrame:GetFrameLevel() + 10)
    end
    UpdateUninterruptibleIconBorder(unit)
end

function BarUpdate_API:UpdateStyle(unit)
    local bar = UCB.castBar[unit]
    local bigCFG = GetCFG(unit)
    local cfg = bigCFG.style

    -- Bar style
    bar.status:SetStatusBarTexture(cfg.texture)

    -- Mirror style
    bar.mirrorStatus.tex:SetTexture(cfg.texture)

    -- Background
    if cfg.showBackground then
        bar.bg:SetTexture(cfg.textureBack)
        bar.bg:SetVertexColor(cfg.bgColour.r, cfg.bgColour.g, cfg.bgColour.b, cfg.bgColour.a)
        --bar.bg:SetColorTexture(cfg.bgColour.r, cfg.bgColour.g, cfg.bgColour.b, cfg.bgColour.a)
        bar.bg:Show()
    else
        bar.bg:Hide()
    end
    --Bar border
    UpdateBorderBar(unit)
    -- Icon border
    UpdateIconBorder(unit)
end


function BarUpdate_API:UpdateOtherFeatures(unit)
    local bar = UCB.castBar[unit]
    local cfg = GetCFG(unit, "otherFeatures")

    if unit == "player" then
        if cfg.showQueueWindow.normal or  cfg.showQueueWindow.channel or cfg.showQueueWindow.empowered then
            if not bar.queueWindowOverlay then
                bar.queueWindowOverlay = bar.frames.overlay:CreateTexture(nil, "OVERLAY", nil, 7)
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

    -- Cancelled/Interrupted frames
    bar.frames.interrupted.status:SetMinMaxValues(0, 1)
    bar.frames.interrupted.status:SetValue(1)
    bar.frames.cancelled.status:SetMinMaxValues(0, 1)
    bar.frames.cancelled.status:SetValue(1)
end


function BarUpdate_API:UpdateColours(unit)
    local bar = UCB.castBar[unit]

    local cfg = GetCFG(unit, "style")

    if unit ~= "player" then
        local rgba = cfg.enemyColour
        bar._enemyColour = {RGBA = rgba, COL = CreateColor(rgba.r, rgba.g, rgba.b, rgba.a)}
    end

    local colourMode = cfg.colourMode

    -- Build the static palette (1 colour or 2-colour gradient)
    local colours
    if colourMode == "class" then
        colours = { UCB.classColour.RGBA }
        bar._colourType = "class"
    else
        -- "custom" (or anything not class): either single or gradient depending on cfg
        if cfg.gradientEnable then
            colours = { cfg.customColour, cfg.customColour2 }
        else
            bar._colourType = "custom"
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
    local cfg = GetCFG(unit)

    -- Channeling ticks
    local classCFG = cfg.CLASSES[UCB.className]
    classCFG._channelingSpellIDs = {}
    if classCFG and classCFG.channeledSpels then
        for _, spellCfg in pairs(classCFG.channeledSpels) do
            if spellCfg.enable then
                classCFG._channelingSpellIDs[spellCfg.id] = spellCfg.ticks
            end
        end
    end

    -- Whitelist/Blacklist
    classCFG._whiteListSpellIDs = {}
    classCFG._blackListSpellIDs = {}
    if classCFG and classCFG.enableAbilityFilter then
        for _, spellCfg in pairs(classCFG.blackListSpells) do
            if spellCfg.enable then
                classCFG._blackListSpellIDs[spellCfg.id] = true
            end
        end
        for _, spellCfg in pairs(classCFG.whiteListSpells) do
            if spellCfg.enable then
                classCFG._whiteListSpellIDs[spellCfg.id] = true
            end
        end
    end

    -- Predecide tick settings here
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