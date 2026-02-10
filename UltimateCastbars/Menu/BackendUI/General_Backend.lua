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


function GeneralSettings_API:ResolveFrameWithRetry(g, which, frameName, opts)
    opts = opts or {}
    local timeout  = opts.timeout or 10
    local interval = opts.interval or 0.1

    -- which = "width" or "height"
    local refKey  = which == "width" and "_widthFrameRef"  or "_heightFrameRef"
    local errKey  = which == "width" and "_widthFrameError" or "_heightFrameError"

    -- empty = treat as UIParent/manual
    if not frameName or frameName == "" then
        g[refKey] = UIParent
        g[errKey] = false
        if UCB and UCB.ACR then UCB.ACR:NotifyChange("UCB") end
        return
    end

    local start = GetTime()
    local function try()
        local f = _G[frameName]
        if f then
            g[refKey] = f
            g[errKey] = false
            if UCB and UCB.ACR then UCB.ACR:NotifyChange("UCB") end
            return
        end

        if (GetTime() - start) >= timeout then
            g[refKey] = UIParent
            g[errKey] = true
            if UCB and UCB.ACR then UCB.ACR:NotifyChange("UCB") end
            return
        end

        C_Timer.After(interval, try)
    end

    try()
end


-- Wait up to `timeout` seconds for _G[frameName] to exist.
-- Calls `onDone(frame)` when found, or `onDone(nil)` on timeout.
function GeneralSettings_API:getFrameWhenReady(frameName, onDone, opts)
    opts = opts or {}
    local timeout  = opts.timeout or 10
    local interval = opts.interval or 0.1

    if not frameName or frameName == "" then
        if onDone then onDone(UIParent) end
        return
    end

    local start = GetTime()
    local function try()
        local frame = _G[frameName]
        if frame then
            if onDone then onDone(frame) end
            return
        end

        if (GetTime() - start) >= timeout then
            if onDone then onDone(nil) end
            return
        end

        C_Timer.After(interval, try)
    end

    try()
end


function GeneralSettings_API:ResolveAnchorWithRetry(g, opts)
    opts = opts or {}
    local timeout  = opts.timeout or 10
    local interval = opts.interval or 0.1

    -- default
    local defaultName = g._defaultAnchor or "UIParent"

    -- if using default, resolve immediately
    if g.useDefaultAnchor or not g.anchorName or g.anchorName == "" then
        g._anchorFrameRef = _G[defaultName] or UIParent
        g._anchorCustomError = false
        LibStub("AceConfigRegistry-3.0"):NotifyChange("UCB")
        return
    end

    local wanted = g.anchorName
    local start = GetTime()

    local function try()
        local f = _G[wanted]
        if f then
            g._anchorFrameRef = f
            g._anchorCustomError = false
            LibStub("AceConfigRegistry-3.0"):NotifyChange("UCB")
            return
        end

        if (GetTime() - start) >= timeout then
            -- timeout: flag error, fallback to default
            g._anchorCustomError = true
            g._anchorFrameRef = _G[defaultName] or UIParent
            LibStub("AceConfigRegistry-3.0"):NotifyChange("UCB")
            return
        end

        C_Timer.After(interval, try)
    end

    try()
end



function GeneralSettings_API:ResolveAllFramesOnLogin(opts)
    opts = opts or {}
    local timeout  = opts.timeout or 10
    local interval = opts.interval or 0.1

    local ACR = LibStub("AceConfigRegistry-3.0", true)

    local function notify()
        if ACR then ACR:NotifyChange("UCB") end
    end

    local function resolveWidthHeight(g)
        if not g then return end

        -- width
        if not g.manualWidth and g.widthInput and g.widthInput ~= "" then
            -- mark as pending; your UI can show "waiting"
            g._widthFrameError = false
            g._widthFrameRef = nil
            -- reuse your retry helper if you made it; otherwise do local retry:
            if self.ResolveFrameWithRetry then
                self:ResolveFrameWithRetry(g, "width", g.widthInput, {timeout=timeout, interval=interval})
            end
        end

        -- height
        if not g.manualHeight and g.heightInput and g.heightInput ~= "" then
            g._heightFrameError = false
            g._heightFrameRef = nil
            if self.ResolveFrameWithRetry then
                self:ResolveFrameWithRetry(g, "height", g.heightInput, {timeout=timeout, interval=interval})
            end
        end
    end

    local function resolveAnchor(g)
        if not g then return end
        if self.ResolveAnchorWithRetry then
            self:ResolveAnchorWithRetry(g, {timeout=timeout, interval=interval})
        end
    end

    -- Resolve all units you support
    for _, unit in ipairs({ "player", "target", "focus" }) do
        local big = (CFG_API and CFG_API.GetValueConfig) and CFG_API.GetValueConfig(unit)
        local g = big and big.general
        if g then
            resolveAnchor(g)
            resolveWidthHeight(g)
        end
    end

    notify()
end
