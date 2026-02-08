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

-- Utility

-- Table of common channeled spells and their tick counts
--[[
local ChannelTicks = {
    -- [spellID] = number of ticks
    [5143]    = 5,   -- Arcane Missiles (Mage)
    [15407]   = 4,   -- Mind Flay (Priest)
    [47540]   = 3,   -- Penance (Priest, default 3, can be 4 with talent)
    [263165]  = 8,   -- Void Torrent (Priest, Shadowlands/BFA, can vary)
    [689]     = 6,   -- Drain Life (Warlock)
    [198590]  = 5,   -- Drain Soul (Warlock)
    [196447]  = 15,  -- Channel Demonfire (Warlock, 15 bolts)
    [257044]  = 7,   -- Rapid Fire (Hunter, 7 shots)
    [113656]  = 4,   -- Fists of Fury (Monk, 4 ticks)
    [115175]  = 8,   -- Soothing Mist (Monk, 8 ticks)
    [356995]  = 4,   -- Disintegrate (Evoker, 4 ticks)
    [48045]   = 5,   -- Mind Sear (Priest)
    [755]     = 10,  -- Health Funnel (Warlock)
    -- Add more or adjust as needed
    -- If you want to change a tick count, just update the value above.
}
--]]

local ChannelTicks = {
    -- [spellID] = number of ticks
    [62]    = 5,   -- Arcane Missiles (Mage) - Arcane
    [258]   = 4,   -- Mind Flay (Priest) - Shadow
    [256]   = 3,   -- Penance (Priest, default 3, can be 4 with talent) - Disc
    --[258]  = 8,   -- Void Torrent (Priest, Shadowlands/BFA, can vary) - Shadow
    [265]     = 6,   -- Drain Life (Warlock) - Affliction
    --[265]  = 5,   -- Drain Soul (Warlock) - Affliction
    [267]  = 15,  -- Channel Demonfire (Warlock, 15 bolts) - Destruction
    [254]  = 7,   -- Rapid Fire (Hunter, 7 shots) - MM
    [269]  = 4,   -- Fists of Fury (Monk, 4 ticks) - WW
    [270]  = 8,   -- Soothing Mist (Monk, 8 ticks) - Mist
    [1467]  = 4,   -- Disintegrate (Evoker, 4 ticks) - Dev
    --[258]   = 5,   -- Mind Sear (Priest) - Shadow
    [266]     = 10,  -- Health Funnel (Warlock) - Demo
}


local function ChannelTicksNum(specID)
    if specID == nil then
        return nil
    end
    if specID == 5143 then
        return 5
    elseif specID == 15407 then
        return 4
    elseif specID == 47540 then
        return 3
    elseif specID == 263165 then
        return 8
    elseif specID == 689 then
        return 6
    elseif specID == 198590 then
        return 5
    elseif specID == 196447 then
        return 15
    elseif specID == 257044 then
        return 7
    elseif specID == 113656 then
        return 4
    elseif specID == 115175 then
        return 8
    elseif specID == 356995 then
        return 4
    elseif specID == 48045 then
        return 5
    elseif specID == 755 then
        return 10
    else
        return 3
    end
end

local function CreateTick(unit, tick, position, anchor)
    local cfg = CFG_API.GetValueConfig(unit)
    -- Useful tick variables
	local tickHeight = cfg.general.barHeight
    local tickWidth  = cfg.otherFeatures.channelTickWidth
    local tickColour = cfg.otherFeatures.channelTickColour

    --local tick = bar.channelTicks[i]

    --if not tick then
    --    tick = bar.status:CreateTexture(nil, "OVERLAY")
    --    bar.channelTicks[i] = tick
    --end

    tick:SetSize(tickWidth, tickHeight)
    if cfg.otherFeatures.useTickTexture then
        tick:SetTexture(cfg.otherFeatures.tickTexture)
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
        local spellIDD = spellID
        local barWidth = cfg.general.actualBarWidth
        local numTicks = ChannelTicksNum(spellIDD)

        if UCB.specID == 1467 and Evoker_API and Evoker_API.OnChannelEvent then
            local startMS, endMS = tags.var[unit].sTime * 1000, tags.var[unit].eTime * 1000
            local mode, positions = Evoker_API:OnChannelEvent(event, barWidth, spellID, startMS, endMS)
            ShowChannelTicks(unit, numTicks, positions)
        else
            ShowChannelTicks(unit, numTicks, nil)
        end
    end
end


-- Hide bar on channel stop event (for interrupted channels)
function CASTBAR_API:OnUnitSpellcastChannelStop(unit, castGUID, spellID)
    -- Only hide if not channeling anymore
    if UnitChannelInfo(unit) then return end

    UCB.castBar[unit].group:Hide()
    UCB.castBar[unit]:SetScript("OnUpdate", nil)

    local cfg = CFG_API.GetValueConfig(unit)
    local barWidth = cfg.general.actualBarWidth

    -- Player main, targets, focus,
    if UnitIsPlayer(unit) then
        if UCB.specID == 1467 and Evoker_API and Evoker_API.OnChannelEvent then
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
    --if not tags.var[unit].sName or not tags.var[unit].sTime or not tags.var[unit].eTime then
    --    if bar then bar:Hide() end
    --    return
    --end

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
    --if not tags.var[unit].sName or not tags.var[unit].sTime or not tags.var[unit].eTime then
    --    if bar then bar:Hide() end
    --    return
    --end

    -- Set text, icon, queue window
    UCB.tags:setTextSameState(cfg.text, bar, "semiDynamic", unit, castType, false)
    UCB.tags:setTextSameState(cfg.text, bar, "dynamic", unit, castType, true)
    
    bar.icon:SetTexture(icon_texture)
    UCB.CASTBAR_API:AssignQueueWindow(unit, castType)

    CASTBAR_API:AssignChannelTicks(unit, spellID, "UPDATE")
    bar.status:SetMinMaxValues(0, math.max(tags.var[unit].dTime, 0.001))
end
