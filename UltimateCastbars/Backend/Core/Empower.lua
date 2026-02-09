local ADDON_NAME, UCB = ...

UCB.CFG_API  = UCB.CFG_API  or {}
UCB.tags     = UCB.tags     or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}


local CFG_API = UCB.CFG_API
local tags = UCB.tags
local CASTBAR_API = UCB.CASTBAR_API


local castType = "empowered"

function CASTBAR_API:HideStages(unit)
    local bar = UCB.castBar[unit]
    if bar.empoweredStages then
        for _, stage in ipairs(bar.empoweredStages) do
            stage:Hide()
        end
    end
    if bar.empoweredSegments then
        for _, seg in ipairs(bar.empoweredSegments) do
            seg:Hide()
        end
    end
end

local function CreateTick(unit, tick, colour, texture, pos)
    local bar = UCB.castBar[unit]
    local cfg = CFG_API.GetValueConfig(unit)
    local barWidth = cfg.general.actualBarWidth

    -- pos is normalized 0..1
    local xNorm = cfg.otherFeatures.invertBar.empowered and (1 - pos) or pos
    local x = xNorm * barWidth

    if cfg.EVOKER.showEmpowerTickTexture then
        tick:SetTexture(texture)
        tick:SetVertexColor(colour.r, colour.g, colour.b, colour.a)
    else
        tick:SetVertexColor(1, 1, 1, 1)
        tick:SetColorTexture(colour.r, colour.g, colour.b, colour.a)
    end

    tick:SetWidth(cfg.EVOKER.empowerTickWidth)
    tick:SetHeight(cfg.general.barHeight)
    tick:ClearAllPoints()

    tick:SetPoint("LEFT", bar.status, "LEFT", x - 1, 0)
    tick:SetPoint("TOP", bar.status, "TOP", 0, 0)
    tick:SetPoint("BOTTOM", bar.status, "BOTTOM", 0, 0)

    tick:Show()
end

local function CreateSegment(unit, segment, colour, texture, startPos, endPos)
    local bar = UCB.castBar[unit]
    local cfg = CFG_API.GetValueConfig(unit)
    local barWidth = cfg.general.actualBarWidth

    -- startPos/endPos are normalized 0..1, startPos < endPos
    local s, e
    if cfg.otherFeatures.invertBar.empowered then
        -- mirror interval
        s = 1 - endPos
        e = 1 - startPos
    else
        s = startPos
        e = endPos
    end

    local startX = s * barWidth
    local width  = (e - s) * barWidth

    if cfg.EVOKER.showEmpowerSegmentTexture then
        segment:SetTexture(texture)
        segment:SetVertexColor(colour.r, colour.g, colour.b, colour.a)
    else
        segment:SetVertexColor(1, 1, 1, 1)
        segment:SetColorTexture(colour.r, colour.g, colour.b, colour.a)
    end

    segment:ClearAllPoints()
    segment:SetPoint("TOPLEFT", bar.status, "TOPLEFT", startX, 0)
    segment:SetPoint("BOTTOMLEFT", bar.status, "BOTTOMLEFT", startX, 0)
    segment:SetWidth(width)
    segment:SetHeight(cfg.general.barHeight)
    segment:Show()
end



local function CreateColourCurve(unit, tickPositions, colours, duration)
    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]
    if not bar.empoweredColourCurve then
        bar.empoweredColourCurve = C_CurveUtil.CreateColorCurve()
        bar.empoweredColourCurve:SetType(Enum.LuaCurveType.Step)
    end
    local curve  = bar.empoweredColourCurve

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

    local numStages = #tags.var[unit].empStages
    local tickPositions = tags.var[unit].empStages
    local duration = tags.var[unit].dTime

    local tickColours = cfg.EVOKER.empowerStageTickColours
    local segColours = cfg.EVOKER.empowerSegBackColours
    local barColours = cfg.EVOKER.empowerBarColours

    local tickTextures = cfg.EVOKER.empowerTickTextures
    local segTextures = cfg.EVOKER.empowerSegmentTextures

    -- Initialise ticks and background segments
    if not bar.empoweredSegments then bar.empoweredSegments = {} end
    if not bar.empoweredStages then bar.empoweredStages = {} end

    CreateColourCurve(unit, tickPositions, barColours, duration)

    -- Create ticks, segments and bar curve
    local prevX = 0
    for i = 1, numStages do

        -- There is n-1 ticks for n stages
        if i < numStages then
            -- Create tick
            local stage = bar.empoweredStages[i]
            if not stage then
                stage = bar.status:CreateTexture(nil, "OVERLAY")
                bar.empoweredStages[i] = stage
            end
            CreateTick(unit, stage, tickColours[i], tickTextures[i],  tickPositions[i])
            
        end
        
        -- Create segment
        local seg = bar.empoweredSegments[i]
        if not seg then
            seg = bar.status:CreateTexture(nil, "BACKGROUND", nil, 2)
            bar.empoweredSegments[i] = seg
        end
        CreateSegment(unit, seg, segColours[i], segTextures[i], prevX, tickPositions[i])
        prevX = tickPositions[i]
    end
end


function CASTBAR_API:OnUnitSpellcastEmpowerStart(unit, castGUID, spellID)
    if UCB.Preview_API.previewActive and UCB.Preview_API.previewActive[unit] then
        UCB.Preview_API:HidePreviewCastBar(unit)
    end
    -- Prevent Font of Magic (spellID 411212) from showing empower stages ???
    if spellID == 411212 then return end

    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]

    local icon_texture = tags:updateVars(unit, castType, spellID)
    
    -- Set text, icon, queue window
    UCB.tags:setTextSameState(cfg.text, bar, "semiDynamic", unit, castType, false)
    UCB.tags:setTextSameState(cfg.text, bar, "dynamic", unit, castType, true)

    bar.icon:SetTexture(icon_texture)
    UCB.CASTBAR_API:AssignQueueWindow(unit, castType)

    CASTBAR_API:InitializeEmpoweredStages(unit)

    bar.status:SetMinMaxValues(0, math.max(tags.var[unit].dTime, 0.001))
    bar:SetScript("OnUpdate", function(bar, elapsed) UCB.CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, castType) end)
    bar.group:Show()
end

function CASTBAR_API:OnUnitSpellcastEmpowerUpdate(unit, castGUID, spellID)
    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]

    local icon_texture = tags:updateVars(unit, castType)
    -- Failsafe
    --if not tags.var[unit].sName or not tags.var[unit].sTime or not tags.var[unit].eTime then
    --    if bar then bar:Hide() end
    --    return
    --end

    UCB.tags:setTextSameState(cfg.text, bar, "semiDynamic", unit, castType, false)
    UCB.tags:setTextSameState(cfg.text, bar, "dynamic", unit, castType, true)
    
    bar.icon:SetTexture(icon_texture)
    UCB.CASTBAR_API:AssignQueueWindow(unit, castType)
    bar.status:SetMinMaxValues(0, math.max(tags.var[unit].dTime, 0.001))
end

function CASTBAR_API:OnUnitSpellcastEmpowerStop(unit, castGUID, spellID)
    -- Only hide if not casting 
    --local nameChnnalel = UnitChannelInfo(unit)
    --local nameCast = UnitCastingInfo(unit)
    --if nameCast or nameChnnalel then return end

    UCB.castBar[unit].group:Hide()
    UCB.castBar[unit]:SetScript("OnUpdate", nil)

    CASTBAR_API:HideStages(unit)
end