local ADDON_NAME, UCB = ...


UCB.Util = UCB.Util or {}
UCB.CFG_API  = UCB.CFG_API  or {}
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.tags     = UCB.tags     or {}
UCB.Preview_API = UCB.Preview_API or {}

local CFG_API = UCB.CFG_API
local CASTBAR_API = UCB.CASTBAR_API

local Util = UCB.Util
local Opt  = UCB.Options
local tags = UCB.tags
local BarUpdate_API = UCB.BarUpdate_API
local Preview_API = UCB.Preview_API


local function UpdateSequence(unit)

    BarUpdate_API:UpdateBarIcon(unit)
    BarUpdate_API:UpdateVisibility(unit)
    BarUpdate_API:UpdateColours(unit)
    BarUpdate_API:UpdateStyle(unit)
    BarUpdate_API:UpdateText(unit)
    --BarUpdate_API:UpdateUninterruptable(unit)
    BarUpdate_API:UpdateOtherFeatures(unit)
    BarUpdate_API:UpdateOthers(unit)

end


local function CreateCastBar(unit)
    -- Create castbar
    local anchor = UIParent

    -- Group frame = the thing you anchor (represents bar+icon combined)
    local group = CreateFrame("Frame", ADDON_NAME .. "_" .. unit .. "CastGroup", anchor)
    UCB.castBarGroup[unit] = group

    -- Bar frame lives inside group (keep your name)
    local bar = CreateFrame("Frame", ADDON_NAME .. "_" .. unit:sub(1,1):upper() .. unit:sub(2) .. "CastBar", group, "BackdropTemplate")
    UCB.castBar[unit] = bar
    bar.group = group  -- handy reference

    -- Status bar (fill bar)
    bar.status = CreateFrame("StatusBar", nil, bar, "BackdropTemplate")
    bar.status:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    bar.status:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)


    bar.overlayFrame = CreateFrame("Frame", nil, bar)
    bar.overlayFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    bar.overlayFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

    bar.underlayFrame = CreateFrame("Frame", nil, bar)
    bar.underlayFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    bar.underlayFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

    bar.textFrame = CreateFrame("Frame", nil, bar)
    bar.textFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    bar.textFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

    bar.mirrorFrame = CreateFrame("Frame", nil, bar)
    bar.mirrorFrame:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
    bar.mirrorFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    bar.mirrorFrame:SetWidth(0)
    bar.mirrorFrame:SetClipsChildren(true)
    bar.mirrorFrame:Hide()

    --bar.unInterruptedFrame = CreateFrame("Frame", nil, bar, "BackdropTemplate")
   -- bar.unInterruptedFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
   -- bar.unInterruptedFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

    bar.iconFrame = CreateFrame("Frame", nil, group, "BackdropTemplate")
    bar.icon = bar.iconFrame:CreateTexture(nil, "ARTWORK")
    bar.icon:SetAllPoints()
    bar.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

    UpdateSequence(unit)

    bar.group:Hide()
end


local function DeleteCastBar(unit)
    if UCB.castBar and UCB.castBar[unit] then
        UCB.castBar[unit].group:Hide()
        UCB.castBar[unit]:SetScript("OnUpdate", nil)
        UCB.castBar[unit] = nil
    end
end


function CASTBAR_API:AssignQueueWindow(typeCast)
    local unit  = "player"
    local bar = UCB.castBar[unit]
    if not bar.queueWindowOverlay then return end

    local bigCFG = CFG_API.GetValueConfig(unit)
    local cfg = bigCFG.otherFeatures
    local queueWindowOverlay = bar.queueWindowOverlay
    local overlayFrame = bar.overlayFrame
    local inverted = cfg.invertBar[typeCast]
    local mirror = cfg.mirrorBar[typeCast]

    local switch = (inverted or mirror) and not (inverted and mirror)  -- if either is true, but not both

    if cfg.showQueueWindow[typeCast] then
        local queWindow = BarUpdate_API.queueWindow / 1000
        local px = bigCFG.general.actualBarWidth * (queWindow / tags.var[unit].dTime)
        queueWindowOverlay:SetWidth(px)
        queueWindowOverlay:ClearAllPoints()
        if (not switch and typeCast ~= "channel") or (typeCast == "channel" and switch) then
            queueWindowOverlay:SetPoint("TOPRIGHT", overlayFrame, "TOPRIGHT", 0, 0)
            queueWindowOverlay:SetPoint("BOTTOMRIGHT", overlayFrame, "BOTTOMRIGHT", 0, 0)
        else
            queueWindowOverlay:SetPoint("TOPLEFT", overlayFrame, "TOPLEFT", 0, 0)
            queueWindowOverlay:SetPoint("BOTTOMLEFT", overlayFrame, "BOTTOMLEFT", 0, 0)
        end
        queueWindowOverlay:Show()
    else
        queueWindowOverlay:Hide()
    end
end


-- Castbar entry functionality
function CASTBAR_API:UpdateCastbar(unit)
    --print("Castbar update")
    if not UCB.castBar then return end
    local cfg = CFG_API.GetValueConfig(unit)
    -- Castbar should be disabled
    if cfg.enabled == false then
        if UCB.castBar[unit] ~= nil then
            DeleteCastBar(unit)
        end
    -- Castbar should be enabled
    else
        -- Castbar doesn't exist yet
        if UCB.castBar[unit] == nil then
            CreateCastBar(unit)
        -- Castbar exists, update layout
        else
            local bar = UCB.castBar[unit]
            if cfg.enabled == false then
                if bar then
                    bar:Hide()
                end
                return
            end
            UpdateSequence(unit)
        end
    end
end


function CASTBAR_API:SemiColourUpdate(unit, bar)
    local tex = bar.status:GetStatusBarTexture()
    local mtex = bar._mirrorTex
    local doMirror = bar._mirrored and mtex
    local colourMode = bar._colourMode
    local canGradient = tex and tex.SetGradient
    local status = bar.status

    if unit == "player" then 
        if colourMode == "single" then
            local r, g, b, a = bar._r, bar._g, bar._b, bar._a
            local col1 = bar._c1
            status:SetStatusBarColor(r, g, b, a)
            if doMirror then mtex:SetVertexColor(r, g, b, a) end
            if canGradient then
                tex:SetGradient("HORIZONTAL", col1, col1)
                if doMirror then mtex:SetGradient("HORIZONTAL", col1, col1) end
            end
        elseif colourMode == "gradient" then
            local r1, g1, b1, a1 = bar._r1, bar._g1, bar._b1, bar._a1
            local col1 = bar._c1
            local col2 = bar._c2
            status:SetStatusBarColor(r1, g1, b1, a1)
            if canGradient then
                tex:SetGradient("HORIZONTAL", col1, col2)
                if doMirror then mtex:SetGradient("HORIZONTAL", col2, col1) end
            end
        end
    else
        if colourMode == "single" then
            if bar._colourType == "custom" then
                local r, g, b, a = bar._r, bar._g, bar._b, bar._a
                local col1 = bar._c1
                status:SetStatusBarColor(r, g, b, a)
                if doMirror then mtex:SetVertexColor(r, g, b, a) end
                if canGradient then
                    tex:SetGradient("HORIZONTAL", col1, col1)
                    if doMirror then mtex:SetGradient("HORIZONTAL", col1, col1) end
                end
            else
                local r, g, b, a, col1, RGBA
                if UnitIsPlayer(unit) then
                    local _, classFile = UnitClass(unit)
                    local classColourVal = UCB.UIOptions.classColoursList[classFile]
                    RGBA = classColourVal.RGBA
                    col1 = classColourVal.COL
                else
                    local defaultEnemyColour = bar._enemyColour
                    RGBA = defaultEnemyColour.RGBA
                    col1 = defaultEnemyColour.COL
                end
                r, g, b, a = RGBA.r, RGBA.g, RGBA.b ,RGBA.a
                status:SetStatusBarColor(r, g, b, a)
                if doMirror then mtex:SetVertexColor(r, g, b, a) end
                if canGradient then
                    tex:SetGradient("HORIZONTAL", col1, col1)
                    if doMirror then mtex:SetGradient("HORIZONTAL", col1, col1) end
                end
            end
        elseif colourMode == "gradient" then
            local r1, g1, b1, a1 = bar._r1, bar._g1, bar._b1, bar._a1
            local col1 = bar._c1
            local col2 = bar._c2
            status:SetStatusBarColor(r1, g1, b1, a1)
            if doMirror then mtex:SetVertexColor(r1, g1, b1, a1) end
            if canGradient then
                tex:SetGradient("HORIZONTAL", col1, col2)
                if doMirror then mtex:SetGradient("HORIZONTAL", col2, col1) end
            end
        end
    end
end

-- Tries to stop previous casts
local function StopPrevCast(unit, bar, castGUID, spellID)
    if bar.activeCast then
        if bar._prevType == "normal" then
            CASTBAR_API:OnUnitSpellcastStop(unit, castGUID, spellID)
        elseif bar._prevType == "channel" then
            CASTBAR_API:OnUnitSpellcastChannelStop(unit, castGUID, spellID)
        elseif bar._prevType == "empowered" then
            CASTBAR_API:OnUnitSpellcastEmpowerStop(unit, castGUID, spellID)
        end
    end
end

function CASTBAR_API:MirrorBar(cfg, bar, castType)
    local mirror = cfg.mirrorBar[castType]
    bar._mirrored = mirror
    bar.mirrorFrame:SetShown(bar._mirrored)
    local status = bar.status and bar.status --bar.status:GetStatusBarTexture()
    if status then status:SetAlphaFromBoolean(not bar._mirrored) end
end

function CASTBAR_API:UninterruptibleCast(unit, unInt)
end


local function InitCastbarVal(status, castType, resumeCast, vars, cfg)
    local minVal = 0
    local maxVal = vars.dTime
    -- Resume sets value to current point
    if resumeCast then
        minVal = vars.durationObject:GetElapsedDuration()
        maxVal = vars.durationObject:GetRemainingDuration()
    end
    -- Channels are inverted, so flip min and max
    if castType == "channel" then
        minVal, maxVal = maxVal, minVal
    end

    -- Set initial value based on invert
    local inverted = cfg.invertBar[castType]
    if inverted then
        status:SetValue(maxVal)
    else
        status:SetValue(minVal)
    end
end


function CASTBAR_API:CastSetup(unit, castGUID, spellID, resumeCast, castType)
    if Preview_API.previewActive and Preview_API.previewActive[unit] then
        Preview_API:HidePreviewCastBar(unit)
    end

    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]
    StopPrevCast(unit, bar, castGUID, spellID)

    -- Update internal vars with spellInfo
    local icon_texture = tags:updateVars(unit, castType, spellID, cfg)
    local vars = tags.var[unit]

    -- Failsafe
    if not vars.durationObject then
        return
    end

    -- Set text, icon, queue window
    local textCFG = cfg.text
    tags:setTextSameState(textCFG, bar, "semiDynamic", unit, castType, false)
    tags:setTextSameState(textCFG, bar, "dynamic", unit, castType, true)
    
    bar.icon:SetTexture(icon_texture)

    if unit == "player" then
        CASTBAR_API:AssignQueueWindow(castType)
    end

    bar.status:SetMinMaxValues(0, vars.dTime)
    local otherCFG = cfg.otherFeatures
    CASTBAR_API:MirrorBar(otherCFG, bar, castType)
    InitCastbarVal(bar.status, castType, resumeCast, vars, otherCFG)

    return cfg, bar, vars
end

function CASTBAR_API:CastOnUpdateSetup(bar, unit, cfg, vars, castType, spellID, CastbarOnUpdate)
    bar._ucbUnit = unit
    bar._ucbCfg = cfg
    bar._ucbCastType = castType
    bar._ucbVars = vars
    bar._ucbSpellID = spellID
    bar:SetScript("OnUpdate", CastbarOnUpdate)
    bar.group:Show()
    bar._prevType = castType
    bar.castActive = true
end


function CASTBAR_API:CastUpdate(unit, castGUID, spellID, castType)
    local cfg = CFG_API.GetValueConfig(unit)
    local bar = UCB.castBar[unit]

    local icon_texture = tags:updateVars(unit, castType, spellID, cfg)
    local vars = tags.var[unit]

    -- Failsafe
    if not vars.durationObject then
        return
    end

    -- Set text, icon, queue window
    local textCFG = cfg.text
    tags:setTextSameState(textCFG, bar, "semiDynamic", unit, castType, false)
    tags:setTextSameState(textCFG, bar, "dynamic", unit, castType, true)

    bar.icon:SetTexture(icon_texture)

    if unit == "player" then
        CASTBAR_API:AssignQueueWindow(castType)
    end

    bar.status:SetMinMaxValues(0, vars.dTime)
    local otherCFG = cfg.otherFeatures
    CASTBAR_API:MirrorBar(otherCFG, bar, castType)
    
    -- Set value based on invert and cast type (channel or not)
    local minVal = 0
    local maxVal = vars.dTime
    if castType == "channel" then
        minVal, maxVal = maxVal, minVal
    end
    local inverted = otherCFG.invertBar[castType]
    if inverted then
        bar.status:SetValue(maxVal)
    else
        bar.status:SetValue(minVal)
    end
end

-- !!!!!!!!!!!!!!!!!!!!!!! DYNAMIC UPDATE FUNCTION !!!!!!!!!!!!!!!!!!!!!!!!
function CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, castType, vars)
    local durationObject = vars.durationObject
    if not durationObject then return end

    local status = bar.status
    local inverted = cfg.otherFeatures.invertBar[castType]

    local progress
    local remaining = durationObject:GetRemainingDuration()
    local elapsedTime = durationObject:GetElapsedDuration()
    -- progress for the bar fill
    local isChannel = (castType == "channel")
    if (not inverted and not isChannel) or (inverted and isChannel) then
        progress = elapsedTime
    else
        progress = remaining
    end
    status:SetValue(progress)

    -- Set dynamic texts
    UCB.tags:ApplyTextState(bar, "dynamic", unit, remaining, elapsedTime)

    -- Look for mirror bar updates
    BarUpdate_API:SyncMirror(bar)

    -- Set dynamic colours
    local colourMode = cfg.style.colourMode
    if castType == "empowered" or colourMode == "ombre" then
        local mirror = cfg.otherFeatures.mirrorBar[castType]
        local switch = (inverted or mirror) and not (inverted and mirror)  -- if either is true, but not both
        BarUpdate_API:AssignColours(unit, bar, cfg, colourMode, castType, durationObject, switch)
    end
    
    return remaining
end