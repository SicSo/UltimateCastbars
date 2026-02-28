local ADDON_NAME, UCB = ...

UCB.Migration = UCB.Migration or {}

local M = {}

-- =========================
-- Helpers
-- =========================

local function _isTable(t) return type(t) == "table" end

local function EnsureTable(root, ...)
    local t = root
    for i = 1, select("#", ...) do
        local k = select(i, ...)
        if not _isTable(t[k]) then t[k] = {} end
        t = t[k]
    end
    return t
end

local function GetPath(root, ...)
    local t = root
    for i = 1, select("#", ...) do
        if not _isTable(t) then return nil end
        t = t[select(i, ...)]
    end
    return t
end

local function SetPath(root, value, ...)
    local n = select("#", ...)
    if n == 0 then return end
    local t = root
    for i = 1, n - 1 do
        local k = select(i, ...)
        if not _isTable(t[k]) then t[k] = {} end
        t = t[k]
    end
    t[select(n, ...)] = value
end

local function DelPath(root, ...)
    local n = select("#", ...)
    if n == 0 then return end
    local t = root
    for i = 1, n - 1 do
        t = t[select(i, ...)]
        if not _isTable(t) then return end
    end
    t[select(n, ...)] = nil
end

local function MovePath(root, fromPath, toPath, opts)
    -- fromPath/toPath: arrays like {"style"} or {"styleCastType","general"}
    -- opts.onlyIfDestNil: true by default
    opts = opts or {}
    local onlyIfDestNil = (opts.onlyIfDestNil ~= false)

    local fromVal = GetPath(root, unpack(fromPath))
    if fromVal == nil then return false end

    local toVal = GetPath(root, unpack(toPath))

    if onlyIfDestNil and toVal ~= nil then
        -- still delete source if requested
        if opts.deleteSourceIfDestExists then
            DelPath(root, unpack(fromPath))
        end
        return false
    end

    SetPath(root, fromVal, unpack(toPath))
    DelPath(root, unpack(fromPath))
    return true
end

local function RenameKey(tbl, oldKey, newKey, opts)
    opts = opts or {}
    if not _isTable(tbl) then return false end
    if tbl[oldKey] == nil then return false end
    if (opts.onlyIfDestNil ~= false) and tbl[newKey] ~= nil then
        if opts.deleteSourceIfDestExists then tbl[oldKey] = nil end
        return false
    end
    tbl[newKey] = tbl[oldKey]
    tbl[oldKey] = nil
    return true
end

local function DeepMergeMissing(dst, src)
    -- Copies ONLY missing keys from src into dst (recursive for tables).
    if not _isTable(dst) or not _isTable(src) then return end
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = v
        elseif _isTable(dst[k]) and _isTable(v) then
            DeepMergeMissing(dst[k], v)
        end
    end
end

-- Expose helpers if you want to use them in revisions
M.EnsureTable = EnsureTable
M.GetPath = GetPath
M.SetPath = SetPath
M.DelPath = DelPath
M.MovePath = MovePath
M.RenameKey = RenameKey
M.DeepMergeMissing = DeepMergeMissing

-- =========================
-- Migration registration
-- =========================

-- Each revision is a list of steps (functions(profile) -> nil/true/false)
local REVISIONS = {}   -- [rev] = { step1, step2, ... }
local LATEST = 0

function M.Latest()
    return LATEST
end

function M.RegisterRevision(rev, ...)
    assert(type(rev) == "number" and rev >= 1, "rev must be a number >= 1")
    local steps = REVISIONS[rev] or {}
    for i = 1, select("#", ...) do
        local fn = select(i, ...)
        assert(type(fn) == "function", "All revision steps must be functions")
        table.insert(steps, fn)
    end
    REVISIONS[rev] = steps
    if rev > LATEST then LATEST = rev end
end

-- Applies revisions to *one* AceDB profile table.
-- opts.schemaKey: where to store schema version (default "__schemaVersion")
-- opts.latest: override latest (default M.Latest())
function M.Apply(profile, opts)
    opts = opts or {}
    local schemaKey = opts.schemaKey or "__schemaVersion"
    local latest = opts.latest or LATEST

    if not _isTable(profile) then
        return false, "profile is not a table"
    end

    local v = tonumber(profile.misc[schemaKey]) or 0

    while v < latest do
        v = v + 1
        local steps = REVISIONS[v]
        if steps then
            for _, step in ipairs(steps) do
                local ok, err = pcall(step, profile)
                if not ok then
                    return false, ("migration r%d failed: %s"):format(v, tostring(err))
                end
            end
        end
    end
    profile.misc[schemaKey] = latest
    return true
end

-- =========================
-- Example revisions (remove/replace with your own)
-- =========================

-- Example: v2 migration: move top-level "style" into "styleCastType.general"
-- and ensure the new structure exists.
-- NOTE: this file does NOT know your createStyle() function; pass one in via closures.
-- You can register steps from your addon file instead, using createStyle in scope.

-- =========================
-- Recommended usage
-- =========================
-- In your addon file:
--
-- local Migrations = UCB_Migrations
-- Migrations.RegisterRevision(2,
--   function(p)
--     -- ensure styleCastType exists with required keys
--     local sct = p.styleCastType
--     if type(sct) ~= "table" then sct = {} ; p.styleCastType = sct end
--     if sct.useGeneralStyle == nil then sct.useGeneralStyle = true end
--     if sct.general == nil then sct.general = createStyle() end
--     if sct.normal == nil then sct.normal = createStyle() end
--     if sct.channel == nil then sct.channel = createStyle() end
--     if sct.empowered == nil then sct.empowered = createStyle() end
--   end,
--   function(p)
--     -- move old key, only if general missing
--     Migrations.MovePath(p, {"style"}, {"styleCastType","general"}, { onlyIfDestNil = true })
--   end
-- )
--
-- Then, after SetProfile():
-- local ok, err = Migrations.Apply(UCB.db.profile, { schemaKey="__schemaVersion" })
-- if not ok then print("UCB migrations failed:", err) end

UCB.Migration = M


