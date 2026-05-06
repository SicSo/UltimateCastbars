local _, UCB = ...

UCB.DefBlizzCast = UCB.DefBlizzCast or {}

local GetCFG = UCB.GetValueConfig
local DefBlizzCast = UCB.DefBlizzCast

local ENABLE_PET_CASTING_BAR_HIDE = true

-- Keep addon-owned bookkeeping off Blizzard-owned frames.
-- Writing custom fields onto Blizzard castbar frames can taint protected values
-- like startTime/maxValue and break Blizzard arithmetic later.
local FrameState = setmetatable({}, { __mode = "k" })

local function GetFrameState(frame)
    if not frame then return nil end

    local state = FrameState[frame]
    if not state then
        state = {}
        FrameState[frame] = state
    end

    return state
end

local function RegisterEventSafe(frame, eventName)
    if not frame or not eventName then return false end
    local ok = pcall(frame.RegisterEvent, frame, eventName)
    return ok
end

local function GetActivePlayerCastUnit()
    if UnitExists and UnitExists("vehicle") and UnitHasVehicleUI and UnitHasVehicleUI("player") then
        return "vehicle"
    end
    return "player"
end

local function IsUnitCastingOrChanneling(unit)
    if UCB:IsPlayer(unit, true) then
        unit = GetActivePlayerCastUnit()
    end

    if UnitCastingInfo and UnitCastingInfo(unit) then return true end
    if UnitChannelInfo and UnitChannelInfo(unit) then return true end
    return false
end

local function ShouldHidePetCastingBar(unit)
    if not ENABLE_PET_CASTING_BAR_HIDE then
        return false
    end

    if not UCB:IsPlayer(unit, true) then
        return false
    end

    local cfg = GetCFG(unit)
    if not (cfg and cfg.defaultBar) then
        return false
    end

    if cfg.defaultBar.enabled ~= false then
        return false
    end

    if UnitExists and UnitExists("vehicle") and UnitHasVehicleUI and UnitHasVehicleUI("player") then
        return true
    end

    return false
end

-- ============================================================
-- Helpers: Blizzard frames
-- ============================================================

local function EnsureVehicleHideEventFrame()
    if UCB.__ucbVehicleHideEvents then return end

    local ef = CreateFrame("Frame")
    UCB.__ucbVehicleHideEvents = ef

    RegisterEventSafe(ef, "UNIT_ENTERED_VEHICLE")
    RegisterEventSafe(ef, "UNIT_EXITED_VEHICLE")
    RegisterEventSafe(ef, "PLAYER_GAINS_VEHICLE_DATA")
    RegisterEventSafe(ef, "PLAYER_LOSES_VEHICLE_DATA")
    RegisterEventSafe(ef, "UPDATE_VEHICLE_ACTIONBAR")
    RegisterEventSafe(ef, "UNIT_ENTERING_VEHICLE")
    RegisterEventSafe(ef, "UNIT_EXITING_VEHICLE")

    ef:SetScript("OnEvent", function(_, _, unitTarget)
        if unitTarget and unitTarget ~= "player" then return end

        DefBlizzCast:ApplyDefaultBlizzCastbar("player", false)

        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                DefBlizzCast:ApplyDefaultBlizzCastbar("player", false)
            end)
            C_Timer.After(0.1, function()
                DefBlizzCast:ApplyDefaultBlizzCastbar("player", false)
            end)
        end
    end)
end

local function GetExtraHideFrames(unit)
    local out = {}

    if UCB:IsPlayer(unit, true) then
        if _G.OverlayPlayerCastingBarFrame then
            out[#out + 1] = _G.OverlayPlayerCastingBarFrame
        end

        if ShouldHidePetCastingBar(unit) and _G.PetCastingBarFrame then
            out[#out + 1] = _G.PetCastingBarFrame
        end
    end

    return out
end

local function GetBlizzFrames(unit)
    if UCB:IsPlayer(unit, true) then
        return { _G.PlayerCastingBarFrame, _G.CastingBarFrame }
    elseif UCB:IsTarget(unit, true) then
        local out = {}

        if _G.TargetFrame and _G.TargetFrame.spellbar then
            out[#out + 1] = _G.TargetFrame.spellbar
        end

        if _G.TargetFrameSpellBar then
            local same = (_G.TargetFrame and _G.TargetFrame.spellbar == _G.TargetFrameSpellBar)
            if not same then
                out[#out + 1] = _G.TargetFrameSpellBar
            end
        end

        return out
    elseif UCB:IsFocus(unit, true) then
        local out = {}

        if _G.FocusFrame and _G.FocusFrame.spellbar then
            out[#out + 1] = _G.FocusFrame.spellbar
        end

        if _G.FocusFrameSpellBar then
            local same = (_G.FocusFrame and _G.FocusFrame.spellbar == _G.FocusFrameSpellBar)
            if not same then
                out[#out + 1] = _G.FocusFrameSpellBar
            end
        end

        if _G.FocusCastingBarFrame then
            out[#out + 1] = _G.FocusCastingBarFrame
        end

        return out
    end

    return {}
end

-- ============================================================
-- State capture / restore
-- ============================================================

local function CaptureState(f)
    if not f then return nil end

    local s = {
        parent = (f.GetParent and f:GetParent()) or UIParent,
        scale  = (f.GetScale and f:GetScale()) or 1,
        alpha  = (f.GetAlpha and f:GetAlpha()) or 1,
        strata = (f.GetFrameStrata and f:GetFrameStrata()) or nil,
        level  = (f.GetFrameLevel and f:GetFrameLevel()) or nil,
        points = {},
    }

    if f.GetNumPoints and f.GetPoint then
        local n = f:GetNumPoints()
        for i = 1, n do
            local p, rt, rp, x, y = f:GetPoint(i)
            s.points[i] = { p, rt, rp, x, y }
        end
    end

    return s
end

local function ApplyCapturedState(f, s)
    if not f or not s then return end

    if f.SetParent and s.parent then
        pcall(function()
            f:SetParent(s.parent)
        end)
    end

    if f.ClearAllPoints and f.SetPoint and s.points then
        pcall(function()
            f:ClearAllPoints()
            for _, pt in ipairs(s.points) do
                local p, rt, rp, x, y = pt[1], pt[2], pt[3], pt[4], pt[5]
                if rt == nil then
                    rt = s.parent or UIParent
                end
                f:SetPoint(p, rt, rp, x, y)
            end
        end)
    end

    if f.SetFrameStrata and s.strata then
        pcall(function()
            f:SetFrameStrata(s.strata)
        end)
    end

    if f.SetFrameLevel and s.level then
        pcall(function()
            f:SetFrameLevel(s.level)
        end)
    end

    if f.SetScale and s.scale then
        pcall(function()
            f:SetScale(s.scale)
        end)
    end

    if f.SetAlpha and s.alpha then
        pcall(function()
            f:SetAlpha(s.alpha)
        end)
    end
end

local function CacheFrameState(f)
    if not f then return end

    local state = GetFrameState(f)
    if state.pcbCached then return end

    state.pcbCached = true
    state.pcbOrig = CaptureState(f)
end

local function RestoreFrameState(f, unit)
    if not f then return end

    local state = GetFrameState(f)
    local baseline = state.ucbBlizzBaseline and state.ucbBlizzBaseline[unit]
    ApplyCapturedState(f, baseline or state.pcbOrig)
end

local function SnapshotBlizzBaseline(unit)
    for _, f in ipairs(GetBlizzFrames(unit)) do
        if f then
            local state = GetFrameState(f)
            state.ucbBlizzBaseline = state.ucbBlizzBaseline or {}
            state.ucbBlizzBaseline[unit] = CaptureState(f)
        end
    end
end

-- ============================================================
-- "Late restore" helper
-- ============================================================

local function RestoreBlizzBaselineWithDelay(unit)
    for _, f in ipairs(GetBlizzFrames(unit)) do
        if f then
            CacheFrameState(f)
            RestoreFrameState(f, unit)
        end
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            for _, f in ipairs(GetBlizzFrames(unit)) do
                if f then
                    RestoreFrameState(f, unit)
                end
            end
        end)
    end
end

-- ============================================================
-- Scale
-- ============================================================

local function ApplyScaleState(f, scale)
    if not f then return end
    CacheFrameState(f)

    if f.SetScale then
        pcall(function()
            f:SetScale(scale)
        end)
    end
end

function DefBlizzCast:RefreshBlizzardCastbarScale(unit)
    local cfg = GetCFG(unit)
    if not cfg or not cfg.defaultBar then return end

    local scale = cfg.defaultBar.blizzBarScale or 1

    for _, f in ipairs(GetBlizzFrames(unit)) do
        if f then
            ApplyScaleState(f, scale)
        end
    end
end

-- ============================================================
-- Hide
-- ============================================================

local function ApplyHideState(f, shouldHide, dontForceShow, unit)
    if not f then return end
    CacheFrameState(f)

    local state = GetFrameState(f)
    local o = state and state.pcbOrig

    if shouldHide then
        if f.SetAlpha then
            pcall(function()
                f:SetAlpha(0)
            end)
        end

        if f.Hide then
            pcall(function()
                f:Hide()
            end)
        end

        return
    end

    if f.SetAlpha then
        pcall(function()
            f:SetAlpha((o and o.alpha) or 1)
        end)
    end

    if dontForceShow then
        return
    end

    if f == _G.OverlayPlayerCastingBarFrame
    or (ShouldHidePetCastingBar(unit) and f == _G.PetCastingBarFrame) then
        return
    end

    if f.Show then
        pcall(function()
            f:Show()
        end)
    end
end

local function ReapplyHideForFrame(frame)
    local state = GetFrameState(frame)
    local owner = state and state.ownerUnit
    if not owner then return end

    local c = GetCFG(owner)
    if not (c and c.defaultBar) then return end

    local hideNow = (c.defaultBar.enabled == false)
    if state.isExtraHideFrame and UCB:IsPlayer(owner, true) then
        hideNow = hideNow or (c.defaultBar.useBlizzardDefaults == false)
    end

    ApplyHideState(frame, hideNow, nil, owner)
end

local function EnsureHideHooks(f)
    if not f then return end

    local state = GetFrameState(f)
    if state.hideHooked then return end
    state.hideHooked = true

    if f.HookScript then
        f:HookScript("OnShow", function(self)
            ReapplyHideForFrame(self)
        end)
    end

    if hooksecurefunc and f.SetShown then
        hooksecurefunc(f, "SetShown", function(self, shown)
            if not shown then return end
            ReapplyHideForFrame(self)
        end)
    end
end

function DefBlizzCast:RefreshBlizzardCastbarHide(unit, showBar)
    local cfg = GetCFG(unit)
    if not cfg then return end
    cfg.defaultBar = cfg.defaultBar or {}

    local shouldHide = (cfg.defaultBar.enabled == false)

    local shouldHideExtras = shouldHide
    if UCB:IsPlayer(unit, true) then
        shouldHideExtras = shouldHide or (cfg.defaultBar.useBlizzardDefaults == false)
    end

    local dontForceShow = false
    if showBar == false and shouldHide == false then
        dontForceShow = not IsUnitCastingOrChanneling(unit)
    end

    local frames = GetBlizzFrames(unit)
    local extras = GetExtraHideFrames(unit)

    for _, f in ipairs(frames) do
        if f then
            local state = GetFrameState(f)
            state.ownerUnit = unit
            state.isExtraHideFrame = false

            EnsureHideHooks(f)
            ApplyHideState(f, shouldHide, dontForceShow, unit)
        end
    end

    for _, f in ipairs(extras) do
        if f then
            local state = GetFrameState(f)
            state.ownerUnit = unit
            state.isExtraHideFrame = true

            EnsureHideHooks(f)
            ApplyHideState(f, shouldHideExtras, dontForceShow, unit)
        end
    end
end

-- ============================================================
-- Position
-- ============================================================

local function ApplyFrameXY(frame, cfg)
    if not frame or not cfg then return end
    CacheFrameState(frame)

    local point = cfg.anchorPoint or "CENTER"
    local x = tonumber(cfg.offsetX) or 0
    local y = tonumber(cfg.offsetY) or 0

    pcall(function()
        frame:ClearAllPoints()
        frame:SetPoint(point, UIParent, point, x, y)
    end)
end

function DefBlizzCast:UpdateDefaultCastbarPosition(x, y, point, unit)
    local cfg = GetCFG(unit)
    if not cfg then return end
    cfg.defaultBar = cfg.defaultBar or {}

    cfg.defaultBar.anchorPoint = point or cfg.defaultBar.anchorPoint or "CENTER"
    cfg.defaultBar.offsetX = tonumber(x) or 0
    cfg.defaultBar.offsetY = tonumber(y) or 0

    for _, f in ipairs(GetBlizzFrames(unit)) do
        if f then
            ApplyFrameXY(f, cfg.defaultBar)
        end
    end

    UCB:NotifyChange()
end

-- ============================================================
-- Defaults
-- ============================================================

function DefBlizzCast:EnsureDefaultBarKeys(unit)
    local cfg = GetCFG(unit)
    if not cfg then return end

    cfg.defaultBar = cfg.defaultBar or {}
    local db = cfg.defaultBar

    if db.enabled == nil then db.enabled = true end
    if db.useBlizzardDefaults == nil then db.useBlizzardDefaults = true end
    if db.blizzBarScale == nil then db.blizzBarScale = 1 end
    if db.anchorPoint == nil then db.anchorPoint = "CENTER" end
    if db.offsetX == nil then db.offsetX = 0 end
    if db.offsetY == nil then db.offsetY = 0 end
end

-- ============================================================
-- Baseline updater (events)
-- ============================================================

local function EnsureBaselineEventFrame()
    if UCB.__ucbBlizzBaselineEvents then return end

    local ef = CreateFrame("Frame")
    UCB.__ucbBlizzBaselineEvents = ef

    ef:RegisterEvent("PLAYER_ENTERING_WORLD")
    ef:RegisterEvent("PLAYER_LOGIN")
    ef:RegisterEvent("UI_SCALE_CHANGED")
    ef:RegisterEvent("DISPLAY_SIZE_CHANGED")

    RegisterEventSafe(ef, "EDIT_MODE_LAYOUTS_UPDATED")
    RegisterEventSafe(ef, "EDIT_MODE_LAYOUT_UPDATED")
    RegisterEventSafe(ef, "EDIT_MODE_LAYOUTS_RESET")

    ef:SetScript("OnEvent", function()
        for _, unit in ipairs({ "player", "target", "focus" }) do
            local u = unit
            local cfg = GetCFG(u)
            if cfg and cfg.defaultBar and cfg.defaultBar.useBlizzardDefaults and cfg.defaultBar.enabled ~= false then
                SnapshotBlizzBaseline(u)
                if C_Timer and C_Timer.After then
                    C_Timer.After(0, function()
                        local c = GetCFG(u)
                        if c and c.defaultBar and c.defaultBar.useBlizzardDefaults and c.defaultBar.enabled ~= false then
                            SnapshotBlizzBaseline(u)
                        end
                    end)
                end
            end
        end
    end)
end

-- ============================================================
-- Layout mode toggle
-- ============================================================

function DefBlizzCast:RefreshBlizzardCastbarLayoutMode(unit, showBar)
    EnsureBaselineEventFrame()

    local cfg = GetCFG(unit)
    if not cfg then return end
    DefBlizzCast:EnsureDefaultBarKeys(unit)

    local db = cfg.defaultBar

    if db.useBlizzardDefaults then
        for _, f in ipairs(GetBlizzFrames(unit)) do
            if f then
                CacheFrameState(f)
            end
        end

        RestoreBlizzBaselineWithDelay(unit)

        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                local c = GetCFG(unit)
                if c and c.defaultBar and c.defaultBar.useBlizzardDefaults and c.defaultBar.enabled ~= false then
                    SnapshotBlizzBaseline(unit)
                end
            end)
        else
            SnapshotBlizzBaseline(unit)
        end
    else
        SnapshotBlizzBaseline(unit)

        for _, f in ipairs(GetBlizzFrames(unit)) do
            if f then
                CacheFrameState(f)
                ApplyScaleState(f, db.blizzBarScale or 1)
                ApplyFrameXY(f, db)
            end
        end
    end

    if db.enabled == false then
        DefBlizzCast:RefreshBlizzardCastbarHide(unit, showBar)
    end
end

local function ApplyCustomNowAndNextFrame(unit)
    local cfg = GetCFG(unit)
    if not cfg or not cfg.defaultBar then return end
    local db = cfg.defaultBar

    for _, f in ipairs(GetBlizzFrames(unit)) do
        if f then
            ApplyScaleState(f, db.blizzBarScale or 1)
            ApplyFrameXY(f, db)
        end
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            local c = GetCFG(unit)
            if not c or not c.defaultBar then return end

            local d = c.defaultBar
            if d.enabled == false then return end
            if d.useBlizzardDefaults == true then return end

            for _, f in ipairs(GetBlizzFrames(unit)) do
                if f then
                    ApplyScaleState(f, d.blizzBarScale or 1)
                    ApplyFrameXY(f, d)
                end
            end
        end)
    end
end

function DefBlizzCast:ApplyDefaultBlizzCastbar_Legacy(unit, showBar)
    local cfg = GetCFG(unit)
    if not cfg then return end
    DefBlizzCast:EnsureDefaultBarKeys(unit)

    local db = cfg.defaultBar

    DefBlizzCast:RefreshBlizzardCastbarHide(unit, showBar)
    if db.enabled == false then return end

    if db.useBlizzardDefaults then
        DefBlizzCast:RefreshBlizzardCastbarLayoutMode(unit, showBar)
    else
        ApplyCustomNowAndNextFrame(unit)
    end
end

function DefBlizzCast:ApplyDefaultBlizzCastbar(unit, showBar)
    local cfg = GetCFG(unit)
    if not cfg then return end
    DefBlizzCast:EnsureDefaultBarKeys(unit)

    if UCB:IsPlayer(unit, true) then
        EnsureVehicleHideEventFrame()
    end

    local db = cfg.defaultBar

    DefBlizzCast:RefreshBlizzardCastbarHide(unit, showBar)
    if db.enabled == false then return end

    if db.useBlizzardDefaults then
        DefBlizzCast:RefreshBlizzardCastbarLayoutMode(unit, showBar)
    else
        ApplyCustomNowAndNextFrame(unit)
    end
end
