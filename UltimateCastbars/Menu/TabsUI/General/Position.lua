local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.GeneralSettings_API = UCB.GeneralSettings_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local UIOptions = UCB.UIOptions
local GeneralSettings_API = UCB.GeneralSettings_API

function GeneralSettings_API:BuildPositionArgs(cfg, unit)
    local g = cfg

    local positionGrp = {
        type = "group",
        name = "Position",
        inline = false,
        order = 1,
        args = {
            anchorGrp = {
                type = "group",
                name = "Anchoring",
                inline = true,
                order = 1,
                args = {
                    customAnchor = {
                        type = "group",
                        name = "Anchoring Frame",
                        order = 1,
                        args = {
                            anchorNameHeader = {
                                type = "header", dialogControl = "UCB_Heading",
                                name = function()
                                    local defaultName = g._defaultAnchor or "UIParent"

                                    if g.useDefaultAnchor or g.anchorName == "" then
                                        return "Anchored frame: "..UIOptions.ColorText(UIOptions.green, defaultName)
                                    end

                                    if g._anchorCustomError then
                                        return "Anchored frame: "..UIOptions.ColorText(UIOptions.red, defaultName.."(Error: "..tostring(g.anchorName)..")")
                                    end

                                    if g._anchorFrameRef and g._anchorFrameRef ~= UIParent then
                                        return "Anchored frame: "..UIOptions.ColorText(UIOptions.green, g.anchorName)
                                    end

                                    return "Anchored frame: "..UIOptions.ColorText(UIOptions.turquoise, "Waiting for: "..tostring(g.anchorName))
                                end,
                                width = "full",
                                order = 1,
                            },
                            toggleDefault = {
                                type = "toggle", dialogControl = "UCB_CheckBox",
                                name = "Use Default Anchor - UIParent (anchorFrom and anchorTo will use different values between default/custom)",
                                order = 2,
                                width = "full",
                                get = function() return g.useDefaultAnchor end,
                                set = function(_, v)
                                    g.useDefaultAnchor = v
                                    if UCB.firstBuild then
                                        GeneralSettings_API:ResolveAnchorWithRetry(unit, g, {tries = g.anchorFrameTries, interval = g.anchorFrameInterval, delay = g.anchorDelay})
                                    else
                                        GeneralSettings_API:ResolveAnchorWithRetry(unit, g, {tries = g.anchorFrameTries, interval = g.anchorFrameInterval, delay = 0})
                                    end
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            anchorCustomInput = {
                                type = "input", dialogControl = "UCB_EditBox",
                                name = "Custom Anchor Frame",
                                order = 3,
                                width = 1.2,
                                get = function() return g.anchorName end,
                                set = function(_, value)
                                    g.anchorName = value
                                    if UCB.firstBuild then
                                        GeneralSettings_API:ResolveAnchorWithRetry(unit, g, {tries = g.anchorFrameTries, interval = g.anchorFrameInterval, delay = g.anchorDelay})
                                    else
                                        GeneralSettings_API:ResolveAnchorWithRetry(unit, g, {tries = g.anchorFrameTries, interval = g.anchorFrameInterval, delay = 0})
                                    end
                                    CASTBAR_API:UpdateCastbar(unit)
                                    GeneralSettings_API:addNewItemList(g.anchoredFrameList, value)
                                end,
                                disabled = function() return g.useDefaultAnchor end,
                            },
                            gap1 = {
                                order = 3.5,
                                type = "description",
                                name = " ",
                                width = 0.1
                            },
                            anchoredFrameList = {
                                type = "select",
                                name = "Previously used custom anchor frames",
                                order = 4,
                                width = 1,
                                values = function()
                                    local list = {}
                                    for _, fname in ipairs(g.anchoredFrameList or {}) do
                                        list[fname] = fname
                                    end
                                    return list
                                end,
                                get = function() return g.anchorName end,
                                set = function(_, value)
                                    g.anchorName = value
                                    if UCB.firstBuild then
                                        GeneralSettings_API:ResolveAnchorWithRetry(unit, g, {tries = g.anchorFrameTries, interval = g.anchorFrameInterval, delay = g.anchorDelay})
                                    else
                                        GeneralSettings_API:ResolveAnchorWithRetry(unit, g, {tries = g.anchorFrameTries, interval = g.anchorFrameInterval, delay = 0})
                                    end
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                                disabled = function() return g.useDefaultAnchor end,
                            },
                            gap2 = {
                                order = 3.5,
                                type = "description",
                                name = " ",
                                width = 0.1
                            },
                            clearFramesList = {
                                type = "execute", dialogControl = "UCB_Button",
                                name = "Clear Frame List",
                                order = 5,
                                width = 1,
                                func = function()
                                    g.anchoredFrameList = {}
                                    g.anchorName = ""
                                    GeneralSettings_API:ResolveAnchorWithRetry(unit, g, {tries = 1})
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                                disabled = function() return g.useDefaultAnchor or not g.anchoredFrameList or #g.anchoredFrameList == 0 end,
                            },
                            anchoringSettingsGrp = {
                                type = "group",
                                name = "Custom Anchoring Settings",
                                order = 6,
                                inline = true,
                                hidden = function() return g.useDefaultAnchor end,
                                args = {
                                    anchoringSettingsDescr = {
                                        type = "description",
                                        name = "If you notice that the castbar is not anchoring correctly to tyhe custom frame, you can add delay before it attempt to find the frame. "..
                                            "You can also adjust the number of tries and the interval between tries to find the frame. The total number of seconds it will try to find the frame is tries*interval. Increase either or both if the addon cant find the frame to anchor to.",
                                        order = 0.5,
                                        width = "full",
                                    },
                                    anchorDelay = {
                                        type = "range", dialogControl = "UCB_Slider",
                                        name = "Anchor Resolve Delay (s)",
                                        order = 1,
                                        width = 1,
                                        min = UIOptions.frameDelayMin,
                                        max = UIOptions.frameDelayMax,
                                        step = 0.1,
                                        get = function() return g.anchorDelay end,
                                        set = function(_, v)
                                            g.anchorDelay = v
                                            CASTBAR_API:UpdateCastbar(unit)
                                        end,
                                    },
                                    gap1 = {
                                        order = 1.5,
                                        type = "description",
                                        name = " ",
                                        width = 0.1
                                    },
                                    anchorTries = {
                                        type = "range", dialogControl = "UCB_Slider",
                                        name = "Anchor Resolve Max Tries",
                                        order = 2,
                                        width = 1,
                                        min = UIOptions.frameTriesMin,
                                        max = UIOptions.frameTriesMax,
                                        step = 1,
                                        get = function() return g.anchorFrameTries end,
                                        set = function(_, v)
                                            g.anchorFrameTries = v
                                            CASTBAR_API:UpdateCastbar(unit)
                                        end,
                                    },
                                    gap2 = {
                                        order = 2.5,
                                        type = "description",
                                        name = " ",
                                        width = 0.1
                                    },
                                    anchorInterval = {
                                        type = "range", dialogControl = "UCB_Slider",
                                        name = "Anchor Resolve Interval (s)",
                                        order = 3,
                                        width = 1,
                                        min = UIOptions.frameIntervalMin,
                                        max = UIOptions.frameIntervalMax,
                                        step = 0.01,
                                        get = function() return g.anchorFrameInterval end,
                                        set = function(_, v)
                                            g.anchorFrameInterval = v
                                            CASTBAR_API:UpdateCastbar(unit)
                                        end,
                                    }
                                }
                            }
                        }
                    },
                    normalAnchors = {
                        type = "group",
                        name = "Anchoring Settings",
                        order = 2,
                        inline = true,
                        args = {
                            anchorDesc = {
                                type = "description",
                                name = "Anchor point on the castbar to the anchor point on the anchoring frame. Default and custom modes have different values for these settings. IF USING DEFAULT U DONT SEE THE CASTBAR, SET THESE TO "..UIOptions.ColorText(UIOptions.turquoise ,"CENTER CENTER!"),
                                order = 0.5,
                            },
                            anchorFrom = {
                                type  = "select",
                                name  = "Anchor From (point on the castbar)",
                                order = 1,
                                width = 1.5,
                                values = UIOptions.anchors,
                                get = function()
                                    if g.useDefaultAnchor then
                                        return g.anchorFromDefault
                                    end
                                    return g.anchorFrom
                                end,
                                set = function(_, v)
                                    if g.useDefaultAnchor then
                                        g.anchorFromDefault = v
                                    else
                                        g.anchorFrom = v
                                    end
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            anchorTo = {
                                type  = "select",
                                name  = "Anchor To (point on the anchoring frame)",
                                order = 2,
                                width = 1.5,
                                values = UIOptions.anchors,
                                get = function()
                                    if g.useDefaultAnchor then
                                        return g.anchorToDefault
                                    end
                                    return g.anchorTo
                                end,
                                set = function(_, v)
                                    if g.useDefaultAnchor then
                                        g.anchorToDefault = v
                                    else
                                        g.anchorTo = v
                                    end
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                        }
                    },
                },
            },
            grpOffsets = {
                type = "group",
                name = "Offsets",
                inline = true,
                order = 2,
                args = {
                    offsetX = {
                        type  = "range", dialogControl = "UCB_Slider",
                        name  = "X",
                        min   = UIOptions.offsetMin_bar, max = UIOptions.offsetMax_bar, step = 1,
                        order = 2,
                        width = 1.5,
                        get   = function() return g.offsetX end,
                        set   = function(_, val)
                            g.offsetX = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    offsetY = {
                        type  = "range", dialogControl = "UCB_Slider",
                        name  = "Y",
                        min   = UIOptions.offsetMin_bar, max = UIOptions.offsetMax_bar, step = 1,
                        order = 3,
                        width = 1.5,
                        get   = function() return g.offsetY end,
                        set   = function(_, val)
                            g.offsetY = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    }
                }
            },
        },
    }
    return positionGrp
end