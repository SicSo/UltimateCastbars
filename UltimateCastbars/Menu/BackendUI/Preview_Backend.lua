local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.Preview_API = UCB.Preview_API or {}
UCB.tags = UCB.tags or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local Preview_API = UCB.Preview_API
local tags = UCB.tags



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

local function EmpowerCast(unit, bar, cfg)
    if cfg.CLASSES.EVOKER.enableEmpowerEffects then
        CASTBAR_API:InitializeEmpoweredStages(unit)
    else
        CASTBAR_API:SemiColourUpdate(unit, bar)
    end
end

function Preview_API:ShowPreviewCastBar(unit, castType)
    local cfg = GetCfg(unit)
    local previewCFG = cfg.previewSettings
    local bar = UCB.castBar[unit]
    Preview_API.previewActive[unit] = true
    Preview_API.lastCastType[unit] = castType

    local duration = previewCFG.previewDuration
    if previewCFG.previewNormalDefaultDuration and castType == "normal" then
        local spellID = previewCFG.previewSpellID[castType]
        if spellID and spellID ~= 0 then
            duration = C_Spell.GetSpellInfo(spellID).castTime / 1000
        end
    end

    local icon_texture = tags:updateVarsPreview(unit, castType, previewCFG.previewSpellID[castType], duration, previewCFG.previewNotIntrerruptible, previewCFG.previewEmpowerStages)
    local vars = tags.var[unit]

    local textCFG = cfg.text
    tags:setTextSameState(textCFG, bar, "semiDynamic", unit, castType, false)
    tags:setTextSameState(textCFG, bar, "dynamic", unit, castType, true)

    bar.icon:SetTexture(icon_texture)

    if unit == "player" then
        CASTBAR_API:AssignQueueWindow(castType)
    end

    if castType == "normal" then
        NormalCast(unit, bar)
    elseif castType == "channel" then
        ChannelCast(unit, previewCFG.previewSpellID[castType], bar)
    elseif castType == "empowered" then
        EmpowerCast(unit, bar, cfg)
    end

    bar.status:SetMinMaxValues(0, math.max(tags.var[unit].dTime, 0.001))
    bar._ucbUnit = unit
    bar._ucbCfg = cfg
    bar._ucbCastType = castType
    bar._ucbVars = vars
    bar:SetScript("OnUpdate", CastbarOnUpdate)
    bar.group:Show()
end

function Preview_API:HidePreviewCastBar(unit)
    if Preview_API.previewActive and Preview_API.previewActive[unit] then
        Preview_API.previewActive[unit] = false
    end

    local bar = UCB.castBar[unit]
    bar.group:Hide()
    bar:SetScript("OnUpdate", nil)
    bar._ucbUnit, bar._ucbCfg, bar._ucbCastType, bar._ucbVars = nil, nil, nil, nil

    -- Player main, targets, focus,
    CASTBAR_API:HideChannelTicks(unit)
    CASTBAR_API:HideStages(unit)

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

