local ADDON_NAME, UCB = ...

UCB.Latency = UCB.Latency or {}

local Latency = UCB.Latency


Latency.startTime = nil
Latency.sendTime = nil



function Latency:OnSpellCastChanged(cancelledCast)
    self.startTime = GetTime()
end

function Latency:OnSpellCastSent(unit, target, castGUID, spellID)
    if unit ~= "player" then return end
    self.sendTime = self.startTime
    self.startTime = nil
end

function Latency:OnSpellCastSuccess(unit, castGUID, spellID, castBarID)
    if unit ~= "player" then return end
    self.sendTime = nil
end

