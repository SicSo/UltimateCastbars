local ADDON_NAME, UCB = ...


UCB.Util = UCB.Util or {}
UCB.CFG_API  = UCB.CFG_API  or {}
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.tags     = UCB.tags     or {}

local CFG_API = UCB.CFG_API
local CASTBAR_API = UCB.CASTBAR_API

local Util = UCB.Util
local Opt  = UCB.Options
local tags = UCB.tags
local BarUpdate_API = UCB.BarUpdate_API


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

    bar.iconFrame = CreateFrame("Frame", nil, group, "BackdropTemplate")
    bar.icon = bar.iconFrame:CreateTexture(nil, "ARTWORK")
    bar.icon:SetAllPoints()
    bar.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

    BarUpdate_API:UpdateBarIcon(unit)
    BarUpdate_API:UpdateVisibility(unit)
    BarUpdate_API:UpdateColours(unit)
    BarUpdate_API:UpdateStyle(unit)
    BarUpdate_API:UpdateText(unit)
    BarUpdate_API:UpdateOtherFeatures(unit)
    BarUpdate_API:UpdateOthers(unit)

    bar.group:Hide()
end


local function DeleteCastBar(unit)
    if UCB.castBar and UCB.castBar[unit] then
        UCB.castBar[unit].group:Hide()
        UCB.castBar[unit]:SetScript("OnUpdate", nil)
        UCB.castBar[unit] = nil
    end
end


function CASTBAR_API:AssignQueueWindow(unit, typeCast)
    local bar = UCB.castBar[unit]
    if not bar.queueWindowOverlay then return end

    local bigCFG = CFG_API.GetValueConfig(unit)
    local cfg = bigCFG.otherFeatures
    local queueWindowOverlay = bar.queueWindowOverlay
    local status = bar.status

    if cfg.showQueueWindow[typeCast] then
        local queWindow = BarUpdate_API.queueWindow / 1000
        local px = bigCFG.general.actualBarWidth * (queWindow / tags.var[unit].dTime)
        queueWindowOverlay:SetWidth(px)
        queueWindowOverlay:ClearAllPoints()
        if (not cfg.invertBar[typeCast] and typeCast ~= "channel") or (typeCast == "channel" and cfg.invertBar[typeCast]) then
            queueWindowOverlay:SetPoint("TOPRIGHT", status, "TOPRIGHT", 0, 0)
            queueWindowOverlay:SetPoint("BOTTOMRIGHT", status, "BOTTOMRIGHT", 0, 0)
        else
            queueWindowOverlay:SetPoint("TOPLEFT", status, "TOPLEFT", 0, 0)
            queueWindowOverlay:SetPoint("BOTTOMLEFT", status, "BOTTOMLEFT", 0, 0)
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

            BarUpdate_API:UpdateBarIcon(unit)
            BarUpdate_API:UpdateVisibility(unit)
            BarUpdate_API:UpdateColours(unit)
            BarUpdate_API:UpdateStyle(unit)
            BarUpdate_API:UpdateText(unit)
            BarUpdate_API:UpdateOtherFeatures(unit)
            BarUpdate_API:UpdateOthers(unit)
        end
    end
end


function CASTBAR_API:SemiColourUpdate(bar)
    local tex = bar.status:GetStatusBarTexture()
    local colourMode = bar._colourMode
    local canGradient = tex and tex.SetGradient
    local status = bar.status

    if colourMode == "single" then
        local r, g, b, a = bar._r, bar._g, bar._b, bar._a
        local col1 = bar._c1
        status:SetStatusBarColor(r, g, b, a)
        if canGradient then
            tex:SetGradient("HORIZONTAL", col1, col1)
        end
    elseif colourMode == "gradient" then
        local r1, g1, b1, a1 = bar._r1, bar._g1, bar._b1, bar._a1
        local col1 = bar._c1
        local col2 = bar._c2
        status:SetStatusBarColor(r1, g1, b1, a1)
        if canGradient then
            tex:SetGradient("HORIZONTAL", col1, col2)
        end
    end
end



-- !!!!!!!!!!!!!!!!!!!!!!! DYNAMIC UPDATE FUNCTION !!!!!!!!!!!!!!!!!!!!!!!!
function CASTBAR_API:CastBar_OnUpdate(bar, elapsed, unit, cfg, castType)
    local now = GetTime()

    local var = UCB.tags.var[unit]
    local sTime, eTime, duration = var.sTime, var.eTime, var.dTime

    local status = bar.status
    local inverted = cfg.otherFeatures.invertBar[castType]


    local remaining = eTime - now
    local elapsedSinceStart = now - sTime

    -- progress for the bar fill
    local isChannel = (castType == "channel")
    local progress
    if (not inverted and not isChannel) or (inverted and isChannel) then
        progress = elapsedSinceStart
    else
        progress = remaining
    end
    status:SetValue(progress)

    -- Set dynamic texts
    UCB.tags:ApplyTextState(bar, "dynamic", unit, remaining)

    -- Set dynamic colours
    local colourMode = cfg.colourMode
    if castType == "empowered" or colourMode == "ombre" then
        -- colour progress (forward along curve unless inverted)
        local colourProgress = elapsedSinceStart
        if inverted then
            colourProgress = duration - elapsedSinceStart  -- == remaining if duration is accurate
        end
       BarUpdate_API:AssignColours(bar, colourMode, castType, colourProgress)
    end

    return remaining
end