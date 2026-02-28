local _, UCB = ...
UCB.Default_DB = UCB.Default_DB or {}


local Default_Values = {
    global = {
        UseGlobalProfile = false,
        GlobalProfileName = "Default",
    },
    profile = {
        player = UCB.Default_DB.player,
        target = UCB.Default_DB.target,
        focus = UCB.Default_DB.focus,
        debug = {
            enabled = false,
            _addonList = {}
        },
        misc = {
            lastUIPath = {},
            __schemaVersion = 0, -- for migrations
        }
        
    },
}

function UCB:GetDefaultDB()
    return Default_Values
end