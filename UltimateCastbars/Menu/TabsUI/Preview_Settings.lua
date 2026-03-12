local _, UCB = ...

UCB.Options = UCB.Options or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.Preview_API = UCB.Preview_API or {}
UCB.UIOptions = UCB.UIOptions or {}

local Opt = UCB.Options
local GetCFG = UCB.GetValueConfig
local Preview_API = UCB.Preview_API
local UIOptions = UCB.UIOptions

local function PreviewSpells(cfg)
    return {
        type   = "group",
        name   = "Preview Spell Settings",
        --inline = false,
        hidden = function() return not Preview_API.showSettingsToggle end,
        order  = 2,
        args   = {
            spellListNormal = {
                type    = "select",
                name    = function()
                    local spellID = cfg.previewSettings.previewSpellID.normal
                    return "Normal Spell for Preview("..Preview_API:IconTagForSpell(spellID, 16)..")"
                end,
                dialogControl = "UCB_SearchDropdown",
                order   = 1,
                width   = 1.3,
                values  = function() 
                    local list = {}
                    for _, spellID in ipairs(UCB.allSpellTypes.normal or {}) do
                        local spellName = C_Spell.GetSpellInfo(spellID).name
                        if spellName then
                            list[spellID] = { text = spellName, icon = select(1, C_Spell.GetSpellTexture(spellID)) }
                        end
                    end
                    return list
                end,
                get     = function() return cfg.previewSettings.previewSpellID.normal end,
                set     = function(_, value) cfg.previewSettings.previewSpellID.normal = value end,
            },
            spellListChannel = {
                type    = "select",
                name    = function()
                    local spellID = cfg.previewSettings.previewSpellID.channel
                    return "Channel Spell for Preview("..Preview_API:IconTagForSpell(spellID, 16)..")"
                end,
                order   = 2,
                width   = 1.3,
                values  = function() 
                    local list = {}
                    for _, spellID in ipairs(UCB.allSpellTypes.channel or {}) do
                        local spellName = C_Spell.GetSpellInfo(spellID).name
                        if spellName then
                            list[spellID] = spellName
                        end
                    end
                    return list
                end,
                get     = function() return cfg.previewSettings.previewSpellID.channel end,
                set     = function(_, value) cfg.previewSettings.previewSpellID.channel = value end,
                hidden = function() return not UCB.allSpellTypes.channel or #UCB.allSpellTypes.channel == 0 end,
            },
            spellListEmpower = {
                type    = "select",
                name    = function()
                    local spellID = cfg.previewSettings.previewSpellID.empowered
                    return "Empower Spell for Preview("..Preview_API:IconTagForSpell(spellID, 16)..")"
                end,
                order   = 3,
                width   = 1.3,
                values  = function() 
                    local list = {}
                    for _, spellID in ipairs(UCB.allSpellTypes.empowered or {}) do
                        local spellName = C_Spell.GetSpellInfo(spellID).name
                        if spellName then
                            list[spellID] = spellName
                        end
                    end
                    return list
                end,
                get     = function() return cfg.previewSettings.previewSpellID.empowered end,
                set     = function(_, value) cfg.previewSettings.previewSpellID.empowered = value end,
                hidden = function() return not UCB.allSpellTypes.empowered or #UCB.allSpellTypes.empowered == 0 end,
            }
        },
    }
end


local function PreviewSettings(cfg, unit)
    return {
        type   = "group",
        name   = "Preview Settings",
        --inline = false,
        hidden = function() return not Preview_API.showSettingsToggle end,
        order  = 3,
        args   = {
            setCustomDuration = {
                type    = "toggle", dialogControl = "UCB_CheckBox",
                name    = "Set Default Preview Duration for Normal Casts",
                order   = 1,
                width   = 1.7,
                get     = function() return cfg.previewSettings.previewNormalDefaultDuration end,
                set     = function(_, value)
                    cfg.previewSettings.previewNormalDefaultDuration = value
                    Preview_API:RestartPreview(unit)
                    end,
            },
            setDuration = {
                type    = "range", dialogControl = "UCB_Slider",
                name    = "Set Default Preview Duration(s)",
                order   = 2,
                width   = 1,
                min     = UCB.UIOptions.minPreviewDuration,
                max     = UCB.UIOptions.maxPreviewDuration,
                step    = 0.5,
                get     = function() return cfg.previewSettings.previewDuration end,
                set     = function(_, value) 
                    cfg.previewSettings.previewDuration = value
                    Preview_API:RestartPreview(unit)
                    end,
            },
            setEmpowerStages = {
                type    = "range", dialogControl = "UCB_Slider",
                name    = "Set Preview Empower Stages",
                order   = 4,
                width   = 1,
                min     = UCB.UIOptions.minPreviewEmpowerStages,
                max     = UCB.UIOptions.maxPreviewEmpowerStages,
                step    = 1,
                get     = function() return cfg.previewSettings.previewEmpowerStages end,
                set     = function(_, value) 
                    cfg.previewSettings.previewEmpowerStages = value
                    Preview_API:RestartPreview(unit)
                    end,
                hidden = function() return not UCB.allSpellTypes.empowered or #UCB.allSpellTypes.empowered == 0 end,
            },
            setPreviewLatency = {
                type    = "range", dialogControl = "UCB_Slider",
                name    = "Set Preview Latency",
                hidden = function() return not UCB:IsPlayer(unit) or not cfg.otherFeatures.latency.enabled end,
                order   = 5,
                width   = 1,
                min     = 0,
                max     = 0.5,
                step    = 0.001,
                get     = function() return cfg.previewSettings.previewLatency or 0 end,
                set     = function(_, value) 
                    cfg.previewSettings.previewLatency = value
                    Preview_API:RestartPreview(unit)
                    end,
            },
            uninterGrp = {
                type = "group",
                name = "Uninterruptible/Kick Settings",
                inline = true,
                order = 6,
                args = {
                    setNotInterruptible = {
                        type    = "toggle", dialogControl = "UCB_CheckBox",
                        name    = "Set Preview Not Interruptible",
                        order   = 1,
                        width   = "full",
                        get     = function() return cfg.previewSettings.previewNotIntrerruptible end,
                        set     = function(_, value) 
                            cfg.previewSettings.previewNotIntrerruptible = value 
                            Preview_API:RestartPreview(unit)
                            end,
                    },
                    previewShowKickCD = {
                        type    = "toggle", dialogControl = "UCB_CheckBox",
                        name    = "Set Preview Kick CD",
                        order   = 2,
                        width   = 1,
                        get     = function() return cfg.previewSettings.previewShowKickCD end,
                        set     = function(_, value)
                            cfg.previewSettings.previewShowKickCD = value
                            Preview_API:RestartPreview(unit)
                            end,
                    },
                    setKickCD = {
                        type    = "range", dialogControl = "UCB_Slider",
                        name    = "Set Preview Kick CD",
                        order   = 3,
                        width   = 1,
                        min     = 0,
                        max     = 20,
                        step    = 0.1,
                        get     = function() return cfg.previewSettings.previewKickCD end,
                        set     = function(_, value) 
                            cfg.previewSettings.previewKickCD = value 
                            Preview_API:RestartPreview(unit)
                            end,
                        hidden = function() return not cfg.previewSettings.previewShowKickCD end,
                    },
                    startKickTimer = {
                        type    = "execute",
                        dialogControl = "UCB_Button",
                        name    = "Start Kick Timer",
                        order   = 4,
                        width   = 1,
                        func    = function()
                            if Preview_API.previewActive and Preview_API.previewActive[unit] then
                                Preview_API:StartKickTimer(cfg.previewSettings.previewKickCD)
                            end
                            Preview_API:RestartPreview(unit)
                        end,
                        hidden = function() return not cfg.previewSettings.previewShowKickCD end,
                    }
                }
            }
        },
    }
end

local function BuildPreviewArgs(args, unit, opts)
    local cfg = GetCFG(unit)
    Preview_API.showSettingsToggle = false

    args.previewRow = {
        type   = "group",
        name   = "",
        --inline = false,
        order  = 1,
        args   = {
            previewbuttonCast = {
                type = "execute",
                dialogControl = "UCB_Button",
                name  = "Preview Cast",
                order = 1,
                width = 1,
                func  = function()
                    if not Preview_API.previewActive then Preview_API.previewActive = {} end
                    if not Preview_API.lastCastType then Preview_API.lastCastType = {} end
                    if not Preview_API.lastCastType[unit] then Preview_API.lastCastType[unit] = "" end
                    local bar = UCB.castBar[unit]
                    if not bar then return end
                    local castType = "normal"

                    if not Preview_API.previewActive[unit] or Preview_API.lastCastType[unit] ~= castType then
                        if Preview_API.previewActive[unit] and Preview_API.lastCastType[unit] ~= castType then
                            Preview_API:HidePreviewCastBar(unit)
                        end
                        Preview_API:ShowPreviewCastBar(unit, castType)
                        bar.group:EnableMouse(true)
                        bar.group:SetMovable(true)
                        bar.group:RegisterForDrag("LeftButton")
                        bar.group:SetScript("OnDragStart", function(self) self:StartMoving() end)
                        bar.group:SetScript("OnDragStop", function(self)
                            self:StopMovingOrSizing()
                            local relFrame = cfg.general.anchorName and _G[cfg.general.anchorName] or _G[cfg.general._defaultAnchor]
                            local anchorFrom = cfg.general.anchorFrom
                            local anchorTo   = cfg.general.anchorTo
                            local x, y = Preview_API:GetOffsetsForAnchorPair(self, relFrame, anchorFrom, anchorTo)
                            cfg.general.offsetX, cfg.general.offsetY = x, y
                        end)
                    else
                        Preview_API:HidePreviewCastBar(unit)
                        bar.group:EnableMouse(false)
                        bar.group:SetMovable(false)
                        bar.group:RegisterForDrag()
                        bar.group:SetScript("OnDragStart", nil)
                        bar.group:SetScript("OnDragStop", nil)
                    end
                end,
            },
            gap = {
                type = "description",
                name = "",
                order = 1.5,
                width = 0.3
            },

            previewbuttonChannel = {
                type = "execute",
                dialogControl = "UCB_Button",
                name  = "Preview Channel",
                order = 2,
                width = 1,
                func  = function()
                    if not Preview_API.previewActive then Preview_API.previewActive = {} end
                    if not Preview_API.lastCastType then Preview_API.lastCastType = {} end
                    if not Preview_API.lastCastType[unit] then Preview_API.lastCastType[unit] = "" end
                    local bar = UCB.castBar[unit]
                    if not bar then return end
                    local castType = "channel"
                    if not Preview_API.previewActive[unit] or Preview_API.lastCastType[unit] ~= castType then
                        if Preview_API.previewActive[unit] and Preview_API.lastCastType[unit] ~= castType then
                            Preview_API:HidePreviewCastBar(unit)
                        end
                        Preview_API:ShowPreviewCastBar(unit, castType)
                        bar.group:EnableMouse(true)
                        bar.group:SetMovable(true)
                        bar.group:RegisterForDrag("LeftButton")
                        bar.group:SetScript("OnDragStart", function(self) self:StartMoving() end)
                        bar.group:SetScript("OnDragStop", function(self)
                            self:StopMovingOrSizing()
                            local relFrame = cfg.general.anchorName and _G[cfg.general.anchorName] or _G[cfg.general._defaultAnchor]
                            local anchorFrom = cfg.general.anchorFrom
                            local anchorTo   = cfg.general.anchorTo
                            local x, y = Preview_API:GetOffsetsForAnchorPair(self, relFrame, anchorFrom, anchorTo)
                            cfg.general.offsetX, cfg.general.offsetY = x, y
                        end)
                    else
                        Preview_API:HidePreviewCastBar(unit)
                        bar.group:EnableMouse(false)
                        bar.group:SetMovable(false)
                        bar.group:RegisterForDrag()
                        bar.group:SetScript("OnDragStart", nil)
                        bar.group:SetScript("OnDragStop", nil)
                    end
                end,
                hidden = function()
                    if UCB:IsPlayer(unit) then
                        return not UCB.allSpellTypes.channel or #UCB.allSpellTypes.channel == 0
                    end
                    return false
                    end,
            },
            gap2 = {
                type = "description",
                name = "",
                order = 2.5,
                width = 0.3
             },

            previewbuttonEmpower = {
                type = "execute",
                dialogControl = "UCB_Button",
                name  = "Preview Empower",
                order = 3,
                width = 1,
                func  = function()
                    if not Preview_API.previewActive then Preview_API.previewActive = {} end
                    if not Preview_API.lastCastType then Preview_API.lastCastType = {} end
                    if not Preview_API.lastCastType[unit] then Preview_API.lastCastType[unit] = "" end
                    local bar = UCB.castBar[unit]
                    if not bar then return end
                    local castType = "empowered"
                    if not Preview_API.previewActive[unit] or Preview_API.lastCastType[unit] ~= castType then
                        if Preview_API.previewActive[unit] and Preview_API.lastCastType[unit] ~= castType then
                            Preview_API:HidePreviewCastBar(unit)
                        end
                        Preview_API:ShowPreviewCastBar(unit, castType)
                        bar.group:EnableMouse(true)
                        bar.group:SetMovable(true)
                        bar.group:RegisterForDrag("LeftButton")
                        bar.group:SetScript("OnDragStart", function(self) self:StartMoving() end)
                        bar.group:SetScript("OnDragStop", function(self)
                            self:StopMovingOrSizing()
                            local relFrame = cfg.general.anchorName and _G[cfg.general.anchorName] or _G[cfg.general._defaultAnchor]
                            local anchorFrom = cfg.general.anchorFrom
                            local anchorTo   = cfg.general.anchorTo
                            local x, y = Preview_API:GetOffsetsForAnchorPair(self, relFrame, anchorFrom, anchorTo)
                            cfg.general.offsetX, cfg.general.offsetY = x, y
                        end)
                    else
                        Preview_API:HidePreviewCastBar(unit)
                        bar.group:EnableMouse(false)
                        bar.group:SetMovable(false)
                        bar.group:RegisterForDrag()
                        bar.group:SetScript("OnDragStart", nil)
                        bar.group:SetScript("OnDragStop", nil)
                    end
                end,
                hidden = function() 
                    if UCB:IsPlayer(unit) then
                        return not UCB.allSpellTypes.empowered or #UCB.allSpellTypes.empowered == 0
                    end
                    return false
                    end,
            },
            gap3 = {
                type = "description",
                name = "",
                order = 3.5,
                width = 0.3
            },
            showSettings = {
                type = "execute",
                dialogControl = "UCB_Button",
                name  = function() 
                    if Preview_API.showSettingsToggle then
                        return UCB.UIOptions.ColorText(UCB.UIOptions.red, "Hide").." Preview Settings"
                    else
                        return UCB.UIOptions.ColorText(UCB.UIOptions.green, "Show").." Preview Settings"
                    end
                end,
                order = 4,
                width = 1,
                func  = function()
                    Preview_API.showSettingsToggle = not Preview_API.showSettingsToggle
                    args.previewSpells = PreviewSpells(cfg)
                    args.previewSettings = PreviewSettings(cfg, unit)
                end,
            }
        },
    }
    args.previewSpells = PreviewSpells(cfg)
    args.previewSettings = PreviewSettings(cfg, unit)
end


-- Public builder
function Opt.BuildGeneralSettingsPreviewArgs(unit, opts)
    opts = opts or {}
    local args = {}

    BuildPreviewArgs(args, unit, opts)
    return args
end
