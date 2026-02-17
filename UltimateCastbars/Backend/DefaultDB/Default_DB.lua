local _, UCB = ...
UCB.Default_DB = UCB.Default_DB or {}


local Default_Values = {
    global = {
        UseGlobalProfile = false,
        GlobalProfileName = "Default",
    },
    profile = {
        player = UCB.Default_DB.Player,
        target = UCB.Default_DB.Target,
        focus = UCB.Default_DB.Focus,
        debug = {
            enabled = false,
            _addonList = {}
        },
        misc = {
            lastUIPath = {},
        }
    }
}

function UCB:GetDefaultDB()
    return Default_Values
end