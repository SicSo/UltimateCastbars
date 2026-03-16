local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.GeneralSettings_API = UCB.GeneralSettings_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local GetCFG = UCB.GetValueConfig
local UIOptions = UCB.UIOptions
local GeneralSettings_API = UCB.GeneralSettings_API

local function createOffsetX(unit)
    local g = GetCFG(unit, "general")

    if g.iconAnchor == "LEFT" then
        return {
            type  = "range", dialogControl = "UCB_Slider",
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
            type  = "range", dialogControl = "UCB_Slider",
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
            type  = "range", dialogControl = "UCB_Slider",
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

local function createOffsetY(unit)
    local g = GetCFG(unit, "general")

    if g.iconAnchor == "TOP" then
        return {
            type  = "range", dialogControl = "UCB_Slider",
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
            type  = "range", dialogControl = "UCB_Slider",
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
            type  = "range", dialogControl = "UCB_Slider",
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

local function rebuildIconOffsets(args, unit)
    args.iconGrp.args.posSizeIcongrp.args.iconPosGrp.args.iconOffsetX = createOffsetX(unit)
    args.iconGrp.args.posSizeIcongrp.args.iconPosGrp.args.iconOffsetY = createOffsetY(unit)
end

function GeneralSettings_API:BuildIconArgs(args, cfg, unit)
    local g = cfg

    args.iconGrp = {
        type = "group",
        name = "Icon",
        inline = false,
        order = 3,
        args = {
            showCastIcon = {
                type = "toggle", dialogControl = "UCB_CheckBox",
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
                                    rebuildIconOffsets(args, unit)
                                    CASTBAR_API:UpdateCastbar(unit)
                                end,
                            },
                            iconOffsetX = createOffsetX(unit),
                            iconOffsetY = createOffsetY(unit),
                        }
                    },
                    iconSizeGrp = {
                        type = "group",
                        name = "Icon Size",
                        inline = true,
                        order = 2,
                        args = {
                            syncIconBar = {
                                type = "toggle", dialogControl = "UCB_CheckBox",
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
                                type  = "range", dialogControl = "UCB_Slider",
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
                                type  = "range", dialogControl = "UCB_Slider",
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