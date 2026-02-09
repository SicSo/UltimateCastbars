local ADDON_NAME, UCB = ...

UCB.CFG_API  = UCB.CFG_API  or {}
UCB.tags     = UCB.tags     or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.Preview_API = UCB.Preview_API or {}

local CFG_API = UCB.CFG_API
local tags = UCB.tags
local CASTBAR_API = UCB.CASTBAR_API
local Preview_API = UCB.Preview_API

local castType = "empowered"

local function CastbarOnUpdate(bar, elapsed)
    local unit = bar._ucbUnit
    local cfg  = bar._ucbCfg
    local castType = bar._ucbCastType
    UCB.CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, castType)
end

function CASTBAR_API:HideStages(unit)
    local bar = UCB.castBar[unit]
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
    tick:SetPoint("LEFT", bar.status, "LEFT", x - 1, 0)
    tick:SetPoint("TOP",  bar.status, "TOP",  0, 0)
    tick:SetPoint("BOTTOM", bar.status, "BOTTOM", 0, 0)
    tick:Show()
end


--local function CreateSegment(unit, segment, colour, texture, startPos, endPos)
local function CreateSegment(bar, barWidth, invert, useTex, segment, colour, texture, startPos, endPos, barHeight)
    -- startPos/endPos are normalized 0..1, startPos < endPos
    local status = bar.status
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
    segment:SetPoint("TOPLEFT", status, "TOPLEFT", startX, 0)
    segment:SetPoint("BOTTOMLEFT", status, "BOTTOMLEFT", startX, 0)
    segment:SetWidth(width)
    segment:SetHeight(barHeight)
    segment:Show()
end

local function CreateColourCurve(unit, tickPositions, colours, duration)
    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]
    local curve = bar.empoweredColourCurve

    if not curve then
        curve = C_CurveUtil.CreateColorCurve()
        curve:SetType(Enum.LuaCurveType.Step)
        bar.empoweredColourCurve = curve
    end

    if curve.Reset then curve:Reset() end  -- IMPORTANT if available

    if cfg.otherFeatures.invertBar.empowered then
        curve:AddPoint(0, CreateColor(colours[#colours].r, colours[#colours].g, colours[#colours].b, colours[#colours].a))
        for i = #tickPositions, 1, -1 do
            curve:AddPoint((1 - tickPositions[i]) * duration, CreateColor(colours[i].r, colours[i].g, colours[i].b, colours[i].a))
        end
    else
        curve:AddPoint(0, CreateColor(colours[1].r, colours[1].g, colours[1].b, colours[1].a))
        for i = 1, #tickPositions-1 do
            curve:AddPoint(tickPositions[i] * duration, CreateColor(colours[i+1].r, colours[i+1].g, colours[i+1].b, colours[i+1].a))
        end
    end
end

-- Empowered Cast Stage Markers
function CASTBAR_API:InitializeEmpoweredStages(unit)
    -- Hide previous stages
    CASTBAR_API:HideStages(unit)

    local bar = UCB.castBar[unit]
    local cfg = CFG_API.GetValueConfig(unit)
    local vars = tags.var[unit]
    local classCFG = cfg.CLASSES.EVOKER

    local numStages = #vars.empStages
    local tickPositions = vars.empStages
    local duration = vars.dTime

    local tickColours = classCFG.empowerStageTickColours
    local segColours = classCFG.empowerSegBackColours
    local barColours = classCFG.empowerBarColours

    local tickTextures = classCFG.empowerTickTextures
    local segTextures = classCFG.empowerSegmentTextures

    local barWidth = cfg.general.actualBarWidth
    local barHeight = cfg.general.barHeight
    local invert = cfg.otherFeatures.invertBar.empowered
    local useTexTick = classCFG.showEmpowerTickTexture
    local useTexSeg = classCFG.showEmpowerSegmentTexture
    local tickWidth = classCFG.empowerTickWidth

    -- Initialise ticks and background segments
    if not bar.empoweredSegments then bar.empoweredSegments = {} end
    if not bar.empoweredStages then bar.empoweredStages = {} end
    local empoweredSegments = bar.empoweredSegments
    local empoweredStages = bar.empoweredStages

    CreateColourCurve(unit, tickPositions, barColours, duration)

    -- Create ticks, segments and bar curve
    local prevX = 0
    for i = 1, numStages do

        -- There is n-1 ticks for n stages
        if i < numStages then
            -- Create tick
            local stage = empoweredStages[i]
            if not stage then
                stage = bar.status:CreateTexture(nil, "OVERLAY")
                empoweredStages[i] = stage
            end
            CreateTick(bar, barWidth, invert, useTexTick, stage, tickColours[i], tickTextures[i],  tickPositions[i], tickWidth, barHeight)
        end
        
        -- Create segment
        local seg = empoweredSegments[i]
        if not seg then
            seg = bar.status:CreateTexture(nil, "BACKGROUND", nil, 2)
            empoweredSegments[i] = seg
        end
        CreateSegment(bar, barWidth, invert, useTexSeg, seg, segColours[i], segTextures[i], prevX, tickPositions[i], barHeight)
        prevX = tickPositions[i]
    end
end

function CASTBAR_API:OnUnitSpellcastEmpowerStart(unit, castGUID, spellID)
    if Preview_API.previewActive and Preview_API.previewActive[unit] then
        Preview_API:HidePreviewCastBar(unit)
    end
    -- Prevent Font of Magic (spellID 411212) from showing empower stages ???
    if spellID == 411212 then return end

    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]

    local icon_texture = tags:updateVars(unit, castType, spellID)
    local vars = tags.var[unit]

    -- Failsafe
    if not vars.sName or not vars.sTime or not vars.eTime then
        return
    end
    
    -- Set text, icon, queue window
    local textCFG = cfg.text
    tags:setTextSameState(textCFG, bar, "semiDynamic", unit, castType, false)
    tags:setTextSameState(textCFG, bar, "dynamic", unit, castType, true)

    bar.icon:SetTexture(icon_texture)
    CASTBAR_API:AssignQueueWindow(unit, castType)

    CASTBAR_API:InitializeEmpoweredStages(unit)

    bar.status:SetMinMaxValues(0, math.max(vars.dTime, 0.001))
    bar._ucbUnit = unit
    bar._ucbCfg = cfg
    bar._ucbCastType = castType
    bar:SetScript("OnUpdate", CastbarOnUpdate)
    bar.group:Show()
end

function CASTBAR_API:OnUnitSpellcastEmpowerUpdate(unit, castGUID, spellID)
    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]

    local icon_texture = tags:updateVars(unit, castType)
    local vars = tags.var[unit]

    -- Failsafe
    if not vars.sName or not vars.sTime or not vars.eTime then
        return
    end

    local textCFG = cfg.text
    tags:setTextSameState(textCFG, bar, "semiDynamic", unit, castType, false)
    tags:setTextSameState(textCFG, bar, "dynamic", unit, castType, true)
    
    bar.icon:SetTexture(icon_texture)
    CASTBAR_API:AssignQueueWindow(unit, castType)
    bar.status:SetMinMaxValues(0, math.max(vars.dTime, 0.001))
end

function CASTBAR_API:OnUnitSpellcastEmpowerStop(unit, castGUID, spellID)
    local bar = UCB.castBar[unit]
    bar.group:Hide()
    bar:SetScript("OnUpdate", nil)
    bar._ucbUnit, bar._ucbCfg, bar._ucbCastType = nil, nil, nil

    CASTBAR_API:HideStages(unit)
end