local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.Preview_API = UCB.Preview_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local Preview_API = UCB.Preview_API




local function PreviewSpells(cfg)
    if not Preview_API.showSettings then
        return nil
    end
    return {
        type   = "group",
        name   = "Preview Spell Settings",
        --inline = false,
        order  = 2,
        args   = {
            spellListNormal = {
                type    = "select",
                name    = function()
                    local spellID = cfg.previewSettings.previewSpellID.normal
                    return "Normal Spell for Preview("..Preview_API:IconTagForSpell(spellID, 16)..")"
                end,
                order   = 1,
                width   = 1.3,
                values  = function() 
                    local list = {}
                    for _, spellID in ipairs(UCB.allSpellTypes.normal or {}) do
                        local spellName = C_Spell.GetSpellInfo(spellID).name
                        if spellName then
                            list[spellID] = spellName
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


local function PreviewSettings(cfg)
    if not Preview_API.showSettings then
        return nil
    end
    return {
        type   = "group",
        name   = "Preview Settings",
        --inline = false,
        order  = 3,
        args   = {
            setCustomDuration = {
                type    = "toggle",
                name    = "Set Default Preview Duration for Normal Casts",
                order   = 1,
                width   = 1,
                get     = function() return cfg.previewSettings.previewNormalDefaultDuration end,
                set     = function(_, value) cfg.previewSettings.previewNormalDefaultDuration = value end,
            },
            setDuration = {
                type    = "range",
                name    = "Set Default Preview Duration(s)",
                order   = 2,
                width   = 1,
                min     = UCB.UIOptions.minPreviewDuration,
                max     = UCB.UIOptions.maxPreviewDuration,
                step    = 0.5,
                get     = function() return cfg.previewSettings.previewDuration end,
                set     = function(_, value) cfg.previewSettings.previewDuration = value end,
            },
            setNotInterruptible = {
                type    = "toggle",
                name    = "Set Preview Not Interruptible",
                order   = 3,
                width   = 1,
                get     = function() return cfg.previewSettings.previewNotIntrerruptible end,
                set     = function(_, value) cfg.previewSettings.previewNotIntrerruptible = value end,
            },
            setEmpowerStages = {
                type    = "range",
                name    = "Set Preview Empower Stages",
                order   = 4,
                width   = 1,
                min     = UCB.UIOptions.minPreviewEmpowerStages,
                max     = UCB.UIOptions.maxPreviewEmpowerStages,
                step    = 1,
                get     = function() return cfg.previewSettings.previewEmpowerStages end,
                set     = function(_, value) cfg.previewSettings.previewEmpowerStages = value end,
                hidden = function() return not UCB.allSpellTypes.empowered or #UCB.allSpellTypes.empowered == 0 end,
            },
        },
    }
end

local function BuildPreviewArgs(args, unit, opts)
    local cfg = GetCfg(unit)
    Preview_API.showSettings = false

    args.previewRow = {
        type   = "group",
        name   = "",
        --inline = false,
        order  = 1,
        args   = {
            previewbuttonCast = {
                type  = "execute",
                name  = "Preview Cast",
                order = 1,
                width = 1.3,
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

            previewbuttonChannel = {
                type  = "execute",
                name  = "Preview Channel",
                order = 2,
                width = 1.3,
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
                hidden = function() return not UCB.allSpellTypes.channel or #UCB.allSpellTypes.channel == 0 end,
            },

            previewbuttonEmpower = {
                type  = "execute",
                name  = "Preview Empower",
                order = 3,
                width = 1.3,
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
                hidden = function() return not UCB.allSpellTypes.empowered or #UCB.allSpellTypes.empowered == 0 end,
            },
            showSettings = {
                type  = "execute",
                name  = function() 
                    if Preview_API.showSettings then
                        return "Hide Preview Settings"
                    else
                        return "Show Preview Settings"
                    end
                end,
                order = 4,
                width = 1,
                func  = function()
                    Preview_API.showSettings = not Preview_API.showSettings
                    args.previewSpells = PreviewSpells(cfg)
                    args.previewSettings = PreviewSettings(cfg)
                end,
            }
        },
    }
    args.previewSpells = PreviewSpells(cfg)
    args.previewSettings = PreviewSettings(cfg)
end


-- Public builder
function Opt.BuildGeneralSettingsPreviewArgs(unit, opts)
    opts = opts or {}
    local args = {}

    BuildPreviewArgs(args, unit, opts)
    return args
end
