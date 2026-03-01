local ADDON_NAME, UCB = ...

UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local BarUpdate_API = UCB.BarUpdate_API

local function UpdateSequence(unit)
    BarUpdate_API:BuildColourCandidates(unit)
    BarUpdate_API:UpdateBarIcon(unit)
    BarUpdate_API:UpdateStyle(unit, true)
    BarUpdate_API:UpdateVisibility(unit)
    BarUpdate_API:UpdateText(unit)
    BarUpdate_API:UpdateUninterruptable(unit)
    BarUpdate_API:UpdateUnkickable(unit)
    BarUpdate_API:UpdateOtherFeatures(unit)
    BarUpdate_API:UpdateOthers(unit)
end


local function CreateFrameBar(bar, name, type, mirror, status, background)
    if mirror then
        local mirror_frame = CreateFrame("Frame", nil, bar, type)
        bar.mirror_frames[name] = mirror_frame
        mirror_frame:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
        mirror_frame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
        mirror_frame:SetWidth(0)
        mirror_frame:SetClipsChildren(true)
        mirror_frame:Hide()
        mirror_frame.tex = mirror_frame:CreateTexture(nil, "ARTWORK", nil, -8)
        mirror_frame.tex:SetAllPoints(bar)
        mirror_frame.tex:SetTexCoord(1, 0, 0, 1)
    end
    local frame = CreateFrame("Frame", nil, bar, type)
    bar.frames[name] = frame
    frame:SetAllPoints()
    if status then
        frame.status = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
        frame.status:SetAllPoints()
    end
    if background then
        frame.bg = frame:CreateTexture(nil, "BACKGROUND", nil, 3)
        frame.bg:SetAllPoints()
    end
    --frame:Hide()
end

local function CreateCastBar(unit)
    -- Create castbar
    local anchor = UIParent

    local gate_effects = CreateFrame("Frame", ADDON_NAME.."_"..unit.."EffectCastGate", anchor)

    -- Group frame = the thing you anchor (represents bar+icon combined)    
    local group = CreateFrame("Frame", ADDON_NAME .. "_" .. unit .. "CastGroup", gate_effects)
    UCB.castBarGroup[unit] = group

    -- Bar frame lives inside group (keep your name)
    local bar = CreateFrame("Frame", ADDON_NAME .. "_" .. unit:sub(1,1):upper() .. unit:sub(2) .. "CastBar", group, "BackdropTemplate")
    UCB.castBar[unit] = bar
    bar.group = group  -- handy reference
    bar.gate_effects = gate_effects

    -- Status bar (fill bar)
    bar.status = CreateFrame("StatusBar", nil, bar, "BackdropTemplate")
    bar.status:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    bar.status:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

    -- Mirror status bar
    bar.mirrorStatus = CreateFrame("Frame", nil, bar)
    bar.mirrorStatus:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
    bar.mirrorStatus:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    bar.mirrorStatus:SetWidth(0)
    bar.mirrorStatus:SetClipsChildren(true)
    bar.mirrorStatus:Hide()
    bar.mirrorStatus.tex = bar.mirrorStatus:CreateTexture(nil, "ARTWORK", nil, -8)
    bar.mirrorStatus.tex:SetAllPoints(bar)
    bar.mirrorStatus.tex:SetTexCoord(1, 0, 0, 1)

    -- Bakcground
    bar.bg = bar:CreateTexture(nil, "BACKGROUND", nil, 1)
    bar.bg:SetAllPoints()

    -- Icon frame 
    bar.iconFrame = CreateFrame("Frame", nil, group, "BackdropTemplate")
    bar.icon = bar.iconFrame:CreateTexture(nil, "ARTWORK")
    bar.icon:SetAllPoints()
    bar.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

    -- Set initial values for bar properties

    -- Texts
    bar.texts = {}

    -- Kickable marker and tick
    local helperTex = "Interface\\TARGETINGFRAME\\UI-StatusBar"

    bar.interruptMarker = CreateFrame("StatusBar", nil, bar)
    bar.interruptMarker:SetStatusBarTexture(helperTex)
    bar.interruptMarker:SetPoint("CENTER")
    bar.interruptMarker:SetAllPoints()
    bar.interruptMarker:SetClipsChildren(false)

    bar.interruptPositioner = CreateFrame("StatusBar", nil, bar)
    bar.interruptPositioner:SetStatusBarTexture(helperTex)
    bar.interruptPositioner:SetPoint("CENTER")
    bar.interruptPositioner:SetAllPoints()
    
    bar.kickTickClip = CreateFrame("Frame", nil, bar)
    bar.kickTickClip:SetAllPoints(bar)
    bar.kickTickClip:SetClipsChildren(true)

    bar.interruptMarkerPoint = bar.kickTickClip:CreateTexture(nil, "ARTWORK")
    bar.interruptMarkerPoint:SetPoint("CENTER")
    bar.interruptMarkerPoint:ClearAllPoints()
    bar.interruptMarkerPoint:SetPoint("LEFT", bar.interruptMarker:GetStatusBarTexture(), "RIGHT", 0, 0)
    bar.interruptMarker:SetPoint("LEFT", bar.interruptPositioner:GetStatusBarTexture(), "RIGHT")

    -- Helper frames
    bar.frames = {}
    bar.mirror_frames = {}
    CreateFrameBar(bar, "overlay", nil, false) -- Ticks and other effects above the bar
    CreateFrameBar(bar, "underlay", nil, false) -- Segments and other effects below the bar
    CreateFrameBar(bar, "text", nil, false) -- Texts above overlay
    CreateFrameBar(bar, "unInterrupted", "BackdropTemplate", true, true, true) -- Uninterruptible overlay (mirror if mirror enabled)
    CreateFrameBar(bar, "untilKick", "BackdropTemplate", true, true, false) -- Unkickable overlay (mirror if mirror enabled)
    bar.frames.untilKick.bg = CreateFrame("StatusBar", nil, bar.frames.untilKick, "BackdropTemplate")
    bar.frames.untilKick.bg:SetAllPoints()
    CreateFrameBar(bar, "interrupted", nil, false, true)
    CreateFrameBar(bar, "cancelled", nil, false, true)

    -- Flags
    bar.flags = {
        castActive = false, -- Active cast
        mirrored = false, -- Whether mirror bars are enabled for this unit
        prevType = nil, -- Type of previous cast (normal/channel/empowered)
        cancelledOrInterrupted = false -- Whether the current cast was cancelled or interrupted (used to prevent hiding the bar on spellcast stop event)    
    }

    -- Cast info
    bar.current_spellID = nil

    -- Channel properties
    bar.channelTicks = {}

    -- Empower properties
    bar.empoweredStages = {}
    bar.empoweredSegments = {}
    bar.empoweredColourCurve = C_CurveUtil.CreateColorCurve()
    bar.empoweredColourCurve:SetType(Enum.LuaCurveType.Step)

    -- Set properties
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

-- Castbar entry functionality
function CASTBAR_API:UpdateCastbar(unit)
    if not UCB.castBar then return end
    local cfg = UCB.GetValueConfig(unit)
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