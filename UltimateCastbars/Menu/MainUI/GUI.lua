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




-- Placeholder: called for each unit tab. Populate later.
function UCBGUI:BuildUnitTab(contentFrame, unit)
    contentFrame:ReleaseChildren()

    if unit == "player" then
        -- If PlayersCastbars is available, render its AceConfig into this tab
        if UCB and UCB.OpenOptionsInContainer then
            UCB:OpenOptionsInContainer(contentFrame)
            return
        end

        -- fallback if not loaded
        local label = AG:Create("Label")
        label:SetFullWidth(true)
        label:SetText("PlayersCastbars options not available.")
        contentFrame:AddChild(label)
        return
    end

    -- keep your other tabs as placeholders for now
    local label = AG:Create("Label")
    label:SetFullWidth(true)
    label:SetText("|cFF8080FF" .. (unit:gsub("^%l", string.upper)) .. "|r settings will be added here later.")
    label:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    label:SetJustifyH("LEFT")
    label:SetHeight(24)
    contentFrame:AddChild(label)
end


function SelectMainTab(tabGroup, event, tabValue)
    UCB.GUI.selectedTab = tabValue
    tabGroup:ReleaseChildren()

    local wrapper = AG:Create("SimpleGroup")
    wrapper:SetFullWidth(true)
    wrapper:SetFullHeight(true)
    wrapper:SetLayout("Fill")
    tabGroup:AddChild(wrapper)

    if tabValue == "player" then
        -- IMPORTANT: Don't embed AceConfigDialog inside a ScrollFrame.
        -- AceConfigDialog builds its own scrolling/tree widgets; nesting it in a scroll frame
        -- causes the "tiny strip at the top" issue.
        local holder = AG:Create("SimpleGroup")
        holder:SetFullWidth(true)
        holder:SetFullHeight(true)
        holder:SetLayout("Fill")
        wrapper:AddChild(holder)

        UCBGUI:BuildUnitTab(holder, "player")
        if holder.DoLayout then holder:DoLayout() end
        return
    elseif tabValue == "profiles" then
        local holder = AG:Create("SimpleGroup")
        holder:SetFullWidth(true)
        holder:SetFullHeight(true)
        holder:SetLayout("Fill")
        wrapper:AddChild(holder)

        if UCB and UCB.OpenProfilesInContainer then
            UCB:OpenProfilesInContainer(holder)
        else
            local label = AG:Create("Label")
            label:SetFullWidth(true)
            label:SetText("Profiles options not available.")
            holder:AddChild(label)
        end

        if holder.DoLayout then holder:DoLayout() end
        return
    end

    -- Use a scroll frame so future options can grow (target/focus etc.)
    local scroll
    if GUIWidgets and GUIWidgets.CreateScrollFrame then
        scroll = GUIWidgets.CreateScrollFrame(wrapper)
    else
        scroll = AG:Create("ScrollFrame")
        scroll:SetLayout("Flow")
        scroll:SetFullWidth(true)
        scroll:SetFullHeight(true)
        wrapper:AddChild(scroll)
    end



    if tabValue == "target" then
        UCBGUI:BuildUnitTab(scroll, "target")
    elseif tabValue == "focus" then
        UCBGUI:BuildUnitTab(scroll, "focus")
    end

    if scroll.DoLayout then scroll:DoLayout() end
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

function UCB:RebuildUI(unit)
    unit = unit or "player"
    if not self.optionsTable or not self.optionsTable.args then return end

    -- OPTIONAL: preserve current selection
    local lastGroups
    if self.ACD and self.ACD.GetStatus then
        local st = self.ACD:GetStatus("UCB")
        lastGroups = st and st.groups
    end

    -- 1) Rebuild TEXT cache
    if self.Options and self.Options.BuildGeneralSettingsTextArgs then
        self.Options._textTreeArgs = self.Options._textTreeArgs or {}
        wipe(self.Options._textTreeArgs)
        self.Options.BuildGeneralSettingsTextArgs(unit, { includePerTabEnable = false })
        -- make sure AceConfig node points to cache
        if self.optionsTable.args.text then
            self.optionsTable.args.text.args = self.Options._textTreeArgs
        end
    end

    -- 2) Rebuild CLASS cache
    if self.Options and self.Options.BuildClassSettingsArgs then
        self.Options._classTreeArgs = self.Options._classTreeArgs or {}
        wipe(self.Options._classTreeArgs)
        self.Options.BuildClassSettingsArgs(unit, { includePerTabEnable = false })
        -- make sure AceConfig node points to cache
        if self.optionsTable.args.classSettings then
            self.optionsTable.args.classSettings.args = self.Options._classTreeArgs
        end
    end

    -- 3) Notify AceConfig to redraw
    local ACR = self.ACR or (LibStub and LibStub("AceConfigRegistry-3.0", true))
    if ACR then
        ACR:NotifyChange("UCB")
    end

    -- 4) Rebuild embedded GUI
    if self.RefreshGUI then
        self:RefreshGUI()
    end

    -- 5) Restore selection
    if lastGroups and self.ACD and self.ACD.SelectGroup then
        self.ACD:SelectGroup("UCB", unpack(lastGroups))
    end
end


-- Optional convenience alias (matches some addons' naming)
UCB.CreateGUI = UCB.OpenGUI
