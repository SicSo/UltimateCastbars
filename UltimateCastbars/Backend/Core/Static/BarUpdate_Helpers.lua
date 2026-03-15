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
local function UpdateRectBorderFromCfg(holder, target, holderKey, cfgBlock, frameLevelDelta)
    if not holder or not target or not cfgBlock then return end

    if not cfgBlock.show then
        BarUpdate_API:HideRectBorder(holder, holderKey)
        return
    end

    BarUpdate_API:ApplyRectBorder(
        holder,
        holderKey,
        target,
        cfgBlock.texture,
        cfgBlock.colour,
        cfgBlock.thickness,
        cfgBlock.offsets,
        frameLevelDelta or -1,
        cfgBlock.fillCorners
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
        fillCorners = cfg.borderFillCorners
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
            fillCorners = cfg.borderFillCorners
        }
        BarUpdate_API:UpdateRectBorderFromCfg(mirror_frame, mirror_frame, "_rectBorder", mirrorBlock, -1)
    elseif mirror_frame then
        BarUpdate_API:HideRectBorder(mirror_frame, "_rectBorder")
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
            fillCorners = cfg.borderFillCornersIcon
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
            fillCorners = cfg.borderFillCornersIcon
        }
    end

    -- icon border frame level often needs to be higher than bar border
    UpdateRectBorderFromCfg(bar.unintIconFrame, bar.unintIconFrame, "_rectBorderUnintIcon", borderBlock, -3)
end


local function _BuildAllSpellIds()
    local merged, seen = {}, {}

    local function addList(list)
        for _, sid in ipairs(list or {}) do
            sid = tonumber(sid)
            if sid and not seen[sid] then
                local info = C_Spell.GetSpellInfo(sid)
                if info and info.name then
                    seen[sid] = info.name -- store name for sorting
                    table.insert(merged, sid)
                end
            end
        end
    end

    addList(UCB.allSpellTypes and UCB.allSpellTypes.channel)
    addList(UCB.allSpellTypes and UCB.allSpellTypes.normal)
    addList(UCB.allSpellTypes and UCB.allSpellTypes.empowered)

    table.sort(merged, function(a, b)
        return (seen[a] or ""):lower() < (seen[b] or ""):lower()
    end)

    return merged -- array of spell IDs
end

local function WhitelistBlacklistSetup(unit, cfg)
     if UCB:IsPlayer(unit) then
        cfg._whiteListSpellIDs = {}
        cfg._blackListSpellIDs = {}
        if cfg and cfg.enableAbilityFilter then

            if cfg.useManualTable then
                for _, spellCfg in pairs(cfg.blackListSpells) do
                    if spellCfg.enable then
                        cfg._blackListSpellIDs[spellCfg.id] = true
                    end
                end
                for _, spellCfg in pairs(cfg.whiteListSpells) do
                    if spellCfg.enable then
                        cfg._whiteListSpellIDs[spellCfg.id] = true
                    end
                end
            end

            if cfg.usePlayerSpellList and not cfg.useManualTable then
                local allSpellIDs = _BuildAllSpellIds()
                for _, spellID in ipairs(allSpellIDs) do
                    cfg._whiteListSpellIDs[spellID] = true
                    cfg._blackListSpellIDs[spellID] = true
                end
            end

        end
    end
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

            if tagOptions.sizeControl.widthControl.enable then
                local width
                if tagOptions.sizeControl.widthControl.type == "percentage" then
                    width = bar:GetWidth() * (tagOptions.sizeControl.widthControl.perValue / 100)
                else
                    width = tagOptions.sizeControl.widthControl.customValue
                end
                fs:SetWidth(width)
            else
                fs:SetWidth(99999)
            end

            if tagOptions.sizeControl.heightControl.enable then
                local height
                if tagOptions.sizeControl.heightControl.type == "percentage" then
                    height = bar:GetHeight() * (tagOptions.sizeControl.heightControl.perValue / 100)
                else
                    height = tagOptions.sizeControl.heightControl.customValue
                end
                fs:SetHeight(height)
                fs:SetNonSpaceWrap(false)
            else
                fs:SetHeight(99999)
                fs:SetNonSpaceWrap(false)
            end
            fs:SetWordWrap(tagOptions.sizeControl.heightControl.wrapText)
            
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
            tagOptions._compiled = UCB.tags:compileFormula(tagOptions._formula, tagOptions._limits, tagOptions.mainType, unit)
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

    -- Whitelist/Blacklist class
    WhitelistBlacklistSetup(unit, cfg.blacklistWhitelist)
end

function BarUpdate_API:UpdateOtherFeatures(unit)
    local bar = UCB.castBar[unit]
    local cfg = GetCFG(unit, "otherFeatures")

    if UCB:IsPlayer(unit) then
        -- Spell que
        if cfg.showQueueWindow.normal or  cfg.showQueueWindow.channel or cfg.showQueueWindow.empowered then
            if not bar.queueWindowOverlay or (bar.queueWindowOverlay and bar._queuePlacement ~= cfg.queuePlacement) then
                if bar.queueWindowOverlay then
                    bar.queueWindowOverlay:Hide()
                    bar.queueWindowOverlay = nil
                end
                bar._queuePlacement = cfg.queuePlacement
                if cfg.queuePlacement == "over" then
                    bar.queueWindowOverlay = bar.frames.overlay:CreateTexture(nil, "OVERLAY", nil, 6)
                else
                    bar.queueWindowOverlay = bar.frames.underlay:CreateTexture(nil, "OVERLAY", nil, 6)
                end
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

        -- Latency
        if cfg.latency.enabled then
            if not bar.latencyOverlay then
                bar.latencyOverlay = bar.frames.overlay:CreateTexture(nil, "OVERLAY", nil, 7)
            end
            -- Texture and colour
            if cfg.latency.useTexture then
                bar.latencyOverlay:SetTexture(cfg.latency.texture)
                bar.latencyOverlay:SetVertexColor(cfg.latency.colour.r, cfg.latency.colour.g, cfg.latency.colour.b, cfg.latency.colour.a)
            else
                bar.latencyOverlay:SetVertexColor(1, 1, 1, 1)
                bar.latencyOverlay:SetColorTexture(cfg.latency.colour.r, cfg.latency.colour.g, cfg.latency.colour.b, cfg.latency.colour.a)
            end
            bar.latencyOverlay:Show()
        elseif bar.latencyOverlay then
            bar.latencyOverlay:Hide()
        end

    end

    -- Cancelled/Interrupted frames
    bar.frames.interrupted:Hide()
    bar.frames.interrupted.status:SetMinMaxValues(0, 1)
    bar.frames.interrupted.status:SetValue(1)
    local interCFG = cfg.interruptedEffect
    bar.frames.interrupted.status:SetStatusBarTexture(interCFG.frameTexture.normal)
    bar.frames.interrupted.status:SetStatusBarColor(interCFG.frameColour.normal.r, interCFG.frameColour.normal.g, interCFG.frameColour.normal.b, interCFG.frameColour.normal.a)
    bar.frames.cancelled:Hide()
    bar.frames.cancelled.status:SetMinMaxValues(0, 1)
    bar.frames.cancelled.status:SetValue(1)
    local cancelCFG = cfg.cancelledEffect
    bar.frames.cancelled.status:SetStatusBarTexture(cancelCFG.frameTexture.normal)
    bar.frames.cancelled.status:SetStatusBarColor(cancelCFG.frameColour.normal.r, cancelCFG.frameColour.normal.g, cancelCFG.frameColour.normal.b, cancelCFG.frameColour.normal.a)

    -- Whitelist/Blacklist cancelled
    WhitelistBlacklistSetup(unit, cancelCFG.blacklistWhitelist)

    -- Permanent background
    BarUpdate_API:UpdateStylePermanentBack(unit)
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

    -- Whitelist/Blacklist class
    WhitelistBlacklistSetup(unit, classCFG.blacklistWhitelist)

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

    -- Spell custom styles
    local spellStyling = classCFG.spellStyling
    if UCB:IsPlayer(unit) then
        spellStyling._customSpellStyles = {}
        for _, spellStyle in ipairs(spellStyling.styleSpells) do
            if spellStyle.enable and spellStyle.id then
                spellStyling._customSpellStyles[spellStyle.id] = spellStyle.style
            end
        end
    end
end