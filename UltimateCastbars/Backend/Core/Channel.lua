local ADDON_NAME, UCB = ...

UCB.CFG_API  = UCB.CFG_API  or {}
UCB.tags     = UCB.tags     or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}


local CFG_API = UCB.CFG_API
local tags = UCB.tags
local CASTBAR_API = UCB.CASTBAR_API


UCB.CLASS_API = UCB.CLASS_API or {}
UCB.CLASS_API.Evoker = UCB.CLASS_API.Evoker or {}
local Evoker_API = UCB.CLASS_API.Evoker

local castType = "channel"

local function GetChannelTickNumber(spellID, cfg)
    if spellID == nil then
        return 0
    end
    local channelSpells = cfg._channelingSpellIDs
    if channelSpells and channelSpells[spellID] then
        return channelSpells[spellID]
    end
    return 0
end

local function CreateTick(unit, tick, position, anchor)
    local cfg = CFG_API.GetValueConfig(unit)
    local otherCFG = cfg.otherFeatures
    local classCFG = cfg.CLASSES[UCB.className]
    -- Useful tick variables
	local tickHeight = cfg.general.barHeight

    local tickWidth, tickColour, useTickTexture, tickTexture

    if not classCFG.useMainSettingsChannel then
        tickWidth  = classCFG.channelTickWidth
        tickColour = classCFG.channelTickColour
        useTickTexture = classCFG.useTickTexture
        tickTexture = classCFG.tickTexture
    else
        tickWidth  = otherCFG.channelTickWidth
        tickColour = otherCFG.channelTickColour
        useTickTexture = otherCFG.useTickTexture
        tickTexture = otherCFG.tickTexture
    end

    tick:SetSize(tickWidth, tickHeight)
    if useTickTexture then
        tick:SetTexture(tickTexture)
        tick:SetVertexColor(tickColour.r, tickColour.g, tickColour.b, tickColour.a)
    else
        tick:SetVertexColor(1, 1, 1, 1)
        tick:SetColorTexture(tickColour.r, tickColour.g, tickColour.b, tickColour.a)
    end

    local x = position
    tick:ClearAllPoints()
    tick:SetPoint("LEFT", anchor, "LEFT", x, 0)
    tick:SetPoint("TOP", anchor, "TOP", 0, 0)
    tick:SetPoint("BOTTOM", anchor, "BOTTOM", 0, 0)
    tick:Show()
end

function CASTBAR_API:HideChannelTicks(unit)
    local bar = UCB.castBar[unit]
    local cfg = CFG_API.GetValueConfig(unit)
    if cfg.otherFeatures._prevChannelNumTicks == 0 then return end

    for i = 1, cfg.otherFeatures._prevChannelNumTicks do
        if bar.channelTicks and bar.channelTicks[i] then
            bar.channelTicks[i]:Hide()
        end
    end
    cfg.otherFeatures._prevChannelNumTicks = 0
end



-- Draw channel ticks on the cast bar
local function ShowChannelTicks(unit, numTicks, pos)
    -- Hide or create the ticks
    CASTBAR_API:HideChannelTicks(unit)
    local bar = UCB.castBar[unit]
    if not bar.channelTicks then bar.channelTicks = {} end

    local cfg = CFG_API.GetValueConfig(unit)
	local barWidth = cfg.general.actualBarWidth

	if pos == nil then
        -- CASE 1: no explicit positions table -> classic evenly-spaced ticks using numTicks
		for i = 1, numTicks - 1 do
			local tick = bar.channelTicks[i]
			if not tick then
				tick = bar.status:CreateTexture(nil, "OVERLAY")
				bar.channelTicks[i] = tick
			end
            CreateTick(unit, tick, (i / numTicks) * barWidth, bar.status)
		end
    else
        -- CASE 2: positions provided -> pos is an array of x offsets FROM THE LEFT
        -- Example: local positions = EvokerDisintegrateTicks:GetPositions(barWidth)
        --          PlayersCastbars:ShowChannelTicks(bar, nil, positions)
        local positions = pos
        local count = #positions
        for i = 1, count do
            local tick = bar.channelTicks[i]
            if not tick then
                tick = bar.status:CreateTexture(nil, "OVERLAY")
                bar.channelTicks[i] = tick
            end
            CreateTick(unit, tick, positions[i], bar.status)
        end
        numTicks = count -- Update numTicks to reflect actual number of ticks shown based on positions table
	end

    -- Hide unused ticks
    if cfg.otherFeatures._prevChannelNumTicks > numTicks then
        for i = numTicks + 1, cfg.otherFeatures._prevChannelNumTicks do
            if bar.channelTicks[i] then bar.channelTicks[i]:Hide() end
        end
    end
    cfg.otherFeatures._prevChannelNumTicks = numTicks
end

-- Assign channel ticks based on spellID and event type
function CASTBAR_API:AssignChannelTicks(unit, spellID, event)
    local bar = UCB.castBar[unit]
    local cfg = CFG_API.GetValueConfig(unit)

    -- Player main, targets, focus,
    if UnitIsPlayer(unit) then
        if not cfg.otherFeatures.showChannelTicks then return end

        local classCFG = cfg.CLASSES[UCB.className]
        if not classCFG.showChannelTicks then return end
        local spellIDD = spellID
        
        -- Dynamic ticks
        if UCB.specID == 1467 and spellIDD == 356995 and classCFG.disintegrateDynamicTicks then
            local barWidth = cfg.general.actualBarWidth
            local startMS, endMS = tags.var[unit].sTime * 1000, tags.var[unit].eTime * 1000
            local mode, positions = Evoker_API:OnChannelEvent(event, barWidth, spellID, startMS, endMS)
            ShowChannelTicks(unit, nil, positions)
        -- Normal ticks based on spellID -> numTicks
        else
            local numTicks = GetChannelTickNumber(spellIDD, classCFG)
            if numTicks and numTicks > 0 then
                ShowChannelTicks(unit, numTicks, nil)
            end
        end

    end
end


-- Hide bar on channel stop event (for interrupted channels)
function CASTBAR_API:OnUnitSpellcastChannelStop(unit, castGUID, spellID)
    -- Only hide if not channeling anymore
    if UnitChannelInfo(unit) then return end
    local classCFG = CFG_API.GetValueConfig(unit).CLASSES[UCB.className]

    UCB.castBar[unit].group:Hide()
    UCB.castBar[unit]:SetScript("OnUpdate", nil)

    local cfg = CFG_API.GetValueConfig(unit)
    local barWidth = cfg.general.actualBarWidth

    -- Player main, targets, focus,
    if UnitIsPlayer(unit) then
        if UCB.specID == 1467 and spellID == 356995 and classCFG.disintegrateDynamicTicks then
            Evoker_API:OnChannelEvent("STOP", barWidth, spellID)
        end
        CASTBAR_API:HideChannelTicks(unit)
    end
end


function CASTBAR_API:OnUnitSpellcastChannelStart(unit, castGUID, spellID)
    if UCB.Preview_API.previewActive and UCB.Preview_API.previewActive[unit] then
        UCB.Preview_API:HidePreviewCastBar(unit)
    end
    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]
    local icon_texture = tags:updateVars(unit, castType)
    
    -- Failsafe
    if not tags.var[unit].sName or not tags.var[unit].sTime or not tags.var[unit].eTime then
        return
    end

    -- Set text, icon, queue window
    UCB.tags:setTextSameState(cfg.text, bar, "semiDynamic", unit, castType, false)
    UCB.tags:setTextSameState(cfg.text, bar, "dynamic", unit, castType, true)

    bar.icon:SetTexture(icon_texture)
    UCB.CASTBAR_API:AssignQueueWindow(unit, castType)

    CASTBAR_API:AssignChannelTicks(unit, spellID, "START")

    CASTBAR_API:SemiColourUpdate(bar)
    bar.status:SetMinMaxValues(0, math.max(tags.var[unit].dTime, 0.001))
    bar:SetScript("OnUpdate", function(bar, elapsed) UCB.CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, castType) end)
    bar.group:Show()
end

function CASTBAR_API:OnUnitSpellcastChannelUpdate(unit, castGUID, spellID)
    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]
    local icon_texture = tags:updateVars(unit, castType)

    -- Failsafe
    if not tags.var[unit].sName or not tags.var[unit].sTime or not tags.var[unit].eTime then
        return
    end

    -- Set text, icon, queue window
    UCB.tags:setTextSameState(cfg.text, bar, "semiDynamic", unit, castType, false)
    UCB.tags:setTextSameState(cfg.text, bar, "dynamic", unit, castType, true)
    
    bar.icon:SetTexture(icon_texture)
    UCB.CASTBAR_API:AssignQueueWindow(unit, castType)

    CASTBAR_API:AssignChannelTicks(unit, spellID, "UPDATE")
    bar.status:SetMinMaxValues(0, math.max(tags.var[unit].dTime, 0.001))
end
