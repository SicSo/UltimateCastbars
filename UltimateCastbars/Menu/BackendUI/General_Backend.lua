local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.GeneralSettings_API = UCB.GeneralSettings_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local GeneralSettings_API = UCB.GeneralSettings_API


function GeneralSettings_API:addNewItemList(tbl, item)
    for _, v in ipairs(tbl) do
        if v == item then
            return -- Item already exists, do not add
        end
    end
    table.insert(tbl, item)
end

function GeneralSettings_API:getFrame(frameName)
    if not frameName or frameName == "" then
        return UIParent
    end

    local frame = _G[frameName]
    if not frame then
        return nil
    end

    return frame
end


function GeneralSettings_API:ResolveFrameWithRetry(unit, g, which, frameName, opts)
    opts = opts or {}
    local tries = tonumber(opts.tries) or 50
    local interval = tonumber(opts.interval) or 0.1
    local delay = tonumber(opts.delay) or 0.1
    if tries < 1 then tries = 1 end
    if interval <= 0 then interval = 0.1 end
    if delay < 0 then delay = 0.1 end

    local refKey = which == "width" and "_widthFrameRef" or "_heightFrameRef"
    local errKey = which == "width" and "_widthFrameError" or "_heightFrameError"

    if not frameName or frameName == "" then
        g[refKey] = UIParent
        g[errKey] = false
        UCB:NotifyChange(unit)
        return
    end

    local attempt = 0
    local function tryResolve()
        attempt = attempt + 1

        local f = _G[frameName]
        if f then
            g[refKey] = f
            g[errKey] = false
            UCB:NotifyChange(unit)
            return
        end

        if attempt >= tries then
            g[refKey] = UIParent
            g[errKey] = true
            UCB:NotifyChange(unit)
            return
        end

        C_Timer.After(interval, tryResolve)
    end

    if delay > 0 then
        C_Timer.After(delay, tryResolve)
    else
        tryResolve()
    end
end



-- Wait up to `timeout` seconds for _G[frameName] to exist.
-- Calls `onDone(frame)` when found, or `onDone(nil)` on timeout.
function GeneralSettings_API:getFrameWhenReady(frameName, onDone, opts)
    opts = opts or {}
    local tries = tonumber(opts.tries) or 50
    local interval = tonumber(opts.interval) or 0.1
    if tries < 1 then tries = 1 end
    if interval <= 0 then interval = 0.1 end


    if not frameName or frameName == "" then
        if onDone then onDone(UIParent) end
        return
    end

    local attempt = 0
    local function try()
        attempt = attempt + 1

        local f = _G[frameName] -- or _G[wanted] for anchor
        if f then
            -- success
            return
        end

        if attempt >= tries then
            -- fail/fallback
            return
        end

        C_Timer.After(interval, try)
    end

    try()
end


function GeneralSettings_API:ResolveAnchorWithRetry(unit, g, opts)
    opts = opts or {}
    local tries = tonumber(opts.tries) or 50
    local interval = tonumber(opts.interval) or 0.1
    if tries < 1 then tries = 1 end
    if interval <= 0 then interval = 0.1 end

    local defaultName = g._defaultAnchor or "UIParent"

    -- default anchor path
    if g.useDefaultAnchor or not g.anchorName or g.anchorName == "" then
        g._anchorFrameRef = _G[defaultName] or UIParent
        g._anchorCustomError = false
        UCB:NotifyChange(unit)
        return
    end

    local wanted = g.anchorName
    local attempt = 0

    local function tryResolve()
        attempt = attempt + 1

        local f = _G[wanted]
        if f then
            g._anchorFrameRef = f
            g._anchorCustomError = false
            UCB:NotifyChange(unit)
            return
        end

        if attempt >= tries then
            g._anchorCustomError = true
            g._anchorFrameRef = _G[defaultName] or UIParent
            UCB:NotifyChange(unit)
            return
        end

        C_Timer.After(interval, tryResolve)
    end

    tryResolve()
end



function GeneralSettings_API:ResolveAllFramesOnLogin(opts)
    opts = opts or {}
    local anchorTries = tonumber(opts.anchorTries) or 50
    local anchorInterval = tonumber(opts.anchorInterval) or 0.1
    local syncTries = tonumber(opts.frameTries) or 50
    local syncInterval = tonumber(opts.frameInterval) or 0.1
    local syncDelay = tonumber(opts.syncDelay) or 0.1
    local anchorDelay = tonumber(opts.anchorDelay) or 0.1

    local function notify(unit)
        UCB:NotifyChange(unit)
    end

    local function resolveWidthHeight(unit, g)
        if not g then return end

        -- width
        if not g.manualWidth and g.widthInput and g.widthInput ~= "" then
            -- mark as pending; your UI can show "waiting"
            g._widthFrameError = false
            g._widthFrameRef = nil
            -- reuse your retry helper if you made it; otherwise do local retry:
            if self.ResolveFrameWithRetry then
                self:ResolveFrameWithRetry(unit, g, "width", g.widthInput, {tries=syncTries, interval=syncInterval, delay = syncDelay})
            end
        end

        -- height
        if not g.manualHeight and g.heightInput and g.heightInput ~= "" then
            g._heightFrameError = false
            g._heightFrameRef = nil
            if self.ResolveFrameWithRetry then
                self:ResolveFrameWithRetry(unit, g, "height", g.heightInput, {tries=syncTries, interval=syncInterval, delay = syncDelay})
            end
        end
    end

    local function resolveAnchor(unit, g)
        if not g then return end
        if self.ResolveAnchorWithRetry then
            self:ResolveAnchorWithRetry(unit, g, {tries=anchorTries, interval=anchorInterval, delay = anchorDelay})
        end
    end

    -- Resolve all units you support
    for _, unit in ipairs({ "player", "target", "focus" }) do
        local big = (CFG_API and CFG_API.GetValueConfig) and CFG_API.GetValueConfig(unit)
        local g = big and big.general
        if g then
            resolveAnchor(unit, g)
            resolveWidthHeight(unit, g)
        end
        notify(unit)
    end
end
