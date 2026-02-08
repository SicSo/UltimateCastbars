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

  -- 1) Rebuild your options structures (fresh closures, current profile)
  if self.Options and self.Options.BuildGeneralSettingsTextArgs then
    if self.Options._textTreeArgs then
      wipe(self.Options._textTreeArgs)
    else
      self.Options._textTreeArgs = {}
    end

    -- Recreate the text tree args from CURRENT profile
    self.Options.BuildGeneralSettingsTextArgs(unit, { includePerTabEnable = false })
  end

  -- 2) Tell AceConfigRegistry that options changed (only matters if you also use ACD somewhere)
  if self.ACR then
    self.ACR:NotifyChange("UCB")
  end

  -- 3) Rebuild your embedded GUI widgets (this is the important part for your addon)
  self:RefreshGUI()
end


-- Optional convenience alias (matches some addons' naming)
UCB.CreateGUI = UCB.OpenGUI
