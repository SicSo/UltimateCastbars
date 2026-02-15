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





-- =========================================================
-- Footer Bar (Option 2) - GitHub / Discord / Donate
-- =========================================================

-- Small helper to safely get the real frame from an AceGUI widget
local function GetWidgetFrame(widget)
    if not widget then return nil end
    return widget.frame or widget
end

-- Simple “button-like” clickable in the footer
function GUIWidgets:CreateFooterButton(parent, opts)
    -- opts: { text="GitHub", icon="path", onClick=function() end, width=165 }
    local scale = 1.3

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetHeight(22 * scale)
    btn:SetWidth((opts.width or 110) * scale)

    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    btn:SetBackdropColor(0.10, 0.10, 0.10, 0.50)
    btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.80)

    -- Icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(14 * scale, 14 * scale)
    icon:SetPoint("LEFT", 6 * scale, 0)
    if opts.icon then icon:SetTexture(opts.icon) end
    btn.icon = icon

    -- Text
    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", icon, "RIGHT", 6 * scale, 0)
    text:SetText(opts.text or "")
    btn.text = text

    -- Scale the font a bit
    local f, _, flags = text:GetFont()
    if f then
        text:SetFont(f, (select(2, text:GetFont()) or 12) * scale, flags)
    end

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.18, 0.18, 0.18, 0.75)
        self:SetBackdropBorderColor(0.90, 0.75, 0.10, 0.90)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.10, 0.10, 0.50)
        self:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.80)
    end)
    btn:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.22, 0.22, 0.22, 0.90)
    end)
    btn:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.18, 0.18, 0.18, 0.75)
    end)

    btn:SetScript("OnClick", function()
        if opts.onClick then opts.onClick() end
    end)

    return btn
end


-- Footer bar attach
function GUIWidgets:AttachFooterBar(aceGuiContainer, footerData)
    local parent = GetWidgetFrame(aceGuiContainer)
    if not parent then return end

    -- If already attached, detach first
    if parent.__ucbFooterBar then
        self:DetachFooterBar(aceGuiContainer)
    end

    -- 50% bigger
    local scale = 1.3

    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetHeight(34 * scale)
    bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 8 * scale, 8 * scale)
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8 * scale, 8 * scale)

    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    bar:SetBackdropColor(0.05, 0.05, 0.05, 0.55)
    bar:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.80)

    -- Left brand block (logo + title + "Made by <Name>")
    local logo = bar:CreateTexture(nil, "ARTWORK")
    logo:SetSize(20 * scale, 20 * scale)
    logo:SetPoint("LEFT", bar, "LEFT", 5 * scale, 0)
    if footerData and footerData.logo then
        logo:SetTexture(footerData.logo)
    end
    bar.logo = logo

    local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", logo, "RIGHT", 3 * scale, 0)
    title:SetText((footerData and footerData.title) or "Addon")
    bar.title = title

    -- Scale title font up
    do
        local fontPath, fontSize, fontFlags = title:GetFont()
        if fontPath and fontSize then
            title:SetFont(fontPath, fontSize * scale, fontFlags)
        end
    end

    -- Inline "Made by " (normal) + Name (highlighted)
    local madeByPrefix = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    madeByPrefix:SetPoint("LEFT", title, "RIGHT", 8 * scale, 0)
    madeByPrefix:SetText("Made by ")
    madeByPrefix:SetTextColor(0.85, 0.85, 0.85, 0.90)

    local madeByName = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    madeByName:SetPoint("LEFT", madeByPrefix, "RIGHT", 0, 0)
    madeByName:SetText((footerData and footerData.madeByName) or "YourName")
    -- Gold/yellow highlight (matches your UI vibe)
    madeByName:SetTextColor(0.90, 0.75, 0.10, 0.95)

    -- Scale made-by fonts up
    do
        local fp, fs, ff = madeByPrefix:GetFont()
        if fp and fs then
            madeByPrefix:SetFont(fp, fs * scale, ff)
        end
        local np, ns, nf = madeByName:GetFont()
        if np and ns then
            madeByName:SetFont(np, ns * scale, nf)
        end
    end

    bar.madeByPrefix = madeByPrefix
    bar.madeByName = madeByName

    -- Center button row container
    local center = CreateFrame("Frame", nil, bar)
    center:SetHeight(22 * scale)
    center:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bar.center = center

    -- Build buttons
    local buttons = {}
    local links = (footerData and footerData.links) or {}
    local totalWidth = 0
    local gap = 8 * scale

    for i, link in ipairs(links) do
        local btn = self:CreateFooterButton(center, {
            text = link.text,
            icon = link.icon,
            width = link.width or 110,
            onClick = function()
                if self.OpenLinkPopup then
                    self:OpenLinkPopup(link.title or link.text or "Link", link.url or "")
                else
                    print((link.title or link.text or "Link") .. ": " .. (link.url or ""))
                end
            end
        })

        if i == 1 then
            btn:SetPoint("LEFT", center, "LEFT", 0, 0)
        else
            btn:SetPoint("LEFT", buttons[i - 1], "RIGHT", gap, 0)
        end

        buttons[i] = btn
        totalWidth = totalWidth + btn:GetWidth()
        if i > 1 then totalWidth = totalWidth + gap end
    end

    center:SetWidth(totalWidth)

    parent.__ucbFooterBar = {
        bar = bar,
        center = center,
        buttons = buttons,
        _oldOnSizeChanged = parent:GetScript("OnSizeChanged"),
    }
    local footerH = 34 * scale + (8 * scale)
    if aceGuiContainer and aceGuiContainer.content then
        aceGuiContainer.content:ClearAllPoints()
        aceGuiContainer.content:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        aceGuiContainer.content:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, footerH)
    end


    -- Keep center aligned if parent resizes (safe chaining)
    parent:SetScript("OnSizeChanged", function(frame, ...)
        if parent.__ucbFooterBar and parent.__ucbFooterBar.center then
            parent.__ucbFooterBar.center:ClearAllPoints()
            parent.__ucbFooterBar.center:SetPoint("CENTER", parent.__ucbFooterBar.bar, "CENTER", 0, 0)
        end
        local old = parent.__ucbFooterBar and parent.__ucbFooterBar._oldOnSizeChanged
        if old then old(frame, ...) end
    end)
end


function GUIWidgets:DetachFooterBar(aceGuiContainer)
    local parent = GetWidgetFrame(aceGuiContainer)
    if not parent or not parent.__ucbFooterBar then return end

    local data = parent.__ucbFooterBar

    -- Restore old OnSizeChanged if we overwrote it
    if data._oldOnSizeChanged then
        parent:SetScript("OnSizeChanged", data._oldOnSizeChanged)
    else
        parent:SetScript("OnSizeChanged", nil)
    end

    if data.bar then
        data.bar:Hide()
        data.bar:SetParent(nil)
    end

    parent.__ucbFooterBar = nil
end

