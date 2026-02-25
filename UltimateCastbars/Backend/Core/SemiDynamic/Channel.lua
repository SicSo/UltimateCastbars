local ADDON_NAME, UCB = ...

UCB.tags     = UCB.tags     or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.CLASS_API = UCB.CLASS_API or {}
UCB.CLASS_API.Evoker = UCB.CLASS_API.Evoker or {}
UCB.Preview_API = UCB.Preview_API or {}

local tags = UCB.tags
local CASTBAR_API = UCB.CASTBAR_API
local Evoker_API = UCB.CLASS_API.Evoker

local castType = "channel"

local function CastbarOnUpdate(bar, elapsed)
    local unit = bar._ucbUnit
    local cfg  = bar._ucbCfg
    local castType = bar._ucbCastType
    local vars = bar._ucbVars
    local spellID = bar._ucbSpellID
    local remainig = UCB.CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, castType, vars)
    if unit == "player" and remainig < -0.001 then
        CASTBAR_API:OnUnitSpellcastChannelStop(unit, nil, spellID)
    end
end

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

local function CreateTick(cfg, bar, index, position)
    local otherCFG = cfg.otherFeatures
    local anchor = bar.frames.overlay

    local tick = bar.channelTicks[index]
    if not tick then
        tick = anchor:CreateTexture(nil, "OVERLAY")
        bar.channelTicks[index] = tick
    end

    -- Useful tick variables
	local tickHeight = cfg.general.barHeight
    local tickWidth, tickColour, useTickTexture, tickTexture = otherCFG._tickWidth, otherCFG._tickColour, otherCFG._useTickTexture, otherCFG._tickTexture

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

function CASTBAR_API:HideChannelTicks(bar, cfg)
    if cfg._prevChannelNumTicks == 0 then return end

    if bar.channelTicks and cfg._prevChannelNumTicks > #bar.channelTicks then
        cfg._prevChannelNumTicks = #bar.channelTicks
    end

    for i = 1, cfg._prevChannelNumTicks do
        if bar.channelTicks[i] then
            bar.channelTicks[i]:Hide()
        end
    end
    cfg._prevChannelNumTicks = 0
end

-- Draw channel ticks on the cast bar
local function ShowChannelTicks(bar, cfg, numTicks, pos)
    local otherCFG = cfg.otherFeatures

	if pos == nil then
        -- CASE 1: no explicit positions table -> classic evenly-spaced ticks using numTicks
        local barWidth = cfg.general.actualBarWidth
		for i = 1, numTicks - 1 do
            CreateTick(cfg, bar, i, (i / numTicks) * barWidth)
		end
    else
        -- CASE 2: positions provided -> pos is an array of x offsets FROM THE LEFT
        local positions = pos
        local count = #positions
        for i = 1, count do
            CreateTick(cfg, bar, i, positions[i])
        end
        numTicks = count -- Update numTicks to reflect actual number of ticks shown based on positions table
	end

    -- Hide unused ticks
    if otherCFG._prevChannelNumTicks > numTicks then
        for i = numTicks + 1, otherCFG._prevChannelNumTicks do
            if bar.channelTicks[i] then bar.channelTicks[i]:Hide() end
        end
    end
    otherCFG._prevChannelNumTicks = numTicks
end

-- Assign channel ticks based on spellID and event type
function CASTBAR_API:AssignChannelTicks(unit, spellID, event)
    local cfg = UCB.GetValueConfig(unit)
    local bar = UCB.castBar[unit]

    -- Player main, targets, focus,
    if UnitIsPlayer(unit) then
        if not cfg.otherFeatures.showChannelTicks then return end

        if unit == "player" then
            local classCFG = cfg.CLASSES[UCB.className]
            if not classCFG.showChannelTicks then return end
            local spellIDD = spellID
            
            -- Dynamic ticks
            if UCB.specID == 1467 and spellIDD == 356995 and classCFG.disintegrateDynamicTicks then
                local vars = tags.var[unit]
                local barWidth = cfg.general.actualBarWidth
                local startMS, endMS = vars.sTime * 1000, vars.eTime * 1000
                local mode, positions = Evoker_API:OnChannelEvent(event, barWidth, spellID, startMS, endMS)
                ShowChannelTicks(bar, cfg, nil, positions)
            -- Normal ticks based on spellID -> numTicks
            else
                local numTicks = GetChannelTickNumber(spellIDD, classCFG)
                if numTicks and numTicks > 0 then
                    ShowChannelTicks(bar, cfg, numTicks, nil)
                else
                    CASTBAR_API:HideChannelTicks(bar, cfg.otherFeatures)
                end
            end
        else
            local _, unitClassId, _ = UnitClass(unit)
            --local unitSpecID = GetInspectSpecialization(unit)
            local classCFG = cfg.CLASSES[unitClassId]
            if not classCFG.showChannelTicks then return end

            --print(unitSpecID)
            --local spec_data = classCFG.specs[unitSpecID]
            --if not classCFG.enableTick and not spec_data.enableTick then return end
            if not classCFG.enableTick then return end

            local numTicks
            --if spec_data.enableTick then
            --    numTicks =  spec_data.tickNumber
            --else
                numTicks = classCFG.tickNumber
            --end
            ShowChannelTicks(bar, cfg, numTicks, nil)
        end

    end
end

---------------------------------------------------- MAIN -------------------------------------------------
function CASTBAR_API:OnUnitSpellcastChannelStart(unit, castGUID, spellID, castBarID, resumeCast)
    local show, cfg, bar, vars = CASTBAR_API:CastSetup(unit, castGUID, spellID, resumeCast, castType)
    if not show then return end
    CASTBAR_API:AssignChannelTicks(unit, spellID, "START")
    -- Set colours
    CASTBAR_API:SemiColourUpdate(unit, bar)
    CASTBAR_API:CastOnUpdateSetup(bar, unit, cfg, vars, castType, spellID, CastbarOnUpdate)
end

function CASTBAR_API:OnUnitSpellcastChannelUpdate(unit, castGUID, spellID, castBarID)
    print("UPDATE")
    local show = CASTBAR_API:CastUpdate(unit, castGUID, spellID, castType)
    print(show)
    if not show then return end
    CASTBAR_API:AssignChannelTicks(unit, spellID, "UPDATE")
end

function CASTBAR_API:OnUnitSpellcastChannelStop(unit, castGUID, spellID, castBarID)
    -- Only hide if not channeling anymore
    --if UnitChannelInfo(unit) then return end
    local bar = UCB.castBar[unit]
    if bar and bar.flags.castActive == true then
        bar.group:Hide()
        bar:SetScript("OnUpdate", nil)
        bar.flags.castActive = false
        bar.flags.prevType = nil
        bar._ucbUnit, bar._ucbCfg, bar._ucbCastType, bar._ucbVars, bar._ucbSpellID = nil, nil, nil, nil, nil
        local cfg = UCB.GetValueConfig(unit)
        local classCFG = cfg.CLASSES[UCB.className]
        -- Player main, targets, focus,
        if unit == "player" then
            if not spellID then spellID = bar.current_spellID end
            if UCB.specID == 1467 and spellID == 356995 and classCFG.disintegrateDynamicTicks then
                local barWidth = cfg.general.actualBarWidth
                Evoker_API:OnChannelEvent("STOP", barWidth, spellID)
            end
        end
        bar.current_spellID = nil
        CASTBAR_API:HideChannelTicks(bar, cfg.otherFeatures)
    end
end
