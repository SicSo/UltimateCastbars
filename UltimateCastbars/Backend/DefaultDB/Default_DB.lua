local _, UCB = ...
UCB.Default_DB = UCB.Default_DB or {}


--iconInternalOffsetMltiplier = {player = -1, target = 1, focus = 1},
--iconAnchors = {player = "LEFT", target = "RIGHT", focus = "RIGHT"},


local Default_Values = {
    global = {
        UseGlobalProfile = false,
        GlobalProfileName = "Default",
    },
    profile = {
        player = UCB.Default_DB.Player,
        target = UCB.Default_DB.Target,
        focus = UCB.Default_DB.Focus,
    }
}

function UCB:GetDefaultDB()
    return Default_Values
end