local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}
UCB.UIStructures = UCB.UIStructures or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options

local UIOptions = UCB.UIOptions
local OtherFeatures_API = UCB.OtherFeatures_API
local UIStructures = UCB.UIStructures
local LSM  = UCB.LSM



function OtherFeatures_API:BuildInstantGCDOptions(unit, cfg, bigCFG)
    local GCDBarGrp = {
        type   = "group",
        name   = "Instant Spells GCD Bar",
        inline = false,
        order  = 7,
        args = {
            latencyInfo = {
                type = "description",
                name = function()
                    return UIOptions.ColorText(UIOptions.turquoise, " Some instant spells are affected by the global cooldown (GCD). This bar shows the GCD duration for those spells. \n THIS IS NOT A NEW BAR, IT REPLACES THE NORMAL CASTBAR WHILE THERE IS NOT CAST GOING.")
                end,
                order = 1,
            },
            enableInstantGCDBar = {
                type = "toggle",
                dialogControl = "UCB_CheckBox",
                name  = "Enable",
                order = 2,
                width = "full",
                get   = function()
                    return cfg.instantGCD.enable
                end,
                set   = function(_, val)
                    cfg.instantGCD.enable = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            gcdTextGrp = {
                type   = "group",
                name   = "Instant GCD Text",
                inline = true,
                order  = 3,
                disabled = function()
                    return not cfg.instantGCD.enable
                end,
                args = {
                    openTextOptions = {
                        type = "execute", dialogControl = "UCB_Button",
                        name = "Open Text Options",
                        desc = "Open the text options for GCD castbar.",
                        order = 1,
                        width = 1,
                        func = function()
                            UCB:SelectGroup({"text"}, unit)
                        end,
                    },
                },
            },
            instantGCDBarOptionsGrp = {
                type   = "group",
                name   = "Instant GCD Bar Options",
                inline = true,
                order  = 4,
                disabled = function()
                    return not cfg.instantGCD.enable
                end,
                args = {
                    selectPreConfigureStyleGeneral = {
                        type = "select", --dialogControl = "UCB_Dropdown",
                        name = "Pre-configure Style",
                        order = 1,
                        hidden = function()
                            return not bigCFG.styleCastType.useGeneralStyle
                        end,
                        values = {
                            general = "General",
                        },
                        get = function()
                            return cfg.instantGCD.preConfigureStyle
                        end,
                        set = function(_, val)
                            cfg.instantGCD.preConfigureStyle = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    selectPreConfigureStyleAll = {
                        type = "select", --dialogControl = "UCB_Dropdown",
                        name = "Pre-configure Style",
                        order = 1,
                        hidden = function()
                            return bigCFG.styleCastType.useGeneralStyle
                        end,
                        values = {
                            general = "General",
                            normal = "Normal",
                            channel = "Channel",
                            empowered = "Empowered",
                        },
                        get = function()
                            return cfg.instantGCD.preConfigureStyle
                        end,
                        set = function(_, val)
                            cfg.instantGCD.preConfigureStyle = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    gap = {
                        type = "description",
                        name = " ",
                        order = 2,
                        width = "full",
                    },
                    useCustomStyle = {
                        type = "toggle",
                        dialogControl = "UCB_CheckBox",
                        name  = "Use Custom Style",
                        order = 3,
                        width = "full",
                        get   = function()
                            return cfg.instantGCD.useCustomStyle
                        end,
                        set   = function(_, val)
                            cfg.instantGCD.useCustomStyle = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                },
            },
            customStyleTab = {
                type   = "group",
                name   = "Instant GCD Style Options",
                inline = false,
                order  = 5,
                hidden = function()
                    return not cfg.instantGCD.useCustomStyle
                end,
                args = UIStructures:BuildStyleWindow(cfg.instantGCD.customStyle, unit),
            },
        },
    }

    return GCDBarGrp
end