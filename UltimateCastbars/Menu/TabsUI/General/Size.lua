local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.GeneralSettings_API = UCB.GeneralSettings_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local UIOptions = UCB.UIOptions
local GeneralSettings_API = UCB.GeneralSettings_API

function GeneralSettings_API:BuildSizeArgs(cfg, unit)
    local g = cfg

    local sizeGrp = {
        type = "group",
        name = "Size",
        inline = false,
        order = 2,
        args = {
            toggleGroup = {
                type = "group",
                name = "Size Control Mode",
                inline = true,
                order = 1,
                args = {
                    manualWidthToogle = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
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
                        type = "toggle", dialogControl = "UCB_CheckBox",
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
                        type = "toggle", dialogControl = "UCB_CheckBox",
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
                        type = "toggle", dialogControl = "UCB_CheckBox",
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
                                type = "range", dialogControl = "UCB_Slider",
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
                                type = "range", dialogControl = "UCB_Slider",
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
                                type = "range", dialogControl = "UCB_Slider",
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
            widthSyncFrameGroup = {
                type = "group",
                name = "Width Frame",
                inline = true,
                order = 2,
                hidden = function()
                    return g.manualWidth
                end,
                args = {
                    widthFrameTitle = {
                        type = "header", dialogControl = "UCB_Heading",
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
                        type = "header", dialogControl = "UCB_Heading",
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
                        type = "input", dialogControl = "UCB_EditBox",
                        name = "Custom Width Frame",
                        order = 3,
                        width = 1.2,
                        get = function() return g.widthInput end,
                        set = function(_, value)
                            g.widthInput = value
                            if UCB.firstBuild then
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "width", value, {tries = g.syncFrameTries, interval = g.syncFrameInterval, delay = g.syncDelay})
                            else
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "width", value, {tries = g.syncFrameTries, interval = g.syncFrameInterval, delay = 0})
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
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "width", value, {tries = g.syncFrameTries, interval = g.syncFrameInterval, delay = g.syncDelay})
                            else
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "width", value, {tries = g.syncFrameTries, interval = g.syncFrameInterval, delay = 0})
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
                        type = "range", dialogControl = "UCB_Slider",
                        name = "Width Min Value",
                        min = UIOptions.widthMin_bar, max = UIOptions.widthMax_bar, step = 1,
                        order = 5,
                        width = 1.3,
                        get = function() return g.widthMinValue end,
                        set = function(_, val)
                            g.widthMinValue = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    gap4 = {
                        order = 5.5,
                        type = "description",
                        name = " ",
                        width = 0.1
                    },
                    widthSyncCombat = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name = "Width Sync In Combat",
                        order = 6,
                        width = 1.3,
                        get = function() return g.size.sizeSync.widthSync.syncInCombat end,
                        set = function(_, val)
                            g.size.sizeSync.widthSync.syncInCombat = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    }
                }
            },
            heightSyncFrameGroup = {
                type = "group",
                name = "Height Frame",
                inline = true,
                order = 3,
                hidden = function()
                    return g.manualHeight
                end,
                args = {
                    heigthFrameTitle = {
                        type = "header", dialogControl = "UCB_Heading",
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
                        type = "header", dialogControl = "UCB_Heading",
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
                        type = "input", dialogControl = "UCB_EditBox",
                        name = "Custom Height Frame",
                        order = 3,
                        width = 1.2,
                        get = function() return g.heightInput end,
                        set = function(_, value)
                            g.heightInput = value
                            if UCB.firstBuild then
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "height", value, {tries = g.syncFrameTries, interval = g.syncFrameInterval, delay = g.syncDelay})
                            else
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "height", value, {tries = g.syncFrameTries, interval = g.syncFrameInterval, delay = 0})
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
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "height", value, {tries = g.syncFrameTries, interval = g.syncFrameInterval, delay = g.syncDelay})
                            else
                                GeneralSettings_API:ResolveFrameWithRetry(unit, g, "height", value, {tries = g.syncFrameTries, interval = g.syncFrameInterval, delay = 0})
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
                        type = "range", dialogControl = "UCB_Slider",
                        name = "Height Min Value",
                        min = UIOptions.heightMin_bar, max = UIOptions.heightMax_bar, step = 1,
                        order = 5,
                        width = 1.2,
                        get = function() return g.heightMinValue end,
                        set = function(_, val)
                            g.heightMinValue = val
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                    },
                    gap4 = {
                        order = 5.5,
                        type = "description",
                        name = " ",
                        width = 0.1
                    },
                    heightSyncCombat = {
                        type = "toggle", dialogControl = "UCB_CheckBox",
                        name = "Height Sync In Combat",
                        order = 6,
                        width = 1.3,
                        get = function() return g.size.sizeSync.heightSync.syncInCombat end,
                        set = function(_, val)
                            g.size.sizeSync.heightSync.syncInCombat = val
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
                        type  = "range", dialogControl = "UCB_Slider",
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
                        type  = "range", dialogControl = "UCB_Slider",
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
                        type  = "range", dialogControl = "UCB_Slider",
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
                        type  = "range", dialogControl = "UCB_Slider",
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
                type = "execute", dialogControl = "UCB_Button",
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
    return sizeGrp
end