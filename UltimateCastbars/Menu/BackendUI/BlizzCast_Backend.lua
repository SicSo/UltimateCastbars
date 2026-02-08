local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.DefBlizzCast = UCB.DefBlizzCast or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local DefBlizzCast = UCB.DefBlizzCast

local function RegisterEventSafe(frame, eventName)
    if not frame or not eventName then return false end
    local ok = pcall(frame.RegisterEvent, frame, eventName)
    return ok
end


local function IsUnitCastingOrChanneling(unit)
    if UnitCastingInfo and UnitCastingInfo(unit) then return true end
    if UnitChannelInfo and UnitChannelInfo(unit) then return true end
    return false
end


-- ============================================================
-- Helpers: Blizzard frames
-- ============================================================
local function GetBlizzFrames()
    return {
        _G.PlayerCastingBarFrame,
        _G.CastingBarFrame,
    }
end

-- Try to pick a sane default unit for event-driven refresh
local function GetPrimaryUnit()
    -- Most addons store player config under "player"
    if GetCfg and GetCfg("player") then return "player" end
    -- Fallback: some store under "PLAYER"
    if GetCfg and GetCfg("PLAYER") then return "PLAYER" end
    return "player"
end

-- ============================================================
-- State capture / restore
--   __pcbOrig         : one-time "first seen" snapshot (fallback)
--   __ucbBlizzBaseline: refreshed snapshot of *current Blizzard layout*
-- ============================================================
local function CaptureState(f)
    if not f then return nil end

    local s = {
        parent = (f.GetParent and f:GetParent()) or UIParent,
        scale  = (f.GetScale  and f:GetScale())  or 1,
        alpha  = (f.GetAlpha  and f:GetAlpha())  or 1,
        strata = (f.GetFrameStrata and f:GetFrameStrata()) or nil,
        level  = (f.GetFrameLevel  and f:GetFrameLevel())  or nil,
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
        f:SetParent(s.parent)
    end

    if f.ClearAllPoints and f.SetPoint and s.points then
        f:ClearAllPoints()
        for _, pt in ipairs(s.points) do
            local p, rt, rp, x, y = pt[1], pt[2], pt[3], pt[4], pt[5]
            if rt == nil then rt = s.parent or UIParent end
            f:SetPoint(p, rt, rp, x, y)
        end
    end

    if f.SetFrameStrata and s.strata then pcall(function() f:SetFrameStrata(s.strata) end) end
    if f.SetFrameLevel  and s.level  then pcall(function() f:SetFrameLevel(s.level) end) end
    if f.SetScale and s.scale then pcall(function() f:SetScale(s.scale) end) end
    if f.SetAlpha and s.alpha then pcall(function() f:SetAlpha(s.alpha) end) end
end

local function CacheFrameState(f)
    if not f or f.__pcbCached then return end
    f.__pcbCached = true
    f.__pcbOrig = CaptureState(f)
end

-- Prefer baseline (if it exists) otherwise fallback to orig
local function RestoreFrameState(f)
    if not f then return end
    ApplyCapturedState(f, f.__ucbBlizzBaseline or f.__pcbOrig)
end

-- Snapshot the CURRENT Blizzard layout (post Edit Mode / layout updates)
-- This must only be done when we're ACTUALLY in Blizzard mode, otherwise we'd
-- just snapshot our custom position and call it "baseline".
local function SnapshotBlizzBaseline()
    for _, f in ipairs(GetBlizzFrames()) do
        if f then
            f.__ucbBlizzBaseline = CaptureState(f)
        end
    end
end

-- ============================================================
-- "Late restore" helper:
-- Blizzard / EditMode can re-anchor after you restore.
-- Doing a second restore next frame fixes the common anchor drift.
-- ============================================================
local function RestoreBlizzBaselineWithDelay()
    for _, f in ipairs(GetBlizzFrames()) do
        if f then
            CacheFrameState(f)
            RestoreFrameState(f)
        end
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            for _, f in ipairs(GetBlizzFrames()) do
                if f then
                    RestoreFrameState(f)
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
    CacheFrameState(f) -- caches first-seen fallback
    if f.SetScale then
        pcall(function() f:SetScale(scale) end)
    end
end

function DefBlizzCast:RefreshBlizzardCastbarScale(unit)
    local cfg = GetCfg(unit)
    if not cfg or not cfg.defaultBar then return end

    local scale = cfg.defaultBar.blizzBarScale or 1

    for _, f in ipairs(GetBlizzFrames()) do
        if f then
            ApplyScaleState(f, scale)
        end
    end
end

-- ============================================================
-- Hide
-- ============================================================
local function ApplyHideState(f, shouldHide, dontForceShow)
    if not f then return end
    CacheFrameState(f)

    if shouldHide then
        if f.SetParent then f:SetParent(UCB.defaultCastbarFrame) end
        if f.SetAlpha then pcall(function() f:SetAlpha(0) end) end
        if f.Hide then f:Hide() end
    else
        -- Don’t restore points here. Only prep visibility.
        local o = f.__pcbOrig
        if f.SetParent and o and o.parent then f:SetParent(o.parent) end
        if f.SetAlpha then pcall(function() f:SetAlpha((o and o.alpha) or 1) end) end

        -- If dontForceShow==true, DO NOT call Show().
        if not dontForceShow and f.Show then
            f:Show()
        end
    end
end


function DefBlizzCast:RefreshBlizzardCastbarHide(unit, showBar)
    local cfg = GetCfg(unit)
    if not cfg then return end
    cfg.defaultBar = cfg.defaultBar or {}

    local shouldHide = (cfg.defaultBar.enabled == false)

    -- On initialApply we only want to show if a cast/channel is active
    local dontForceShow = false
    if showBar == false and shouldHide == false then
        dontForceShow = not IsUnitCastingOrChanneling(unit)
    end

    for _, f in ipairs(GetBlizzFrames()) do
        if f then
            if not f.__ucbHideHooked then
                f.__ucbHideHooked = true

                f:HookScript("OnShow", function(self)
                    local c = GetCfg(unit)
                    if c and c.defaultBar and c.defaultBar.enabled == false then
                        ApplyHideState(self, true)
                    end
                end)

                if hooksecurefunc then
                    hooksecurefunc(f, "Show", function(self)
                        local c = GetCfg(unit)
                        if c and c.defaultBar and c.defaultBar.enabled == false then
                            ApplyHideState(self, true)
                        end
                    end)
                end
            end

            ApplyHideState(f, shouldHide, dontForceShow)
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

    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, point, x, y)
end

function DefBlizzCast:UpdateDefaultCastbarPosition(x, y, point, unit)
    local cfg = GetCfg(unit)
    if not cfg then return end
    cfg.defaultBar = cfg.defaultBar or {}

    cfg.defaultBar.anchorPoint = point or cfg.defaultBar.anchorPoint or "CENTER"
    cfg.defaultBar.offsetX = tonumber(x) or 0
    cfg.defaultBar.offsetY = tonumber(y) or 0

    for _, f in ipairs(GetBlizzFrames()) do
        if f then
            ApplyFrameXY(f, cfg.defaultBar)
        end
    end

    if UCB.ACR then
        UCB.ACR:NotifyChange("UCB")
    end
end

-- ============================================================
-- Defaults
-- ============================================================
function DefBlizzCast:EnsureDefaultBarKeys(unit)
    local cfg = GetCfg(unit)
    if not cfg then return end

    cfg.defaultBar = cfg.defaultBar or {}
    local db = cfg.defaultBar

    if db.enabled == nil then db.enabled = true end

    -- Toggle default: use Blizzard/original layout unless user chooses custom
    if db.useBlizzardDefaults == nil then db.useBlizzardDefaults = true end

    if db.blizzBarScale == nil then db.blizzBarScale = 1 end
    if db.anchorPoint == nil then db.anchorPoint = "CENTER" end
    if db.offsetX == nil then db.offsetX = 0 end
    if db.offsetY == nil then db.offsetY = 0 end
end

-- ============================================================
-- Baseline updater (events)
-- Keeps __ucbBlizzBaseline correct when Blizzard/EditMode moves stuff.
-- We only snapshot when "useBlizzardDefaults" is true AND the bar is enabled.
-- ============================================================
local function EnsureBaselineEventFrame()
    if UCB.__ucbBlizzBaselineEvents then return end

    local ef = CreateFrame("Frame")
    UCB.__ucbBlizzBaselineEvents = ef

    -- Always-safe, widely supported events
    ef:RegisterEvent("PLAYER_ENTERING_WORLD")
    ef:RegisterEvent("PLAYER_LOGIN")
    ef:RegisterEvent("UI_SCALE_CHANGED")
    ef:RegisterEvent("DISPLAY_SIZE_CHANGED")

    -- Edit Mode events differ by client/version -> register safely.
    -- Try a few known names; unknown ones will be ignored without error.
    RegisterEventSafe(ef, "EDIT_MODE_LAYOUTS_UPDATED")
    RegisterEventSafe(ef, "EDIT_MODE_LAYOUT_UPDATED")
    RegisterEventSafe(ef, "EDIT_MODE_LAYOUTS_RESET")

    ef:SetScript("OnEvent", function()
        local unit = GetPrimaryUnit()
        local cfg = GetCfg(unit)
        if not cfg then return end
        cfg.defaultBar = cfg.defaultBar or {}
        local db = cfg.defaultBar

        -- Only update baseline when Blizzard mode is active and not hidden
        if db.useBlizzardDefaults and db.enabled ~= false then
            CacheFrameState(_G.PlayerCastingBarFrame)
            CacheFrameState(_G.CastingBarFrame)

            SnapshotBlizzBaseline()
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    local c = GetCfg(unit)
                    if c and c.defaultBar and c.defaultBar.useBlizzardDefaults and c.defaultBar.enabled ~= false then
                        SnapshotBlizzBaseline()
                    end
                end)
            end
        end
    end)
end


-- ============================================================
-- Layout mode toggle
--   Fixes anchor drift by:
--     1) Maintaining a dedicated Blizzard baseline snapshot
--     2) Restoring baseline with a next-frame "late restore"
--     3) Updating baseline on key Blizzard/EditMode events
-- ============================================================
function DefBlizzCast:RefreshBlizzardCastbarLayoutMode(unit, showBar)
    EnsureBaselineEventFrame()

    local cfg = GetCfg(unit)
    if not cfg then return end
    DefBlizzCast:EnsureDefaultBarKeys(unit)

    local db = cfg.defaultBar

    if db.useBlizzardDefaults then
        -- Returning to Blizzard mode:
        -- Restore baseline (or orig fallback) and do a late restore to beat EditMode/layout manager.
        for _, f in ipairs(GetBlizzFrames()) do
            if f then
                CacheFrameState(f) -- ensures __pcbOrig exists
            end
        end

        RestoreBlizzBaselineWithDelay()

        -- After restoring, refresh baseline so future restores match the *current* Blizzard layout
        -- (especially if Blizzard adjusts between frames).
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                local c = GetCfg(unit)
                if c and c.defaultBar and c.defaultBar.useBlizzardDefaults and c.defaultBar.enabled ~= false then
                    SnapshotBlizzBaseline()
                end
            end)
        else
            SnapshotBlizzBaseline()
        end
    else
        -- Leaving Blizzard mode -> snapshot Blizzard baseline NOW (only if we were in blizz mode)
        -- If baseline already exists it's fine; this keeps it "fresh" before we start moving frames.
        SnapshotBlizzBaseline()

        -- Apply custom placement+scale
        for _, f in ipairs(GetBlizzFrames()) do
            if f then
                CacheFrameState(f)
                ApplyScaleState(f, db.blizzBarScale or 1)
                ApplyFrameXY(f, db)
            end
        end
    end

    -- If user is hiding the default bar, re-apply hide after layout switch
    if db.enabled == false then
        DefBlizzCast:RefreshBlizzardCastbarHide(unit, showBar)
    end
end


local function ApplyCustomNowAndNextFrame(unit)
    local cfg = GetCfg(unit)
    if not cfg or not cfg.defaultBar then return end
    local db = cfg.defaultBar

    for _, f in ipairs(GetBlizzFrames()) do
        if f then
            ApplyScaleState(f, db.blizzBarScale or 1)
            ApplyFrameXY(f, db)
        end
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            local c = GetCfg(unit)
            if not c or not c.defaultBar then return end
            local d = c.defaultBar
            if d.enabled == false then return end
            if d.useBlizzardDefaults == true then return end

            for _, f in ipairs(GetBlizzFrames()) do
                if f then
                    ApplyScaleState(f, d.blizzBarScale or 1)
                    ApplyFrameXY(f, d)
                end
            end
        end)
    end
end


function DefBlizzCast:ApplyDefaultBlizzCastbar(unit, showBar)
    local cfg = GetCfg(unit)
    if not cfg then return end
    DefBlizzCast:EnsureDefaultBarKeys(unit)

    local db = cfg.defaultBar

    -- install hooks + hide/show
    DefBlizzCast:RefreshBlizzardCastbarHide(unit, showBar)
    if db.enabled == false then return end

    if db.useBlizzardDefaults then
        -- restore Blizzard baseline
        DefBlizzCast:RefreshBlizzardCastbarLayoutMode(unit)
    else
        -- force custom and beat late Blizzard anchoring
        ApplyCustomNowAndNextFrame(unit)
    end
end
