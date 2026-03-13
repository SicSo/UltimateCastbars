local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}
UCB.UIStructures = UCB.UIStructures or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local UIOptions = UCB.UIOptions
local OtherFeatures_API = UCB.OtherFeatures_API
local UIStructures = UCB.UIStructures
local LSM  = UCB.LSM


function OtherFeatures_API:BuildInverseMirrorOptions(unit, cfg)
    local inversMirrorGrp = {
        type   = "group",
        name   = "Inverse/Mirror Bar",
        inline = false,
        order  = 4,
        args = {
            inverseGrp = {
                type = "group",
                name = "Inverse Bar Options",
                inline = true,
                order = 1,
                args = {
                    inverseTagInfo = {
                        type = "description",
                        name = "These settings invert the bar animation.",
                        order = 1,
                    },
                    inverseBarCast = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name  = "Enable Inverse Bar Normal Cast (drain)",
                        order = 2,
                        width = "full",
                        get   = function() return cfg.invertBar.normal end,
                        set   = function(_, val)
                            cfg.invertBar.normal = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    inverseBarChannel = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name  = "Enable Inverse Bar Channelled Cast (fill)",
                        order = 3,
                        width = "full",
                        get   = function() return cfg.invertBar.channel end,
                        set   = function(_, val)
                            cfg.invertBar.channel = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    inverseBarEmpowered = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name  = "Enable Inverse Bar Empowered Cast (drain)",
                        order = 4,
                        width = "full",
                        get   = function() return cfg.invertBar.empowered end,
                        set   = function(_, val)
                            cfg.invertBar.empowered = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                }
            },
            mirrorGrp = {
                type = "group",
                name = "Mirror Bar Options",
                inline = true,
                order = 2,
                args = {
                    mirrorTagInfo = {
                        type = "description",
                        name = "Changes the direction of fill/drain. By default it is right->left for fill and left->right for drain, this option makes it the opposite.",
                        order = 1,
                    },
                    mirrorBarCast = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name  = "Enable Mirror Bar Normal Cast",
                        order = 2,
                        width = "full",
                        get   = function() return cfg.mirrorBar.normal end,
                        set   = function(_, val)
                            cfg.mirrorBar.normal = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    mirrorBarChannel = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name  = "Enable Mirror Bar Channelled Cast",
                        order = 3,
                        width = "full",
                        get   = function() return cfg.mirrorBar.channel end,
                        set   = function(_, val)
                            cfg.mirrorBar.channel = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    mirrorBarEmpowered = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name  = "Enable Mirror Bar Empowered Cast",
                        order = 4,
                        width = "full",
                        get   = function() return cfg.mirrorBar.empowered end,
                        set   = function(_, val)
                            cfg.mirrorBar.empowered = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                }
            }
        },
    }
    return inversMirrorGrp
end