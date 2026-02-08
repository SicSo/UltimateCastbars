local _, UCB = ...

local AG = UCB and UCB.AG
if not (UCB and AG) then return end

UCB.GUIWidgets = UCB.GUIWidgets or {}
local GUIWidgets = UCB.GUIWidgets


-- ===== Clickable header links + popup =====

-- ===== Bottom-left links + copy popup (AceGUI) =====

GUIWidgets._linkPopup = GUIWidgets._linkPopup or nil

function GUIWidgets:OpenLinkPopup(title, url)
    if self._linkPopup then
        AG:Release(self._linkPopup)
        self._linkPopup = nil
    end

    local f = AG:Create("Frame")
    f:SetTitle(title or "Link")
    f:SetLayout("Flow")
    f:SetWidth(520)
    f:SetHeight(140)
    f:EnableResize(false)
    f:SetCallback("OnClose", function(widget)
        AG:Release(widget)
        self._linkPopup = nil
    end)

    local info = AG:Create("Label")
    info:SetFullWidth(true)
    info:SetText("Copy the link below:")
    f:AddChild(info)

    local eb = AG:Create("EditBox")
    eb:SetFullWidth(true)
    eb:SetLabel("Link")
    eb:SetText(url or "")
    f:AddChild(eb)

    -- highlight for quick Ctrl+C
    if eb.editbox and eb.editbox.HighlightText then
        eb.editbox:HighlightText()
        eb.editbox:SetFocus()
    end

    self._linkPopup = f
end

local function MakeClickableText(parentFrame, text, onClick, iconPath, fontSize, iconSize)
    fontSize = fontSize or 12
    iconSize = iconSize or 14

    local padL = 2     -- left padding inside button
    local padR = 2     -- right padding inside button
    local gap  = 4     -- gap between text and icon

    local b = CreateFrame("Button", nil, parentFrame)
    b:EnableMouse(true)
    b:RegisterForClicks("AnyUp")
    b:SetFrameStrata(parentFrame:GetFrameStrata() or "DIALOG")
    b:SetFrameLevel((parentFrame:GetFrameLevel() or 0) + 50)

    -- Text
    local fs = b:CreateFontString(nil, "OVERLAY")
    fs:SetFont("Interface\\AddOns\\UltimateCastbars\\gfx\\Fonts\\Expressway.ttf", fontSize, "OUTLINE")
    fs:SetText(text)
    fs:SetTextColor(0.25, 0.55, 1.0)
    fs:ClearAllPoints()
    fs:SetPoint("LEFT", b, "LEFT", padL, 0)

    local textW = fs:GetStringWidth()
    local textH = fs:GetStringHeight()

    local icon, iconW = nil, 0
    if iconPath then
        iconW = iconSize

        icon = b:CreateTexture(nil, "OVERLAY")
        icon:SetSize(iconSize, iconSize)
        icon:SetTexture(iconPath)

        -- Anchor icon to the RIGHT inside the button (not outside)
        icon:ClearAllPoints()
        icon:SetPoint("RIGHT", b, "RIGHT", -padR, 0)
    end

    -- Button size must include text + gap + icon + padding
    local w = padL + textW + (icon and (gap + iconW) or 0) + padR
    local h = math.max(textH, iconSize) + 6
    b:SetSize(w, h)
    b:SetHitRectInsets(-2, -2, -2, -2)

    -- If you want the icon immediately after the text (instead of far-right),
    -- swap the icon anchor to:
    -- icon:SetPoint("LEFT", fs, "RIGHT", gap, 0)

    b:SetScript("OnEnter", function() fs:SetTextColor(0.45, 0.75, 1.0) end)
    b:SetScript("OnLeave", function() fs:SetTextColor(0.25, 0.55, 1.0) end)
    b:SetScript("OnClick", function()
        if type(onClick) == "function" then onClick() end
    end)

    b:Show()
    return b, fs, icon
end



function GUIWidgets:AttachBottomLeftLinks(aceGuiFrame, links)
    if not aceGuiFrame.__ucbHookedRelease then
    aceGuiFrame.__ucbHookedRelease = true
    local old = aceGuiFrame.OnRelease
    aceGuiFrame.OnRelease = function(widget)
        if GUIWidgets and GUIWidgets.DetachBottomLeftLinks then
            GUIWidgets:DetachBottomLeftLinks(widget)
        end
        if old then old(widget) end
        end
    end

    if not (aceGuiFrame and aceGuiFrame.frame) then return end
    local parent = aceGuiFrame.frame

    -- cleanup if called again
    if parent.__ucbBottomLinks then
        for _, o in ipairs(parent.__ucbBottomLinks) do
            if o and o.Hide then o:Hide() end
        end
    end
    parent.__ucbBottomLinks = {}

    local link1 = MakeClickableText(parent, links[1].text, function()
        GUIWidgets:OpenLinkPopup(links[1].title, links[1].url)
    end, "Interface\\AddOns\\UltimateCastbars\\gfx\\Icons\\discord.png", 12, 20)
    table.insert(parent.__ucbBottomLinks, link1)

    local sep = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sep:SetText(" | ")
    table.insert(parent.__ucbBottomLinks, sep)

    local link2 = MakeClickableText(parent, links[2].text, function()
        GUIWidgets:OpenLinkPopup(links[2].title, links[2].url)
    end, "Interface\\AddOns\\UltimateCastbars\\gfx\\Icons\\Ko-fi_HEART.png", 12, 25)
    table.insert(parent.__ucbBottomLinks, link2)

    -- Anchor bottom-left, slightly above the edge
    link1:ClearAllPoints()
    link1:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 12, 10)

    sep:ClearAllPoints()
    sep:SetPoint("LEFT", link1, "RIGHT", 0, 0)

    link2:ClearAllPoints()
    link2:SetPoint("LEFT", sep, "RIGHT", 0, 0)
end

function GUIWidgets:DetachBottomLeftLinks(aceGuiFrame)
    if not aceGuiFrame then return end
    local parent = aceGuiFrame.frame
    if not parent then return end

    local t = parent.__ucbBottomLinks
    if not t then return end

    for _, obj in ipairs(t) do
        if obj then
            -- Only Frames have scripts
            if obj.GetObjectType and obj:GetObjectType() == "Frame" then
                if obj.SetScript then
                    obj:SetScript("OnUpdate", nil)
                    obj:SetScript("OnClick", nil)
                    obj:SetScript("OnEnter", nil)
                    obj:SetScript("OnLeave", nil)
                end
            end

            if obj.Hide then obj:Hide() end
            -- Some objects support SetParent, some don't (FontString usually does, but be safe)
            if obj.SetParent then obj:SetParent(nil) end
        end
    end

    parent.__ucbBottomLinks = nil
end



local function DeepDisable(widget, disabled, skipWidget)
    if widget == skipWidget then return end
    if widget.SetDisabled then widget:SetDisabled(disabled) end
    if widget.children then
        for _, child in ipairs(widget.children) do
            DeepDisable(child, disabled, skipWidget)
        end
    end
end
GUIWidgets.DeepDisable = DeepDisable

local function CreateInformationTag(containerParent, labelDescription, textJustification)
    local informationLabel = AG:Create("Label")
    informationLabel:SetText((UCB.INFOBUTTON or "") .. (labelDescription or ""))
    informationLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    informationLabel:SetFullWidth(true)
    informationLabel:SetJustifyH(textJustification or "CENTER")
    informationLabel:SetHeight(24)
    informationLabel:SetJustifyV("MIDDLE")
    containerParent:AddChild(informationLabel)
    return informationLabel
end
GUIWidgets.CreateInformationTag = CreateInformationTag

local function CreateScrollFrame(containerParent)
    local scrollFrame = AG:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    containerParent:AddChild(scrollFrame)
    return scrollFrame
end
GUIWidgets.CreateScrollFrame = CreateScrollFrame

local function CreateInlineGroup(containerParent, containerTitle)
    local inlineGroup = AG:Create("InlineGroup")
    inlineGroup:SetTitle("|cFFFFFFFF" .. (containerTitle or "") .. "|r")
    inlineGroup:SetFullWidth(true)
    inlineGroup:SetLayout("Flow")
    containerParent:AddChild(inlineGroup)
    return inlineGroup
end
GUIWidgets.CreateInlineGroup = CreateInlineGroup

local function CreateHeader(containerParent, headerTitle)
    local headingText = AG:Create("Heading")
    headingText:SetText("|cFFFFCC00" .. (headerTitle or "") .. "|r")
    headingText:SetFullWidth(true)
    containerParent:AddChild(headingText)
    return headingText
end
GUIWidgets.CreateHeader = CreateHeader
