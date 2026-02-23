local ADDON_NAME, UCB = ...

UCB.GUIWidgets = UCB.GUIWidgets or {}
UCB.GUI = UCB.GUI or {}
UCB.UI = UCB.UI or {}
UCB.GUI.Helpers = UCB.GUI.Helpers or {}

-- GUIWidgets should be loaded before this file (or you can require it first)
local GUIWidgets = UCB.GUIWidgets
local UI = UCB.UI
local GUI = UCB.GUI
local GUI_Helpers = UCB.GUI.Helpers

GUI.optionsTable = GUI.optionsTable or {}
GUI._optionsRegistered = GUI._optionsRegistered or {}

local Container
-- ============================================================================
--  Root invalidation / rebuild helpers
-- ============================================================================

function GUI:InvalidateRootOptions()
    -- allow RegisterRootOptions() to rebuild + re-register
    self._rootOptionsRegistered = nil
    self.optionsTable = nil

    -- if you cache built args anywhere, clear them too (safe even if nil)
    if UCB.Options then
        UCB.Options._textTreeArgs  = UCB.Options._textTreeArgs  or {}
        UCB.Options._classTreeArgs = UCB.Options._classTreeArgs or {}
        wipe(UCB.Options._textTreeArgs)
        wipe(UCB.Options._classTreeArgs)
    end
end

function GUI:InvalidateUnitOptions(unit)
    if not unit then return end

    if UCB.Options then
        UCB.Options._textTreeArgs  = UCB.Options._textTreeArgs  or {}
        UCB.Options._classTreeArgs = UCB.Options._classTreeArgs or {}

        -- Prefer unit-keyed caches:
        if type(UCB.Options._textTreeArgs) == "table" then
            UCB.Options._textTreeArgs[unit] = nil
        end
        if type(UCB.Options._classTreeArgs) == "table" then
            UCB.Options._classTreeArgs[unit] = nil
        end
    end
end

function GUI:_EnsureUnitGroup(unit, order, displayName)
    self._unitGroups = self._unitGroups or {}

    if not self._unitGroups[unit] then
        self._unitGroups[unit] = {
            type  = "group",
            name  = displayName or unit,
            order = order or 1,
            args  = {}, -- swapped during unit rebuilds
        }
    end

    return self._unitGroups[unit]
end

function GUI:BuildRootOptionsTable()
    -- stable tables (important!)
    self._rootOptions = self._rootOptions or {}
    self._rootArgs    = self._rootArgs    or {}

    local treeArgs = {}

    -- Build / rebuild sub-args (MUST return tables)
    for unit, shown in pairs(UCB.menuUnits) do
        if shown then
            treeArgs[unit] = self:BuildUnitOptionsArgs(unit) or {}
        else
            treeArgs[unit] = {}
        end
    end

    -- Profiles group: BuildProfilesOptions() returns a group table; we want its args table
    local profArgs  = self:BuildProfilesOptions() or {}

    wipe(self._rootArgs)

    -- Stable unit group tables (so we can rebuild only one unit later)
    local playerGroup = self:_EnsureUnitGroup("player", 1, "Player")
    playerGroup.args = treeArgs["player"] or {}

    local targetGroup = self:_EnsureUnitGroup("target", 2, "Target")
    targetGroup.args = treeArgs["target"] or {}

    local focusGroup = self:_EnsureUnitGroup("focus", 3, "Focus")
    focusGroup.args = treeArgs["focus"] or {}

    self._rootArgs.player = playerGroup
    self._rootArgs.target = targetGroup
    self._rootArgs.focus  = focusGroup

    self._rootArgs.profiles = {
        type        = "group",
        name        = "Profiles",
        order       = 4,
        childGroups = "tab",
        args        = profArgs, -- MUST be a table (can be empty)
    }

    wipe(self._rootOptions)
    self._rootOptions.type        = "group"
    self._rootOptions.name        = "Ultimate Castbars"
    self._rootOptions.childGroups = "tab"
    self._rootOptions.args        = self._rootArgs

    return self._rootOptions
end

-- force=true will rebuild + re-register even if already registered before
function GUI:RegisterRootOptions(force)
    if self._rootOptionsRegistered and not force then return end
    self._rootOptionsRegistered = true

    self.optionsTable = self:BuildRootOptionsTable()

    UCB.AC:RegisterOptionsTable(self.appName, self.optionsTable)
end

function GUI:FullRebuildRootUI(path)
    -- preserve current selection path in ROOT if open somewhere
    local lastGroups = path
    if not path then
        lastGroups = GUI_Helpers:GetCurrentPath(self.appName)
    end

    -- close existing ROOT instance (standalone or embedded)
    if UCB.ACD and UCB.ACD.Close then
        UCB.ACD:Close(self.appName)
    end

    -- fully rebuild + re-register the ROOT options table (fresh closures/args)
    self:InvalidateRootOptions()
    self:RegisterRootOptions(true)

    -- reopen into the SAME holder if your custom GUI is open
    local parent = self._rootHolder
    if parent then
        parent:ReleaseChildren()
        if parent.SetLayout then parent:SetLayout("Fill") end
        if parent.SetFullWidth then parent:SetFullWidth(true) end
        if parent.SetFullHeight then parent:SetFullHeight(true) end

        UCB.ACD:Open(self.appName, parent)
    end

    -- notify + restore selection (next frame)
    C_Timer.After(0, function()
        UCB:NotifyChange()

      
        if lastGroups and #lastGroups > 0 then
            UCB:SelectGroup(lastGroups)
        else
            UCB:SelectGroup({"player", "general"})
        end

    end)
end

function GUI:QueueFullRebuildRootUI()
    self._rebuildQueued = self._rebuildQueued or {}
    if self._rebuildQueued[self.appName] then return end
    self._rebuildQueued[self.appName] = true

    C_Timer.After(0, function()
        self._rebuildQueued[self.appName] = nil
        self:FullRebuildRootUI()
    end)
end

function GUI:OnProfileSwapRefreshUI()
    -- If GUI is open, do a full rebuild so all closures/args rebind to the new DB
    if self._rootHolder then
        self:QueueFullRebuildRootUI()
        return
    end

    -- If not visible, just invalidate so next open builds from the new DB
    self:InvalidateRootOptions()
end


-- ============================================================================
--  Your custom window opener (no extra tabs; shows ROOT directly)
-- ============================================================================
local function PathKey(path)
  if type(path) ~= "table" then return "" end
  return table.concat(path, "\001")
end

function GUI:CloseGUI()
    if not self.isGUIOpen then return end

    if UCB.ACD and UCB.ACD.Close then
        UCB.ACD:Close(self.appName)
    end

    if Container then
        if GUIWidgets and GUIWidgets.DetachFooterBar then
            GUIWidgets:DetachFooterBar(Container)
        end
        UCB.AG:Release(Container)
        Container = nil
    end

    self._rootHolder = nil
    self.isGUIOpen = false
    self._currentSelectedTab = nil
end

function GUI:OpenGUI(selectPath)
    collectgarbage("collect")
    self:RegisterRootOptions()
    self.GUI = self.GUI or {}

    if InCombatLockdown and InCombatLockdown() then return end

    local cfg = UCB.GetValueConfig()
    if not selectPath then
        selectPath = cfg.misc.lastUIPath
        local ok, valid, badAt, reason = GUI_Helpers:ValidateGroupPath(selectPath)
        if not ok or not valid or #valid == 0 or selectPath == {} then
            selectPath = {"player","general"}
            cfg.misc.lastUIPath = selectPath
        end
    end

    local path = selectPath
    local wantedKey = PathKey(path)

    -- if already open: toggle or switch
    if self.isGUIOpen and Container then
        if self._currentSelectedKey == wantedKey then
            self:CloseGUI()
            return
        end
        -- ensure any changes are reflected before switching
        cfg.misc.lastUIPath = path
        UCB:SelectGroup(path)
        GUI:RefreshGUI(true, path)
        self._currentSelectedKey = wantedKey
        return
    end

    -- Otherwise: open fresh
    self.isGUIOpen = true
    self._currentSelectedTab = nil

    Container = UCB.AG:Create("Frame")
    Container:SetTitle(UI.text.name.." - v"..UI.text.version)
    Container:SetLayout("Fill")
    Container:SetWidth(1000)
    Container:SetHeight(800)
    Container:EnableResize(true)

    local MIN_W = 1000
    local function ClampMinWidth()
        if not Container or not Container.frame then return end
        local w = Container.frame:GetWidth()
        if w and w < MIN_W then
            Container.frame:SetWidth(MIN_W)
            if Container.SetWidth then Container:SetWidth(MIN_W) end
        end
    end
    Container.frame:HookScript("OnSizeChanged", ClampMinWidth)

    local function HookSizer(sizer)
        if not sizer then return end
        sizer:HookScript("OnMouseUp", ClampMinWidth)
        sizer:HookScript("OnMouseDown", ClampMinWidth)
    end
    HookSizer(Container.sizer_se)
    HookSizer(Container.sizer_e)
    HookSizer(Container.sizer_s)

    Container:SetCallback("OnClose", function(widget)
        local cfg = UCB.GetValueConfig()
        if cfg and cfg.misc then
            cfg.misc.lastUIPath = GUI_Helpers:GetCurrentPath(self.appName)
        end
        -- close the ACD app too (matches CloseGUI)
        if UCB.ACD and UCB.ACD.Close then
            UCB.ACD:Close(self.appName)
        end

        --if GUIWidgets and GUIWidgets.DetachBottomLeftLinks then
        if GUIWidgets and GUIWidgets.DetachFooterBar then
            --GUIWidgets:DetachBottomLeftLinks(widget)
            GUIWidgets:DetachFooterBar(widget)

        end

        UCB.AG:Release(widget)
        Container = nil

        self._rootHolder = nil
        self.isGUIOpen = false
        self._currentSelectedTab = nil
    end)

    GUIWidgets:AttachFooterBar(Container, {
        logo  = UI.icons.logo,
        title = UI.text.name,
        madeByName = UI.text.madeByM,
        links = {
            {
                id="github",
                text="GitHub",
                icon=UI.icons.github,
                title="GitHub",
                url=UI.links.github,
                width = 90,
            },
            {
                id="discord",
                text="Discord",
                icon=UI.icons.discord,
                title="Discord",
                url=UI.links.discord,
                width = 90,
            },
            {
                id="donate",
                text="Donate",
                icon=UI.icons.donate,
                title="Donate",
                url={
                    { label = "Ko-fi",   url = UI.links.kofi },
                    { label = "PayPal",  url = UI.links.paypal },
                    { label = "Patreon", url = UI.links.patreon },
                },
                width = 90,
            },
        }
    })
    
    GUIWidgets:AttachTopRightChangelogButton(Container)

    local holder = UCB.AG:Create("SimpleGroup")
    holder:SetFullWidth(true)
    holder:SetFullHeight(true)
    holder:SetLayout("Fill")
    Container:AddChild(holder)

    self._rootHolder = holder

    -- make sure old instance is closed before opening into holder
    if UCB.ACD and UCB.ACD.Close then
        UCB.ACD:Close(self.appName)
    end
    UCB.ACD:Open(self.appName, holder)

    UCB:NotifyChange()

    C_Timer.After(0, function()
        if self.isGUIOpen then
            UCB:SelectGroup(path)
            GUI:RefreshGUI(true, path)
            self._currentSelectedKey = wantedKey
        end
    end)
end


function GUI:RefreshGUI(hard, path)
    if not (self.isGUIOpen and UCB.ACD) then return end

    local st = GUI_Helpers:GetCurrentPath(self.appName)
    local groups = path or st

    -- If an editbox is focused, Ace may not repaint that field value.
    local focused = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
    if focused and focused.ClearFocus then
        focused:ClearFocus()
    end

    -- Hard refresh: rebuild options + reopen + restore selected path.
    if hard then
        self:FullRebuildRootUI(groups) -- your existing function already preserves/restores selection
        return
    end

    -- Soft refresh: notify + reselect twice (next frames)
    UCB:NotifyChange()

    C_Timer.After(0, function()
        if not self.isGUIOpen then return end
        UCB:SelectGroup(groups)
        C_Timer.After(0, function()
            if not self.isGUIOpen then return end
            UCB:SelectGroup(groups)
        end)
    end)
end

-- ============================================================================
-- NEW: Unit-only rebuild / refresh helpers
-- ============================================================================
function GUI:RebuildUnitOptions(unit)
    if not unit then return end

    -- Ensure ROOT exists (so unit group tables exist)
    self:RegisterRootOptions()

    local shown = UCB.menuUnits and UCB.menuUnits[unit]
    local newArgs = {}

    if shown then
        self:InvalidateUnitOptions(unit)
        newArgs = self:BuildUnitOptionsArgs(unit) or {}
    end

    -- Swap only the unit args (stable group table)
    local grp = self._unitGroups and self._unitGroups[unit]
    if grp then
        grp.args = newArgs
        return
    end

    -- Fallback (if _unitGroups wasn't wired)
    if self._rootArgs and self._rootArgs[unit] then
        self._rootArgs[unit].args = newArgs
    end
end

function GUI:RefreshUnitUI(unit, path)
    if not unit then return end

    self:RebuildUnitOptions(unit)

    -- If not open, just leave it rebuilt/invalidated for next open
    if not (self.isGUIOpen and UCB.ACD) then
        return
    end

    local groups = path or GUI_Helpers:GetCurrentPath(self.appName)

    -- If an editbox is focused, Ace may not repaint that field value.
    local focused = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
    if focused and focused.ClearFocus then
        focused:ClearFocus()
    end

    UCB:NotifyChange()

    UCB:SelectGroup(groups)

    -- AceConfigDialog sometimes needs a double select to repaint reliably
    C_Timer.After(0, function()
        if not self.isGUIOpen then return end
        UCB:SelectGroup(groups)
        C_Timer.After(0, function()
            if not self.isGUIOpen then return end
            UCB:SelectGroup(groups)
        end)
    end)
end

function GUI:QueueUnitRebuild(unit, path)
    if not unit then return end

    self._unitRebuildQueued = self._unitRebuildQueued or {}
    local key = tostring(self.appName) .. ":" .. tostring(unit)
    if self._unitRebuildQueued[key] then return end
    self._unitRebuildQueued[key] = true

    C_Timer.After(0, function()
        self._unitRebuildQueued[key] = nil
        self:RefreshUnitUI(unit, path)
    end)
end