local _, UCB = ...

if not UCB then return end

UCB.AG = UCB.AG or (LibStub and LibStub("AceGUI-3.0", true))
local AG = UCB.AG
if not AG then return end

UCB.GUIWidgets = UCB.GUIWidgets or {}

-- GUIWidgets should be loaded before this file (or you can require it first)
local GUIWidgets = UCB.GUIWidgets

local UCBGUI = UCB.GUI or {}
UCB.GUI = UCBGUI

local isGUIOpen = false
local Container

--[[
function UCBGUI:BuildUnitTab(contentFrame, unit)
    contentFrame:ReleaseChildren()

    if UCB and UCB.OpenOptionsInContainer then
        UCB:OpenOptionsInContainer(contentFrame, unit)
        return
    end

    local label = AG:Create("Label")
    label:SetFullWidth(true)
    label:SetText("Options not available.")
    contentFrame:AddChild(label)
end


UCBGUI._embedParent = UCBGUI._embedParent or {}

local UNIT_TABS = { player = true, target = false, focus = false }

function SelectMainTab(tabGroup, event, tabValue)
    UCB.GUI.selectedTab = tabValue
    tabGroup:ReleaseChildren()

    local wrapper = AG:Create("SimpleGroup")
    wrapper:SetFullWidth(true)
    wrapper:SetFullHeight(true)
    wrapper:SetLayout("Fill")
    tabGroup:AddChild(wrapper)

    local holder = AG:Create("SimpleGroup")
    holder:SetFullWidth(true)
    holder:SetFullHeight(true)
    holder:SetLayout("Fill")
    wrapper:AddChild(holder)

    -- store holder so we can refresh THIS tab if needed
    UCBGUI._embedParent = UCBGUI._embedParent or {}
    UCBGUI._embedParent[tabValue] = holder

    if UNIT_TABS[tabValue] then
        UCBGUI:BuildUnitTab(holder, tabValue)
        return
    end

    if tabValue == "profiles" then
        if UCB and UCB.OpenProfilesInContainer then
            UCB:OpenProfilesInContainer(holder)
        else
            local label = AG:Create("Label")
            label:SetFullWidth(true)
            label:SetText("Profiles options not available.")
            holder:AddChild(label)
        end
        return
    end
end


function UCB:InvalidateUnitOptions(unit)
    UCB._optionsRegistered = UCB._optionsRegistered or {}
    UCB.optionsTable = UCB.optionsTable or {}

    UCB._optionsRegistered[unit] = nil
    UCB.optionsTable[unit] = nil
end


function UCB:OpenGUI()
    if isGUIOpen then return end
    if InCombatLockdown and InCombatLockdown() then return end

    isGUIOpen = true

    Container = AG:Create("Frame")
    Container:SetTitle(UCB.PRETTY_ADDON_NAME or "Ultimate Castbars")
    Container:SetLayout("Fill")
    Container:SetWidth(1000)
    Container:SetHeight(800)
    Container:EnableResize(true)
    -- Minimum size
    local MIN_W = 1000
    local function ClampMinWidth()
        if not Container or not Container.frame then return end
        local w = Container.frame:GetWidth()
        if w and w < MIN_W then
            Container.frame:SetWidth(MIN_W)
            -- also update AceGUI's stored width so it doesn't fight you
            if Container.SetWidth then Container:SetWidth(MIN_W) end
        end
    end

    -- Clamp whenever size changes (covers dragging and programmatic resizes)
    Container.frame:HookScript("OnSizeChanged", function()
        ClampMinWidth()
    end)

    -- Extra safety: clamp when the user finishes dragging a sizer
    local function HookSizer(sizer)
        if not sizer then return end
        sizer:HookScript("OnMouseUp", function()
            ClampMinWidth()
        end)
        sizer:HookScript("OnMouseDown", function()
            ClampMinWidth()
        end)
    end

    HookSizer(Container.sizer_se)
    HookSizer(Container.sizer_e)
    HookSizer(Container.sizer_s)

    Container:SetCallback("OnClose", function(widget)
        if GUIWidgets and GUIWidgets.DetachBottomLeftLinks then
            GUIWidgets:DetachBottomLeftLinks(widget)
        end
        AG:Release(widget)
        isGUIOpen = false
        Container = nil
    end)


    -- Header links (left of the close X)
    local discordUrl = "https://discord.gg/wX5hWW3N3Q"
    local supportUrl = "https://ko-fi.com/sicso"

    GUIWidgets:AttachBottomLeftLinks(Container, {
        {
            text  = "Need support or want to suggest features? Join Discord!",
            title = "Discord",
            url   = discordUrl,
        },
        {
            text  = "Good addons take a lot of personal time to develop. Support the creator if you can!",
            title = "Support the creator",
            url   = supportUrl,
        },
    })



    local tabGroup = AG:Create("TabGroup")
    tabGroup:SetFullWidth(true)
    tabGroup:SetFullHeight(true)
    tabGroup:SetLayout("Fill")
    tabGroup:SetTabs({
        { text = "Player", value = "player" },
        { text = "Target", value = "target" },
        { text = "Focus",  value = "focus"  },
        { text = "Profiles", value = "profiles" },
    })
    tabGroup:SetCallback("OnGroupSelected", SelectMainTab)

    UCBGUI.tabGroup = tabGroup
    UCBGUI.selectedTab = "player"

    Container:AddChild(tabGroup)

    -- Default tab
    tabGroup:SelectTab("player")
end

function UCB:RefreshGUI()
    if not Container or not UCB.GUI or not UCB.GUI.tabGroup then return end

    local tg = UCB.GUI.tabGroup
    local tab = UCB.GUI.selectedTab or (tg.status and tg.status.selected) or "player"

    -- Force rebuild of the current tab contents
    tg:SelectTab(tab)
end


function UCB:FullRebuildOptionsUI(unit)
    unit = unit or "player"
    local appName = UCB:AppNameForUnit(unit)

    -- preserve selection path if that app is currently open
    local lastGroups
    if self.ACD and self.ACD.GetStatus then
        local st = self.ACD:GetStatus(appName)
        lastGroups = st and st.groups
    end

    -- close existing instance of this app (standalone or embedded)
    if self.ACD and self.ACD.Close then
        self.ACD:Close(appName)
    end

    -- force rebuild of options table
    self:InvalidateUnitOptions(unit)
    self:EnsureOptionsRegistered(unit)

    -- If this unit tab is currently visible, re-open into its holder.
    local parent = self.GUI and self.GUI._embedParent and self.GUI._embedParent[unit]
    if parent then
        parent:ReleaseChildren()
        if parent.SetLayout then parent:SetLayout("Fill") end
        if parent.SetFullWidth then parent:SetFullWidth(true) end
        if parent.SetFullHeight then parent:SetFullHeight(true) end

        self.ACD:Open(appName, parent)

        C_Timer.After(0, function()
            if lastGroups and #lastGroups > 0 then
                if UCB.ACD and UCB.ACD.SelectGroup then
                    UCB.ACD:SelectGroup(appName, unpack(lastGroups))
                end
            else
                if UCB.ACD and UCB.ACD.SelectGroup then
                    UCB.ACD:SelectGroup(appName, "general")
                end
            end
        end)
    end

    -- If not visible, we’re done: it will be fresh next time the user clicks that tab.
end

function UCB:QueueFullRebuildOptionsUI(unit)
    unit = unit or "player"
    self._rebuildQueued = self._rebuildQueued or {}
    if self._rebuildQueued[unit] then return end
    self._rebuildQueued[unit] = true

    C_Timer.After(0, function()
        self._rebuildQueued[unit] = nil
        self:FullRebuildOptionsUI(unit)
    end)
end


function UCB:OnProfileSwapRefreshUI()
    -- Always invalidate all unit option tables so they will rebuild from the new DB
    self:InvalidateUnitOptions("player")
    self:InvalidateUnitOptions("target")
    self:InvalidateUnitOptions("focus")

    -- If GUI is open and a unit tab is currently visible, rebuild that one immediately
    local selected = self.GUI and self.GUI.selectedTab
    if selected == "player" or selected == "target" or selected == "focus" then
        self:QueueFullRebuildOptionsUI(selected)
    end

    -- If you also have standalone windows open for any unit appName,
    -- you can optionally force NotifyChange for each app:
    -- self:NotifyChange("player"); self:NotifyChange("target"); self:NotifyChange("focus")
end

--]]


local ROOT_APP = "UCB_ROOT"

-- ============================================================================
--  Root invalidation / rebuild helpers
-- ============================================================================

function UCB:InvalidateRootOptions()
    -- allow RegisterRootOptions() to rebuild + re-register
    self._rootOptionsRegistered = nil
    self.optionsTable = nil

    -- if you cache built args anywhere, clear them too (safe even if nil)
    if self.Options then
        self.Options._textTreeArgs  = self.Options._textTreeArgs  or {}
        self.Options._classTreeArgs = self.Options._classTreeArgs or {}
        wipe(self.Options._textTreeArgs)
        wipe(self.Options._classTreeArgs)
    end
end

function UCB:BuildRootOptionsTable()
    -- stable tables (important!)
    self._rootOptions = self._rootOptions or {}
    self._rootArgs    = self._rootArgs    or {}

    -- Build / rebuild sub-args (MUST return tables)
    local playerArgs = self:BuildUnitOptionsArgs("player") or {}
    --local targetArgs = self:BuildUnitOptionsArgs("target") or {}
    --local focusArgs  = self:BuildUnitOptionsArgs("focus")  or {}
    local targetArgs = {}
    local focusArgs  = {}

    -- Profiles group: BuildProfilesOptions() returns a group table; we want its args table
    local profArgs  = self:BuildProfilesOptions() or {}

    wipe(self._rootArgs)

    self._rootArgs.player = {
        type  = "group",
        name  = "Player",
        order = 1,
        args  = playerArgs,
    }

    self._rootArgs.target = {
        type  = "group",
        name  = "Target",
        order = 2,
        args  = targetArgs,
    }

    self._rootArgs.focus = {
        type  = "group",
        name  = "Focus",
        order = 3,
        args  = focusArgs,
    }

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
function UCB:RegisterRootOptions(force)
    if self._rootOptionsRegistered and not force then return end
    self._rootOptionsRegistered = true

    self.optionsTable = self:BuildRootOptionsTable()

    self.AC:RegisterOptionsTable(ROOT_APP, self.optionsTable)

    -- Add to Blizzard Options only once
    if not self.optionsPanel then
        self.optionsPanel, self.optionsCategoryID = self.ACD:AddToBlizOptions(ROOT_APP, "Ultimate Castbars")
    end
end

function UCB:FullRebuildRootUI()
    -- preserve current selection path in ROOT if open somewhere
    local lastGroups
    if self.ACD and self.ACD.GetStatus then
        local st = self.ACD:GetStatus(ROOT_APP)
        lastGroups = st and st.groups -- example: {"player","text","someNode"}
    end

    -- close existing ROOT instance (standalone or embedded)
    if self.ACD and self.ACD.Close then
        self.ACD:Close(ROOT_APP)
    end

    -- fully rebuild + re-register the ROOT options table (fresh closures/args)
    self:InvalidateRootOptions()
    self:RegisterRootOptions(true)

    -- reopen into the SAME holder if your custom GUI is open
    local parent = self.GUI and self.GUI._rootHolder
    if parent then
        parent:ReleaseChildren()
        if parent.SetLayout then parent:SetLayout("Fill") end
        if parent.SetFullWidth then parent:SetFullWidth(true) end
        if parent.SetFullHeight then parent:SetFullHeight(true) end

        self.ACD:Open(ROOT_APP, parent)
    end

    -- notify + restore selection (next frame)
    C_Timer.After(0, function()
        if self.ACR then
            self.ACR:NotifyChange(ROOT_APP)
        end

        if self.ACD and self.ACD.SelectGroup then
            if lastGroups and #lastGroups > 0 then
                self.ACD:SelectGroup(ROOT_APP, unpack(lastGroups))
            else
                self.ACD:SelectGroup(ROOT_APP, "player", "general")
            end
        end
    end)
end

function UCB:QueueFullRebuildRootUI()
    self._rebuildQueued = self._rebuildQueued or {}
    if self._rebuildQueued[ROOT_APP] then return end
    self._rebuildQueued[ROOT_APP] = true

    C_Timer.After(0, function()
        self._rebuildQueued[ROOT_APP] = nil
        self:FullRebuildRootUI()
    end)
end

function UCB:OnProfileSwapRefreshUI()
    -- If GUI is open, do a full rebuild so all closures/args rebind to the new DB
    if self.GUI and self.GUI._rootHolder then
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

function UCB:CloseGUI()
    if not self.GUI or not self.GUI.isGUIOpen then return end

    if self.ACD and self.ACD.Close then
        self.ACD:Close(ROOT_APP)
    end

    if Container then
        if GUIWidgets and GUIWidgets.DetachBottomLeftLinks then
            GUIWidgets:DetachBottomLeftLinks(Container)
        end
        AG:Release(Container)
        Container = nil
    end

    self.GUI._rootHolder = nil
    self.GUI.isGUIOpen = false
    self.GUI._currentSelectedTab = nil
end

function UCB:OpenGUI(selectPath)
    self:RegisterRootOptions()
    self.GUI = self.GUI or {}

    if InCombatLockdown and InCombatLockdown() then return end

    local path = selectPath or {"player","general"}
    local wantedKey = PathKey(path)

    -- if already open: toggle or switch
    if self.GUI.isGUIOpen and Container then
        if self.GUI._currentSelectedKey == wantedKey then
        self:CloseGUI()
        return
        end

        if self.ACD and self.ACD.SelectGroup then
        self.ACD:SelectGroup(ROOT_APP, unpack(path))
        print("Done")
        self.GUI._currentSelectedKey = wantedKey
        end
        return
    end

    -- Otherwise: open fresh
    self.GUI.isGUIOpen = true
    self.GUI._currentSelectedTab = nil

    Container = AG:Create("Frame")
    Container:SetTitle(UCB.PRETTY_ADDON_NAME or "Ultimate Castbars")
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
        -- close the ACD app too (matches CloseGUI)
        if self.ACD and self.ACD.Close then
            self.ACD:Close(ROOT_APP)
        end

        if GUIWidgets and GUIWidgets.DetachBottomLeftLinks then
            GUIWidgets:DetachBottomLeftLinks(widget)
        end

        AG:Release(widget)
        Container = nil

        self.GUI._rootHolder = nil
        self.GUI.isGUIOpen = false
        self.GUI._currentSelectedTab = nil
    end)

    local holder = AG:Create("SimpleGroup")
    holder:SetFullWidth(true)
    holder:SetFullHeight(true)
    holder:SetLayout("Fill")
    Container:AddChild(holder)

    self.GUI._rootHolder = holder

    -- make sure old instance is closed before opening into holder
    if self.ACD and self.ACD.Close then
        self.ACD:Close(ROOT_APP)
    end
    self.ACD:Open(ROOT_APP, holder)

    self:NotifyChange()

    C_Timer.After(0, function()
        if self.ACD and self.ACD.SelectGroup and self.GUI and self.GUI.isGUIOpen then
            self.ACD:SelectGroup(ROOT_APP, unpack(path))
            self.GUI._currentSelectedKey = wantedKey
        end
    end)
end



-- Optional convenience alias (matches some addons' naming)
UCB.CreateGUI = UCB.OpenGUI
