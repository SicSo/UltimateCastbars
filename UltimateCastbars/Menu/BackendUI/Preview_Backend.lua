local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.Preview_API = UCB.Preview_API or {}
UCB.tags = UCB.tags or {}

local CASTBAR_API = UCB.CASTBAR_API
local GetCFG = UCB.GetValueConfig
local Preview_API = UCB.Preview_API
local tags = UCB.tags

Preview_API.previewActive = {}
Preview_API.lastCastType = {}
Preview_API.kickDurationObject = nil
Preview_API.previewShowKickCD = {}

function Preview_API:StartKickTimer(seconds)
    local d = C_DurationUtil.CreateDuration()
    d:SetTimeFromStart(GetTime(), seconds)
    Preview_API.kickDurationObject = d
end


local function CastbarOnUpdate(bar, elapsed)
    local unit = bar._ucbUnit
    local cfg  = bar._ucbCfg
    local castType = bar._ucbCastType
    local vars = bar._ucbVars
    local remainig = UCB.CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, castType, vars)
    if remainig <= 0 then
        Preview_API:ShowPreviewCastBar(unit, castType)
    end
end


local function NormalCast(unit, bar)
    CASTBAR_API:SemiColourUpdate(unit, bar)
end


local function ChannelCast(unit, spellID, bar)
    CASTBAR_API:AssignChannelTicks(unit, spellID, "START")
    CASTBAR_API:SemiColourUpdate(unit, bar)
end

local function EmpowerCast(unit, bar, cfg, vars)
    if cfg.CLASSES.EVOKER.enableEmpowerEffects then
        CASTBAR_API:InitializeEmpoweredStages(bar, cfg, vars)
    else
        CASTBAR_API:SemiColourUpdate(unit, bar)
    end
end

function Preview_API:RestartPreview(unit)
    -- Stop preview
    local hidden = false
    if Preview_API.previewActive and Preview_API.previewActive[unit] then
        Preview_API:HidePreviewCastBar(unit)
        hidden = true
    end
    -- Restart preview if active before
    if hidden then
        Preview_API:ShowPreviewCastBar(unit, Preview_API.lastCastType[unit])
    end
end

function Preview_API:ShowPreviewCastBar(unit, castType)
    local mainCFG = UCB.GetValueConfig()
    local cfg = mainCFG[unit]
    local previewCFG = cfg.previewSettings
    local spellID = previewCFG.previewSpellID[castType]

    -- Print spellID 
    CASTBAR_API:PrintSpellID(mainCFG, spellID)

    local bar = UCB.castBar[unit]
    Preview_API.previewActive[unit] = true
    Preview_API.lastCastType[unit] = castType
    Preview_API.previewShowKickCD[unit] = previewCFG.previewShowKickCD

    CASTBAR_API:StopPrevCast(unit, bar, nil, nil, nil)

    -- Stop view of cancelled/interrupted casts
    CASTBAR_API:StopFrameTimer(UCB.castBar[unit], "cancelled")
    CASTBAR_API:StopFrameTimer(UCB.castBar[unit], "interrupted")

    local latency = previewCFG.previewLatency

    bar.current_spellID = spellID

    local duration = previewCFG.previewDuration
    if previewCFG.previewNormalDefaultDuration and castType == "normal" then
        local spellID = previewCFG.previewSpellID[castType]
        if spellID and spellID ~= 0 then
            duration = C_Spell.GetSpellInfo(spellID).castTime / 1000
        end
    end

    local icon_texture = tags:updateVarsPreview(unit, cfg, castType, spellID, duration, previewCFG.previewNotIntrerruptible, previewCFG.previewEmpowerStages, latency)
    local vars = tags.var[unit]
    if UCB:IsPlayer(unit) then
        -- Spell filter unint (make the spell int to avoid any unint effects)
        if not CASTBAR_API:SpellFilter(spellID, cfg.uninterruptible) then
            vars.nIntr = false
        end
    end

    tags:setTextSameState(bar, "semiDynamic", unit, castType, false)
    tags:setTextSameState(bar, "dynamic", unit, castType, true)

    bar.icon:SetTexture(icon_texture)

    if UCB:IsPlayer(unit) then
        CASTBAR_API:AssignQueueWindow(unit, cfg, castType)
        CASTBAR_API:AssignLatencyWindow(bar, cfg, castType, latency, vars)
    end

    local bar_status = bar.status
    bar_status:SetMinMaxValues(0, vars.dTime)
    local otherCFG = cfg.otherFeatures
    CASTBAR_API:MirrorBar(cfg, bar, castType)
    CASTBAR_API:InitCastbarVal(bar_status, castType, false, vars, otherCFG)

    -- Set style based on cast type
    CASTBAR_API:ApplyStyle(bar, unit, cfg, spellID, castType, bar_status)

    CASTBAR_API:UninterruptibleCast(bar, bar_status, vars)

    CASTBAR_API:InterruptibleTick(bar, unit, bar_status, vars, cfg, castType)

    if castType == "normal" then
        NormalCast(unit, bar)
    elseif castType == "channel" then
        ChannelCast(unit, spellID, bar)
    elseif castType == "empowered" then
        EmpowerCast(unit, bar, cfg, vars)
    end

    bar.gate_effects:SetAlpha(1)
    bar.group:SetAlpha(1)
    bar:SetAlpha(1)
    bar._ucbUnit = unit
    bar._ucbCfg = cfg
    bar._ucbCastType = castType
    bar._ucbVars = vars
    bar._ucbSpellID = spellID
    bar:SetScript("OnUpdate", CastbarOnUpdate)
    bar.group:Show()
    bar.flags.prevType = castType
    bar.flags.castActive = true

    CASTBAR_API:HideCastbar(bar, unit, vars, cfg)
end

function Preview_API:HidePreviewCastBar(unit)
    if Preview_API.previewActive and Preview_API.previewActive[unit] then
        Preview_API.previewActive[unit] = false
    end

    local cfg = GetCFG(unit)

    local bar = UCB.castBar[unit]
    bar.group:Hide()
    bar:SetScript("OnUpdate", nil)
    local otherFeaturesCFG = cfg.otherFeatures
    if otherFeaturesCFG.enable and otherFeaturesCFG.hideWhenCasting then
        bar.background_frame:Show()
    end
    bar.flags.castActive = false
    bar.flags.prevType = nil
    bar.current_spellID = nil
    bar._ucbUnit, bar._ucbCfg, bar._ucbCastType, bar._ucbVars, bar._ucbSpellID = nil, nil, nil, nil, nil

    -- Player main, targets, focus,
    CASTBAR_API:HideChannelTicks(bar, cfg.otherFeatures)
    CASTBAR_API:HideStages(bar)

end


function Preview_API:IconTagForSpell(spellID, size)
    size = size or 16
    if not spellID then return "" end
    local iconID = select(1, C_Spell.GetSpellTexture(spellID))
    if not iconID then return "" end
    -- icon crop optional: :0:0:64:64:5:59:5:59 gives nicer padding, but plain works too
    return ("|T%d:%d:%d:0:0:64:64:5:59:5:59|t "):format(iconID, size, size)
end

local function PointXY(frame, point)
    local L, R, T, B = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
    if not (L and R and T and B) then return nil, nil end

    local cx, cy = (L + R) / 2, (T + B) / 2

    if point == "TOPLEFT" then return L, T
    elseif point == "TOP" then return cx, T
    elseif point == "TOPRIGHT" then return R, T
    elseif point == "LEFT" then return L, cy
    elseif point == "CENTER" then return cx, cy
    elseif point == "RIGHT" then return R, cy
    elseif point == "BOTTOMLEFT" then return L, B
    elseif point == "BOTTOM" then return cx, B
    elseif point == "BOTTOMRIGHT" then return R, B
    end

    return cx, cy
end

-- Returns offsets (x, y) such that:
-- frame:SetPoint(anchorFrom, relativeFrame, anchorTo, x, y)
function Preview_API:GetOffsetsForAnchorPair(frame, relativeFrame, anchorFrom, anchorTo)
    relativeFrame = relativeFrame or UIParent
    anchorFrom = anchorFrom or "CENTER"
    anchorTo = anchorTo or "CENTER"

    local fx, fy = PointXY(frame, anchorFrom)
    local rx, ry = PointXY(relativeFrame, anchorTo)
    if not (fx and rx) then return 0, 0 end

    return fx - rx, fy - ry
end

