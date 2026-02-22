local ADDON_NAME, UCB = ...

UCB.CASTBAR_API = UCB.CASTBAR_API or {}

local CASTBAR_API = UCB.CASTBAR_API

local castType = "empowered"

local function CastbarOnUpdate(bar, elapsed)
    local unit = bar._ucbUnit
    local cfg  = bar._ucbCfg
    local castType = bar._ucbCastType
    local vars = bar._ucbVars
    local remainig = UCB.CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, castType, vars)
    if unit == "player" and remainig < -0.001 then
        CASTBAR_API:OnUnitSpellcastEmpowerStop(unit)
    end
end

function CASTBAR_API:HideStages(bar, unit)
    if not bar then
        if not unit then return end
        bar = UCB.castBar[unit]
    end
    local empoweredStages = bar.empoweredStages
    local empoweredSegments = bar.empoweredSegments
    if empoweredStages then
        for _, stage in ipairs(empoweredStages) do
            stage:Hide()
        end
    end
    if empoweredSegments then
        for _, seg in ipairs(empoweredSegments) do
            seg:Hide()
        end
    end
end

local function CreateTick(bar, barWidth, invert, useTex, tick, colour, texture, pos, tickWidth, barHeight)
    local xNorm = invert and (1 - pos) or pos
    local x = xNorm * barWidth
    local overlayFrame = bar.frames.overlay

    if useTex then
        tick:SetTexture(texture)
        tick:SetVertexColor(colour.r, colour.g, colour.b, colour.a)
    else
        tick:SetVertexColor(1,1,1,1)
        tick:SetColorTexture(colour.r, colour.g, colour.b, colour.a)
    end

    tick:SetWidth(tickWidth)
    tick:SetHeight(barHeight)
    tick:ClearAllPoints()
    tick:SetPoint("LEFT",overlayFrame, "LEFT", x - 1, 0)
    tick:SetPoint("TOP",  overlayFrame, "TOP",  0, 0)
    tick:SetPoint("BOTTOM", overlayFrame, "BOTTOM", 0, 0)
    tick:Show()
end

local function CreateSegment(bar, barWidth, invert, useTex, segment, colour, texture, startPos, endPos, barHeight)
    -- startPos/endPos are normalized 0..1, startPos < endPos
    local underlayFrame = bar.frames.underlay
    local s, e
    if invert then
        -- mirror interval
        s = 1 - endPos
        e = 1 - startPos
    else
        s = startPos
        e = endPos
    end

    local startX = s * barWidth
    local width  = (e - s) * barWidth

    if useTex then
        segment:SetTexture(texture)
        segment:SetVertexColor(colour.r, colour.g, colour.b, colour.a)
    else
        segment:SetVertexColor(1, 1, 1, 1)
        segment:SetColorTexture(colour.r, colour.g, colour.b, colour.a)
    end

    segment:ClearAllPoints()
    segment:SetPoint("TOPLEFT", underlayFrame, "TOPLEFT", startX, 0)
    segment:SetPoint("BOTTOMLEFT", underlayFrame, "BOTTOMLEFT", startX, 0)
    segment:SetWidth(width)
    segment:SetHeight(barHeight)
    segment:Show()
end

local function CreateColourCurve(bar, tickPositions, colours, inverted)
    local curve = bar.empoweredColourCurve
    curve:ClearPoints()

    if inverted then
        -- Start from last stage color, then walk boundaries mirrored across 1.0
        curve:AddPoint(0, CreateColor(colours[#tickPositions].r, colours[#tickPositions].g, colours[#tickPositions].b, colours[#tickPositions].a))
        for i = #tickPositions - 1, 1, -1 do
            curve:AddPoint(1 - tickPositions[i], CreateColor(colours[i].r, colours[i].g, colours[i].b, colours[i].a))
        end
    else
        curve:AddPoint(0, CreateColor(colours[1].r, colours[1].g, colours[1].b, colours[1].a))
        for i = 1, #tickPositions - 1 do
            curve:AddPoint(tickPositions[i], CreateColor(colours[i + 1].r, colours[i + 1].g, colours[i + 1].b, colours[i + 1].a))
        end
    end
end

-- Empowered Cast Stage Markers
function CASTBAR_API:InitializeEmpoweredStages(bar, cfg, vars)
    -- Hide previous stages
    CASTBAR_API:HideStages(bar)

    local classCFG = cfg.CLASSES.EVOKER

    local numStages = #vars.empStages
    local tickPositions = vars.empStages

    local tickColours = classCFG.empowerStageTickColours
    local segColours = classCFG.empowerSegBackColours
    local barColours = classCFG.empowerBarColours

    local tickTextures = classCFG.empowerTickTextures
    local segTextures = classCFG.empowerSegmentTextures

    local barWidth = cfg.general.actualBarWidth
    local barHeight = cfg.general.barHeight
    local invert = cfg.otherFeatures.invertBar.empowered
    local mirror = cfg.otherFeatures.mirrorBar.empowered
    local switch = (invert or mirror) and not (invert and mirror)  -- if either is true, but not both
    local useTexTick = classCFG.showEmpowerTickTexture
    local useTexSeg = classCFG.showEmpowerSegmentTexture
    local tickWidth = classCFG.empowerTickWidth

    -- Initialise ticks and background segments
    local empoweredSegments = bar.empoweredSegments
    local empoweredStages = bar.empoweredStages

    CreateColourCurve(bar, tickPositions, barColours, switch)

    -- Frames
    local overlayFrame = bar.frames.overlay
    local underlayFrame = bar.frames.underlay
    -- Create ticks, segments and bar curve
    local prevX = 0
    for i = 1, numStages do
        -- There is n-1 ticks for n stages
        if i < numStages then
            -- Create tick
            local stage = empoweredStages[i]
            if not stage then
                stage = overlayFrame:CreateTexture(nil, "OVERLAY")
                empoweredStages[i] = stage
            end
            CreateTick(bar, barWidth, switch, useTexTick, stage, tickColours[i], tickTextures[i],  tickPositions[i], tickWidth, barHeight)
        end
        -- Create segment
        local seg = empoweredSegments[i]
        if not seg then
            seg = underlayFrame:CreateTexture(nil, "BACKGROUND", nil, 2)
            empoweredSegments[i] = seg
        end
        CreateSegment(bar, barWidth, switch, useTexSeg, seg, segColours[i], segTextures[i], prevX, tickPositions[i], barHeight)
        prevX = tickPositions[i]
    end
end

---------------------------------------------------- MAIN -------------------------------------------------
function CASTBAR_API:OnUnitSpellcastEmpowerStart(unit, castGUID, spellID, castBarID, resumeCast)
    -- Prevent Font of Magic (spellID 411212) from showing empower stages ???
    if unit == "player" and spellID == 411212 then return end
    local show, cfg, bar, vars = CASTBAR_API:CastSetup(unit, castGUID, spellID, resumeCast, castType)
    if not show then return end
    -- Set colours and other empower stage visuals
    if cfg.CLASSES.EVOKER.enableEmpowerEffects and UnitIsPlayer(unit) then
        CASTBAR_API:InitializeEmpoweredStages(bar, cfg,  vars)
    else
        CASTBAR_API:SemiColourUpdate(unit, bar)
    end
    CASTBAR_API:CastOnUpdateSetup(bar, unit, cfg, vars, castType, spellID, CastbarOnUpdate)
end

function CASTBAR_API:OnUnitSpellcastEmpowerUpdate(unit, castGUID, spellID, castBarID)
    CASTBAR_API:CastUpdate(unit, castGUID, spellID, castType)
end

function CASTBAR_API:OnUnitSpellcastEmpowerStop(unit, castGUID, spellID, castBarID)
    local bar = UCB.castBar[unit]
    if bar and bar.flags.castActive then
        bar.group:Hide()
        bar:SetScript("OnUpdate", nil)
        bar.flags.castActive = false
        bar.flags.prevType = nil
        bar.current_spellID = nil
        bar._ucbUnit, bar._ucbCfg, bar._ucbCastType, bar._ucbVars, bar._ucbSpellID = nil, nil, nil, nil, nil
        local cfg = UCB.GetValueConfig(unit)
        if cfg.CLASSES.EVOKER.enableEmpowerEffects and UnitIsPlayer(unit) then
            CASTBAR_API:HideStages(bar)
        end
    end
end