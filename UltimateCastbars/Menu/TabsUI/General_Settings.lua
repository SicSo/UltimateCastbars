local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.GeneralSettings_API = UCB.GeneralSettings_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local GeneralSettings_API = UCB.GeneralSettings_API



local function BuildFramePickerArgs(args, unit)
    local g = GetCfg(unit).general

    args.framePickerGrp = {
        type = "group",
        name = "Frame Picker",
        inline = true,
        order = 0,
        args = {
                info = {
                    order = 1,
                    width = "full",
                    type = "description",
                    name ="This is a helepr functionality to find the desired frame within your UI. You can use it to find frame to anchor the castbar to or sync the width or height."..
                        "To do so, click the 'Grab Mouseover Frame' button and then hover on any frame within the UI. The frame will be highlighted in green. If you are looking for another frame on another strata,".. 
                        "press the keys UP/DOWN arrows to find change the strata level. Once you found the desired, click CTRL while hovering. The name of the frame will be shown in the 'Frame clicked' field and can be copied from there. "..
                        "You can copy the value from the textbox above and paste it into the 'Custom Anchor Frame', 'Custom Width Frame' or 'Custom Height Frame' field."
                },
                frameClickedLast = {
                    type = "header",
                    name = function()
                        return "Frame clicked last: "..UIOptions.ColorText(UIOptions.turquoise, g.frameLastClicked)
                    end,
                    width = "full",
                    order = 1,
                },
                grabButton = {
                    type = "execute",
                    name = "Grab Mouseover Frame",
                    order = 2,
                    width = 1.5,
                    func = function()
                            UCB.SimpleFramePickerObj:Start(
                                function(frameName)
                                    g.frameLastClicked = frameName
                                    UCB:RefreshGUI({ "player", "general"})
                                end,
                                function()
                                    --print("Picker cancelled.")
                                end
                            )
                    end,
                },
                gap1 = {
                order = 2.5,
                type = "description",
                name = " ",
                width = 0.1
                },
                frameLastClickedCopy = {
                    type = "input",
                    name = "Frame clicked",
                    width = 1.2,
                    order = 3,
                    get = function() return g.frameLastClicked end,
                    set = function() end,
                },

            }
        }
end
local function BuildPositionArgs(args, unit)
    local g = GetCfg(unit).general

    args.positionGrp = {
        type = "group",
        name = "Castbar Position",
        inline = true,
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
                                type = "header",
                                name = function()
                                    local defaultName = g._defaultAnchor or "UIParent"

                                    if g.useDefaultAnchor or g.anchorName == "" then
                                        return "Anchored frame: "..UIOptions.ColorText(UIOptions.green, defaultName)
                                    end

                                    if g._anchorCustomError then
                                        return "Anchored frame: "..UIOptions.ColorText(UIOptions.red, defaultName.."(Error: "..tostring(g.anchorName)..")")
                                    end

                                    -- If resolved, show it; otherwise show “waiting…”
                                    if g._anchorFrameRef and g._anchorFrameRef ~= UIParent then
                                        return "Anchored frame: "..UIOptions.ColorText(UIOptions.green, g.anchorName)
                                    end

                                    return "Anchored frame: "..UIOptions.ColorText(UIOptions.turquoise, "Waiting for: "..tostring(g.anchorName))
                                end,
                                width = "full",
                                order = 1,
                            },
                            toggleDefault = {
                                type = "toggle",
                                name = "Use Default Anchor (UIParent)",
                                order = 2,
                                width = "full",
                                get = function() return g.useDefaultAnchor end,
                                set = function(_, v)
                                    g.useDefaultAnchor = v
                                    if UCB.firstBuild then
                                        GeneralSettings_API:ResolveAnchorWithRetry(unit, g, {tries=g.anchorFrameTries, interval=g.anchorFrameInterval, delay=g.anchorDelay})
                                    else
                                        GeneralSettings_API:ResolveAnchorWithRetry(unit, g, {tries=g.anchorFrameTries, interval=g.anchorFrameInterval, delay=0})
                                    end
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            anchorCustomInput = {
                                type = "input",
                                name = "Custom Anchor Frame",
                                order = 3,
                                width = 1.2,
                                get = function() return g.anchorName end,
                                set = function(_, value) 
                                    g.anchorName = value
                                    if UCB.firstBuild then
                                        GeneralSettings_API:ResolveAnchorWithRetry(unit, g, {tries=g.anchorFrameTries, interval=g.anchorFrameInterval, delay=g.anchorDelay})
                                    else
                                        GeneralSettings_API:ResolveAnchorWithRetry(unit, g, {tries=g.anchorFrameTries, interval=g.anchorFrameInterval, delay=0})
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
                                        GeneralSettings_API:ResolveAnchorWithRetry(unit, g, {tries=g.anchorFrameTries, interval=g.anchorFrameInterval, delay=g.anchorDelay})
                                    else
                                        GeneralSettings_API:ResolveAnchorWithRetry(unit, g, {tries=g.anchorFrameTries, interval=g.anchorFrameInterval, delay=0})
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
                                type = "execute",
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
                                        type = "range",
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
                                        type = "range",
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
                                        type = "range",
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
                            anchorFrom = {
                                type  = "select",
                                name  = "Anchor From (point on the castbar)",
                                order = 1,
                                width = 1.5,
                                values = UIOptions.anchors,
                                get = function() return g.anchorFrom end,
                                set = function(_, v)
                                    g.anchorFrom = v
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            anchorTo = {
                                type  = "select",
                                name  = "Anchor To (point on the anchoring frame)",
                                order = 2,
                                width = 1.5,
                                values = UIOptions.anchors,
                                get = function() return g.anchorTo end,
                                set = function(_, v)
                                    g.anchorTo = v
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
                        type  = "range",
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
                        type  = "range",
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
end

local function BuildSizeArgs(args, unit)
    local g = GetCfg(unit).general

    args.sizeGrp = {
        type = "group",
        name = "Castbar Size",
        inline = true,
        order = 2,
        args = {
            toggleGroup = {
                type = "group",
                name = "Size Control Mode",
                inline = true,
                order = 1,
                args = {
                    manualWidthToogle = {
                        type = "toggle",
                        name = "Use manual Width",
                        order = 1,
                        width = 1,
                        get = function() return g.manualWidth end,
                        set = function(_, v)
                            g.manualWidth = v
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    manualHeightToogle = {
                        type = "toggle",
                        name = "Use manual Height",
                        order = 2,
                        width = 1,
                        get = function() return g.manualHeight end,
                        set = function(_, v)
                            g.manualHeight = v
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    borderWidthToogle = {
                        type = "toggle",
                        name = "Include Border in Width",
                        order = 3,
                        width = 1,
                        get = function() return g.includeBorderInWidth end,
                        set = function(_, v)
                            g.includeBorderInWidth = v
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    borderHeightToogle = {
                        type = "toggle",
                        name = "Include Border in Height",
                        order = 4,
                        width = 1,
                        get = function() return g.includeBorderInHeight end,
                        set = function(_, v)
                            g.includeBorderInHeight = v
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    syncSettingsGrp = {
                        type = "group",
                        name = "Custom Sync Settings",
                        inline = true,
                        order = 5,
                        hidden = function() return not (g.manualWidth or g.manualHeight) end,
                        args = {
                            syncDescr = {
                                type = "description",
                                name = "When syncing width/height across bars, delay is applied to prevent size issues. Increase if you notice bars are sizing incorrectly."..
                                 " Sync tries and interval determine how long it will attempt to find the frame. The total number of seounds is tries*interval. Increase either or both if the addon cant find the frame to sync to.",
                                order = 0.5,
                                width = "full",
                            },
                            syncDelay = {
                                type = "range",
                                name = "Sync Delay (s)",
                                order = 1,
                                width = 1,
                                min = UIOptions.frameDelayMin,
                                max = UIOptions.frameDelayMax,
                                step = 0.1,
                                get = function() return g.syncDelay end,
                                set = function(_, v)
                                    g.syncDelay = v
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            gap1 = {
                            order = 1.5,
                            type = "description",
                            name = " ",
                            width = 0.1
                            },
                            numTries = {
                                type = "range",
                                name = "Sync Max Tries",
                                order = 2,
                                width = 1,
                                min = UIOptions.frameTriesMin,
                                max = UIOptions.frameTriesMax,
                                step = 1,
                                get = function() return g.syncFrameTries end,
                                set = function(_, v)
                                    g.syncFrameTries = v
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            gap2 = {
                            order = 2.5,
                            type = "description",
                            name = " ",
                            width = 0.1
                            },
                            interval = {
                                type = "range",
                                name = "Sync Interval (s)",
                                order = 3,
                                width = 1,
                                min = UIOptions.frameIntervalMin,
                                max = UIOptions.frameIntervalMax,
                                step = 0.01,
                                get = function() return g.syncFrameInterval end,
                                set = function(_, v)
                                    g.syncFrameInterval = v
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                        }
                    }
                }
            },
            widthFrameGroup = {
                type = "group",
                name = "Width Frame",
                inline = true,
                order = 2,
                hidden = function()
                    return g.manualWidth
                end,
                args = {
                    widthFrameTitle = {
                        type = "header",
                        name = function()
                            local str1
                            local widthFrame = g._widthFrameRef or GeneralSettings_API:getFrame(g.widthInput) or UIParent
                            if g.widthInput == "" or g._widthFrameError or widthFrame == UIParent then
                                str1 = "Frame "..UIOptions.ColorText(UIOptions.red, g.widthInput).." not used; ".."Width: "..g.barWidth.." (manual)"
                            else
                                local width = widthFrame and widthFrame:GetWidth()
                                if width < g.widthMinValue then
                                    str1 = "Frame "..UIOptions.ColorText(UIOptions.red, g.widthInput).." not used; Frame width: "..UIOptions.ColorText(UIOptions.red, width).." < width min value: "..UIOptions.ColorText(UIOptions.red, g.widthMinValue)
                                else
                                    str1 = "Frame "..UIOptions.ColorText(UIOptions.green, g.widthInput).." used"
                                end
                            end
                            return str1
                        end,
                        order = 1,
                        width = "full",
                    },
                    widthFrameStats = {
                        type = "header",
                        name = function ()
                            local frame = g._widthFrameRef or GeneralSettings_API:getFrame(g.widthInput) or UIParent
                            if frame and frame ~= UIParent then
                                return "Width: "..UIOptions.ColorText(UIOptions.turquoise, frame:GetWidth()).."; Height: "..UIOptions.ColorText(UIOptions.turquoise, frame:GetHeight())
                            else
                                return UIOptions.ColorText(UIOptions.red, "Frame not found")
                            end
                        end,
                        order = 2,
                        width = "full",
                        hidden = function()
                            local f = g._widthFrameRef or GeneralSettings_API:getFrame(g.widthInput) or UIParent
                            return g.widthInput == "" or g._widthFrameError or f == UIParent
                        end,
                    },
                    widthFrameInput = {
                        type = "input",
                        name = "Custom Width Frame",
                        order = 3,
                        width = 1.2,
                        get = function() return g.widthInput end,
                        set = function(_, value)
                            g.widthInput = value
                            if UCB.firstBuild then
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "width", value, {tries=g.syncFrameTries, interval=g.syncFrameInterval, delay=g.syncDelay})
                            else
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "width", value, {tries=g.syncFrameTries, interval=g.syncFrameInterval, delay=0})
                            end
                            CASTBAR_API:UpdateCastbar(unit)
                            GeneralSettings_API:addNewItemList(g.frameSizeList, value)
                        end,
                    },
                    gap2 = {
                    order = 3.5,
                    type = "description",
                    name = " ",
                    width = 0.1
                    },
                    widthFrameSelect = {
                        type = "select",
                        name = "Previously used frames to sync",
                        order = 4,
                        width = 1,
                        values = function()
                            local list = {}
                            for _, fname in ipairs(g.frameSizeList or {}) do
                                list[fname] = fname
                            end
                            return list
                        end,
                        get = function() return g.widthInput end,
                       set = function(_, value)
                            g.widthInput = value
                            if UCB.firstBuild then
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "width", value, {tries=g.syncFrameTries, interval=g.syncFrameInterval, delay=g.syncDelay})
                            else
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "width", value, {tries=g.syncFrameTries, interval=g.syncFrameInterval, delay=0})
                            end
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    gap3 = {
                    order = 4.5,
                    type = "description",
                    name = " ",
                    width = 0.1
                    },
                    widthMinValue = {
                        type = "range",
                        name = "Width Min Value",
                        min = UIOptions.widthMin_bar, max = UIOptions.widthMax_bar, step = 1,
                        order = 5,
                        width = 1.3,
                        get = function() return g.widthMinValue end,
                        set = function(_, val)
                            g.widthMinValue = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    }
                }
            },
            heightFrameGroup = {
                type = "group",
                name = "Height Frame",
                inline = true,
                order = 3,
                hidden = function()
                    return g.manualHeight
                end,
                args = {
                    heigthFrameTitle = {
                        type = "header",
                        name = function()
                            local str1
                            local heightFrame = g._heightFrameRef or GeneralSettings_API:getFrame(g.heightInput) or UIParent
                            if g.heightInput == "" or g._heightFrameError or heightFrame == UIParent then
                                str1 = "Frame "..UIOptions.ColorText(UIOptions.red, g.heightInput).." not used; ".."Height: "..g.barHeight.." (manual)"
                            else
                                local height = heightFrame and heightFrame:GetHeight()
                                if height < g.heightMinValue then
                                    str1 = "Frame "..UIOptions.ColorText(UIOptions.red, g.heightInput).." not used; Frame height: "..UIOptions.ColorText(UIOptions.red, height).." < height min value: "..UIOptions.ColorText(UIOptions.red, g.heightMinValue)
                                else
                                    str1 = "Frame "..UIOptions.ColorText(UIOptions.green, g.heightInput).." used"
                                end
                            end
                            return str1
                        end,
                        order = 1,
                        width = "full",
                    },
                    heightFrameStats = {
                        type = "header",
                        name = function ()
                            local frame = g._heightFrameRef or GeneralSettings_API:getFrame(g.heightInput) or UIParent
                            if frame and frame ~= UIParent then
                                return "Width: "..UIOptions.ColorText(UIOptions.turquoise, frame:GetWidth()).."; Height: "..UIOptions.ColorText(UIOptions.turquoise, frame:GetHeight())
                            else
                                return UIOptions.ColorText(UIOptions.red, "Frame not found")
                            end
                        end,
                        order = 2,
                        width = "full",
                        hidden = function()
                            local f = g._heightFrameRef or GeneralSettings_API:getFrame(g.heightInput) or UIParent
                            return g.heightInput == "" or g._heightFrameError or f == UIParent
                        end,
                    },
                    heightFrameInput = {
                        type = "input",
                        name = "Custom Height Frame",
                        order = 3,
                        width = 1.2,
                        get = function() return g.heightInput end,
                        set = function(_, value)
                            g.heightInput = value
                            if UCB.firstBuild then
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "height", value, {tries=g.syncFrameTries, interval=g.syncFrameInterval, delay=g.syncDelay})
                            else
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "height", value, {tries=g.syncFrameTries, interval=g.syncFrameInterval, delay=0})
                            end
                            CASTBAR_API:UpdateCastbar(unit)
                            GeneralSettings_API:addNewItemList(g.frameSizeList, value)
                            end,
                    },
                    gap2 = {
                    order = 3.5,
                    type = "description",
                    name = " ",
                    width = 0.1
                    },
                    heightFrameSelect = {
                        type = "select",
                        name = "Previously used frames to sync",
                        order = 4,
                        width = 1,
                        values = function()
                            local list = {}
                            for _, fname in ipairs(g.frameSizeList or {}) do
                                list[fname] = fname
                            end
                            return list
                        end,
                        get = function() return g.heightInput end,
                        set = function(_, value) 
                            g.heightInput = value
                            if UCB.firstBuild then
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "height", value, {tries=g.syncFrameTries, interval=g.syncFrameInterval, delay=g.syncDelay})
                            else
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "height", value, {tries=g.syncFrameTries, interval=g.syncFrameInterval, delay=0})
                            end
                            CASTBAR_API:UpdateCastbar(unit)
                            end,
                    },
                    gap3 = {
                    order = 4.5,
                    type = "description",
                    name = " ",
                    width = 0.1
                    },
                    heightMinValue = {
                        type = "range",
                        name = "Height Min Value",
                        min = UIOptions.heightMin_bar, max = UIOptions.heightMax_bar, step = 1,
                        order = 5,
                        width = 1.2,
                        get = function() return g.heightMinValue end,
                        set = function(_, val)
                            g.heightMinValue = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    }
                }
            },
            groupManualControl = {
                type = "group",
                name = "Manual Size Control",
                inline = true,
                order = 3,
                hidden = function()
                    return not g.manualWidth and not g.manualHeight
                end,
                args = {
                    barWidth = {
                        type  = "range",
                        name  = "Manual Width",
                        min   = UIOptions.widthMin_bar, max = UIOptions.widthMax_bar, step = 1,
                        order = 2,
                        width = 1.2,
                        get   = function() return g.barWidth end,
                        set   = function(_, val)
                            g.barWidth = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                        hidden = function()
                            return not g.manualWidth
                        end,
                    },
                    barHeight = {
                        type  = "range",
                        name  = "Manual Height",
                        min   = UIOptions.heightMin_bar, max = UIOptions.heightMax_bar, step = 1,
                        order = 3,
                        width = 1.2,
                        get   = function() return g.barHeight end,
                        set   = function(_, val)
                            g.barHeight = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                        hidden = function()
                            return not g.manualHeight
                        end,
                    }
                },
            },
            groupOffsetControl = {
                type = "group",
                name = "Offset Size Control",
                inline = true,
                order = 3,
                hidden = function()
                    return g.manualWidth and g.manualHeight
                end,
                args = {
                    barWidth = {
                        type  = "range",
                        name  = "Offset Width",
                        min   = UIOptions.widthOffsetMin_bar, max = UIOptions.widthOffsetMax_bar, step = 1,
                        order = 2,
                        width = 1.2,
                        get   = function() return g.widthOffset end,
                        set   = function(_, val)
                            g.widthOffset = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                        hidden = function()
                            return g.manualWidth
                        end,
                    },
                    barHeight = {
                        type  = "range",
                        name  = "Offset Height",
                        min   = UIOptions.heightOffsetMin_bar, max = UIOptions.heightOffsetMax_bar, step = 1,
                        order = 3,
                        width = 1.2,
                        get   = function() return g.heightOffset end,
                        set   = function(_, val)
                            g.heightOffset = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                        hidden = function()
                            return g.manualHeight
                        end,
                    }
                },
            },
            buttonClearList = {
                type = "execute",
                name = "Clear Frame List",
                order = 4,
                width = 1,
                func = function()
                        g.frameSizeList = {}
                        g.widthInput = ""
                        g.heightInput = ""
                        CASTBAR_API:UpdateCastbar(unit)
                end,
                hidden = function() return #g.frameSizeList == 0 or (g.manualWidth and g.manualHeight) end,
            }
        }
    }
end




local function createOffsetX(unit, args)
    local g = GetCfg(unit).general

    if g.iconAnchor == "LEFT" then
        return {
            type  = "range",
            name = "X",
            min = 0, max = UIOptions.offsetMax_icon, step = 1,
            order = 2,
            width = 1.5,
            get = function() return g.iconOffsetX or 0 end,
            set = function(_, val)
                g.iconOffsetX = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        }
    elseif g.iconAnchor == "RIGHT" then
        return {
            type  = "range",
            name = "X",
            min = UIOptions.offsetMin_icon, max = 0, step = 1,
            order = 2,
            width = 1.5,
            get = function() return g.iconOffsetX or 0 end,
            set = function(_, val)
                g.iconOffsetX = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        }
    else
        return {
            type  = "range",
            name  = "X",
            min   = UIOptions.offsetMin_bar, max = UIOptions.offsetMax_bar, step = 1,
            order = 2,
            width = 1.5,
            get   = function() return g.offsetX or 0 end,
            set   = function(_, val)
                g.offsetX = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        }
    end
end

local function buildCreateOffsetX(unit, args)
    args.iconGrp.args.posSizeIcongrp.args.iconPosGrp.args.iconOffsetX = createOffsetX(unit, args)
end




local function createOffsetY(unit, args)
    local g = GetCfg(unit).general

    if g.iconAnchor == "TOP" then
        return {
            type  = "range",
            name = "Y",
            min = 0, max = UIOptions.offsetMax_icon, step = 1,
            order = 3,
            width = 1.5,
            get = function() return g.iconOffsetY or 0 end,
            set = function(_, val)
                g.iconOffsetY = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        }
    elseif g.iconAnchor == "BOTTOM" then
        return {
            type  = "range",
            name = "Y",
            min = UIOptions.offsetMin_icon, max = 0, step = 1,
            order = 3,
            width = 1.5,
            get = function() return g.iconOffsetY or 0 end,
            set = function(_, val)
                g.iconOffsetY = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        }
    else
        return {
            type  = "range",
            name  = "Y",
            min   = UIOptions.offsetMin_bar, max = UIOptions.offsetMax_bar, step = 1,
            order = 3,
            width = 1.5,
            get   = function() return g.offsetY or 0 end,
            set   = function(_, val)
                g.offsetY = val
                CASTBAR_API:UpdateCastbar(unit)
            end,
        }
    end
end

local function buildCreateOffsetY(unit, args)
    args.iconGrp.args.posSizeIcongrp.args.iconPosGrp.args.iconOffsetY = createOffsetY(unit, args)
end


local function BuildIconArgs(args, unit)
    local g = GetCfg(unit).general

    args.iconGrp = {
        type = "group",
        name = "Castbar Icon",
        inline = true,
        order = 3,
        args = {
            showCastIcon = {
                type  = "toggle",
                name  = "Show Cast Icon",
                order = 1,
                get   = function() return g.showCastIcon end,
                set   = function(_, val)
                    g.showCastIcon = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
            posSizeIcongrp = {
                type = "group",
                name = "",
                inline = true,
                order = 2,
                disabled = function() return g.showCastIcon == false end,
                args = {
                    iconPosGrp =  {
                        type = "group",
                        name = "Icon Position",
                        inline = true,
                        order = 1,
                        args = {
                            iconPosInfo = {
                                type = "description",
                                name = "Anchoring places the icon relative to the castbar. The side anchors (LEFT/RIGHT) treat the icon as part of the bar’s width, so the whole widget shifts as a single wide block. The vertical anchors (TOP/BOTTOM) treat the icon as stacked above/below and locked to the castbar height, so it affects the widget’s height instead of its width. The corner anchors (TOPLEFT/TOPRIGHT/BOTTOMLEFT/BOTTOMRIGHT) pin the widget by a corner but don’t let the icon change the synced/manual width or height, so the icon is positioned at that corner without resizing the main bar area.",
                                order = 0,
                                width = "full",
                            },
                            iconAnchor = {
                                type  = "select",
                                name  = "Icon Anchor Point",
                                order = 1,
                                width = 1,
                                values = UIOptions.anchors,
                                get   = function() return g.iconAnchor end,
                                set   = function(_, v)
                                    g.iconAnchor = v
                                    buildCreateOffsetX(unit, args)
                                    buildCreateOffsetY(unit, args)
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            iconOffsetX = createOffsetX(unit, args),
                            iconOffsetY = createOffsetY(unit, args),
                        }
                    },
                    iconSizeGrp = {
                        type = "group",
                        name = "Icon Size",
                        inline = true,
                        order = 2,
                        args = {
                            syncIconBar = {
                                type  = "toggle",
                                name  = "Sync Icon Size to Bar Height",
                                order = 1,
                                width = 1.2,
                                get   = function() return g.syncIconBar == true end,
                                set   = function(_, val)
                                    g.syncIconBar = val and true or false
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            iconWidth = {
                                type  = "range",
                                name  = "Icon Width",
                                min   = UIOptions.widthMin_icon, max = UIOptions.widthMax_icon, step = 1,
                                order = 2,
                                get   = function() return g.iconWidth end,
                                set   = function(_, val)
                                    g.iconWidth = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                                disabled = function()
                                    return g.showCastIcon == false or g.syncIconBar == true
                                end,
                            },
                            iconHeight = {
                                type  = "range",
                                name  = "Icon Height",
                                min   = UIOptions.heightMin_icon, max = UIOptions.heightMax_icon, step = 1,
                                order = 3,
                                width = 1.2,
                                get   = function() return g.iconHeight end,
                                set   = function(_, val)
                                    g.iconHeight = val
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                                disabled = function()
                                    return g.showCastIcon == false or g.syncIconBar == true
                                end,
                            }
                        }
                    },
                }
            }
        }
    }
end


-- Public builder
function Opt.BuildGeneralSettingsArgs(unit, opts)
    opts = opts or {}
    local args = {}

    BuildFramePickerArgs(args, unit)
    BuildPositionArgs(args, unit)
    BuildSizeArgs(args, unit)
    BuildIconArgs(args, unit)

    return args
end
