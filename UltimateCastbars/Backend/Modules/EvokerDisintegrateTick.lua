local ADDON_NAME, UCB = ...

UCB.CLASS_API = UCB.CLASS_API or {}
UCB.CLASS_API.Evoker = UCB.CLASS_API.Evoker or {}
local EvokerAPI = UCB.CLASS_API.Evoker


local EVOKER_CLASS_ID = 13
local DEVASTATION_SPEC_ID = 1467
local DISINTEGRATE_SPELL_ID = 356995

-- persistent state (only player needed)
EvokerAPI.state = EvokerAPI.state or {
	channeling = false,
	chaining = false,
	lastStartMs = 0,
	lastEndMs = 0,
}

local function IsEvoker()
	return select(3, UnitClass("player")) == EVOKER_CLASS_ID
end

local function IsDevastation()
	return PlayerUtil and PlayerUtil.GetCurrentSpecID and PlayerUtil.GetCurrentSpecID() == DEVASTATION_SPEC_ID
end

function EvokerAPI:GetMaxTicksAndBaseDuration()
	local maxTicks = C_SpellBook.IsSpellKnown(1219723) and 5 or 4
	local baseDuration = 3 * (C_SpellBook.IsSpellKnown(369913) and 0.8 or 1)
	return maxTicks, baseDuration
end

function EvokerAPI:GetHastedChannelDuration(baseDuration)
	local haste = 1 + (UnitSpellHaste("player") or 0) / 100
	return baseDuration / haste
end

-- Normal (non-chained) tick marks: matches your original "ticks" placement
-- returns x offsets FROM LEFT
function EvokerAPI:ComputeNormalPositions(barWidth)
	local maxTicks = self:GetMaxTicksAndBaseDuration()
	-- maxTickMarks = maxTicks - 2
	local count = maxTicks - 2
	if count <= 0 then return nil end

	local step = barWidth / (maxTicks - 1)

	local positions = {}
	for i = 1, count do
		-- original: anchored from RIGHT at -(i*step)
		-- convert to left offset:
		positions[#positions + 1] = barWidth - (i * step)
	end

	table.sort(positions)
	return positions
end

-- Chained tick marks: separate function dedicated to the "chaining Disintegrate" math
-- startTimeMs/endTimeMs are from UnitChannelInfo()
-- returns x offsets FROM LEFT
function EvokerAPI:ComputeChainedPositions(barWidth, startTimeMs, endTimeMs)

	local maxTicks, baseDuration = self:GetMaxTicksAndBaseDuration()

	local duration = (endTimeMs - startTimeMs) / 1000
	if duration <= 0 then return nil end

	local hasted = self:GetHastedChannelDuration(baseDuration)

	-- same as your original logic:
	local relativeInitial = 1 - (hasted / duration)
	local initialOffsetFromRight = barWidth * relativeInitial

	local step = (barWidth - initialOffsetFromRight) / (maxTicks - 1)

	local positions = {}
	for i = 1, (maxTicks - 1) do
		-- original: first mark only shown if initialOffsetFromRight > 0
		if not (i == 1 and initialOffsetFromRight <= 0) then
			local offsetFromRight = initialOffsetFromRight + (i - 1) * step
			local xFromLeft = barWidth - offsetFromRight
			positions[#positions + 1] = xFromLeft
		end
	end

	table.sort(positions)
	return positions
end

function EvokerAPI:ResetState()
	self.state.channeling = false
	self.state.chaining = false
	self.state.lastStartMs = 0
	self.state.lastEndMs = 0
end

-- Optional: a small helper that decides when we "entered chaining"
-- You can evolve this later if you find a better signal.
function EvokerAPI:ShouldEnterChaining()
	return self.state.channeling and not self.state.chaining
end

-- One function to call from your castbar handlers.
-- Returns:
--   mode = "normal" | "chained" | nil
--   positions = table of x offsets from left | nil
function EvokerAPI:OnChannelEvent(event, barWidth, spellID, startTimeMs, endTimeMs)
	if not IsEvoker() or not IsDevastation() then
		self:ResetState()
		return nil, nil
	end

	if spellID ~= DISINTEGRATE_SPELL_ID then
		-- not our spell; keep your addon free to do other tick logic
		self:ResetState()
		return nil, nil
	end

	if event == "START" then
		self.state.channeling = true
		self.state.chaining = false
		self.state.lastStartMs = startTimeMs or 0
		self.state.lastEndMs = endTimeMs or 0

		return "normal", self:ComputeNormalPositions(barWidth)

	elseif event == "UPDATE" then
		-- channel update while already channeling => chaining behavior
		if self:ShouldEnterChaining() then
			self.state.chaining = true
		end

		self.state.lastStartMs = startTimeMs or self.state.lastStartMs
		self.state.lastEndMs = endTimeMs or self.state.lastEndMs

		if self.state.chaining and startTimeMs and endTimeMs then
			return "chained", self:ComputeChainedPositions(barWidth, startTimeMs, endTimeMs)
		end

		-- if somehow update happens before we marked channeling, treat like normal
		self.state.channeling = true
		return "normal", self:ComputeNormalPositions(barWidth)

	elseif event == "STOP" then
		self:ResetState()
		return nil, nil
	end

	return nil, nil
end

