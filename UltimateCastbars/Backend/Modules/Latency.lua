local ADDON_NAME, UCB = ...

UCB.Latency = UCB.Latency or {}

local Latency = UCB.Latency

Latency.startTime = nil
Latency.sendTime = nil
Latency.worldLatency = select(4, GetNetStats())  / 1000

function Latency:OnSpellCastChanged(cancelledCast)
    self.startTime = GetTimePreciseSec()
end

function Latency:OnSpellCastSent(unit, target, castGUID, spellID)
    if not UCB:IsPlayer(unit, true) then return end
    self.sendTime = self.startTime
    self.startTime = nil
    self.worldLatency = select(4, GetNetStats()) / 1000
end

function Latency:OnSpellCastSuccess(unit, castGUID, spellID, castBarID)
    if not UCB:IsPlayer(unit, true) then return end
    self.sendTime = nil
end

