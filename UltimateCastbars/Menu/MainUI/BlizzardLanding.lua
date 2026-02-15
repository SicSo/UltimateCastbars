local ADDON_NAME, UCB = ...

UCB.UI = UCB.UI or {}
local UI = UCB.UI

-- ---------- Helpers ----------
local function OpenLinkPopup(title, url)
    if not url or url == "" then return end

    local f = UltimateCastbars_LinkPopup
    if not f then
        f = CreateFrame("Frame", "UltimateCastbars_LinkPopup", UIParent, "BackdropTemplate")
        f:SetSize(520, 140)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })

        f.title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        f.title:SetPoint("TOP", 0, -16)

        f.edit = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        f.edit:SetSize(460, 30)
        f.edit:SetPoint("TOP", f.title, "BOTTOM", 0, -18)
        f.edit:SetAutoFocus(true)
        f.edit:SetScript("OnEscapePressed", function() f:Hide() end)
        f.edit:SetScript("OnEnterPressed", function() f:Hide() end)

        f.hint = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        f.hint:SetPoint("TOP", f.edit, "BOTTOM", 0, -10)
        f.hint:SetText("Press Ctrl+C to copy. WoW cannot open links directly.")

        f.close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.close:SetSize(120, 26)
        f.close:SetPoint("BOTTOM", 0, 14)
        f.close:SetText("Close")
        f.close:SetScript("OnClick", function() f:Hide() end)
    end

    f.title:SetText(title or "Link")
    f.edit:SetText(url)
    f:Show()

    C_Timer.After(0, function()
        f.edit:SetFocus()
        f.edit:HighlightText()
    end)
end

local function CreateOpenOptionsButton(parentFrame, onClick)
    local template = "SharedButtonLargeTemplate"
    if not (C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo(template)) then
        template = "UIPanelButtonTemplate"
    end

    local btn = CreateFrame("Button", nil, parentFrame, template)
    btn:SetSize(520, 70)                 -- fixed size so it fills your rectangle
    btn:SetPoint("CENTER", parentFrame, 0, -30)
    btn:SetText("Open Options")

    -- Make sure the built-in textures fill the whole button (prevents “not covering” look)
    local n, p, h = btn:GetNormalTexture(), btn:GetPushedTexture(), btn:GetHighlightTexture()
    if n then n:SetAllPoints(btn) end
    if p then p:SetAllPoints(btn) end
    if h then h:SetAllPoints(btn) h:SetBlendMode("ADD") end

    -- Make the label bigger
    local fs = btn:GetFontString()
    if fs then
        fs:SetTextColor(1.0, 0.85, 0.05, 1)
        local f, s, flags = fs:GetFont()
        if f and s then
            fs:SetFont(f, s * 1.8, flags)
        end
    end

    btn:SetScript("OnClick", onClick)
    return btn
end


local function CreateLinkButton(parentFrame, labelText, url, iconPath)
    local template = "SharedButtonSmallTemplate"
    if not (C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo(template)) then
        template = "UIPanelButtonTemplate"
    end

    local btn = CreateFrame("Button", nil, parentFrame, template)
    btn:SetSize(160, 34)
    btn:SetText("") -- we will create our own centered label

    -- Force template textures to fill rect
    local n, p, h = btn:GetNormalTexture(), btn:GetPushedTexture(), btn:GetHighlightTexture()
    if n then n:SetAllPoints(btn) end
    if p then p:SetAllPoints(btn) end
    if h then h:SetAllPoints(btn) h:SetBlendMode("ADD") end

    -- Center group (icon + text)
    local group = CreateFrame("Frame", nil, btn)
    group:SetPoint("CENTER", btn, "CENTER", 0, 0)
    group:SetSize(1, 1)

    local spacing = 8
    local iconSize = 18

    local icon
    if iconPath then
        icon = group:CreateTexture(nil, "ARTWORK")
        icon:SetSize(iconSize, iconSize)
        icon:SetTexture(iconPath)
        icon:SetPoint("LEFT", group, "LEFT", 0, 0)
    end

    local label = group:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetText(labelText or "")
    label:SetTextColor(1.0, 0.85, 0.05, 1)

    -- Font sizing
    do
        local f, s, flags = label:GetFont()
        if f and s then
            label:SetFont(f, s * 1.2, flags)
        end
    end

    if icon then
        label:SetPoint("LEFT", icon, "RIGHT", spacing, 0)
    else
        label:SetPoint("LEFT", group, "LEFT", 0, 0)
    end

    -- Size the group to its contents so it truly centers
    -- Note: need a frame update for accurate GetStringWidth sometimes; do it next tick.
    C_Timer.After(0, function()
        if not group or not group:IsShown() then return end

        local labelW = label:GetStringWidth() or 0
        local iconW = icon and iconSize or 0
        local groupW = iconW + (icon and spacing or 0) + labelW

        group:SetWidth(groupW)
        group:SetHeight(math.max(iconSize, label:GetStringHeight() or 0))
    end)

    btn:SetScript("OnClick", function()
        OpenLinkPopup((labelText or "Link") .. " Link", url)
    end)

    return btn
end

local function CloseBlizzardOptions()
    -- Retail Settings
    if SettingsPanel and SettingsPanel:IsShown() then
        HideUIPanel(SettingsPanel)
    end
    -- Classic/old Interface Options
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
        HideUIPanel(InterfaceOptionsFrame)
    end
end

local function OpenYourConfig()
    -- Change this to your real opener if different
    if UCB and UCB.OpenGUI then
        UCB:OpenGUI()
        return
    end

    -- Fallback: try a global function name if you have one
    if _G.UltimateCastbars_OpenGUI then
        _G.UltimateCastbars_OpenGUI()
        return
    end

    print("|cffff4444Ultimate Castbars:|r Could not find OpenGUI() function. Update OpenYourConfig() in BlizzardLanding.lua.")
end



-- ---------- Build Landing Panel ----------
local function BuildLandingPanel()
    local panel = CreateFrame("Frame", "UltimateCastbars_LandingPanel", UIParent)
    panel.name = "Ultimate Castbars" -- shown name in Interface Options (Classic)

    local expressway = "Interface\\AddOns\\UltimateCastbars\\gfx\\Fonts\\Expressway.ttf"

    -- Background dark overlay (similar vibe)
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    bg:SetColorTexture(0, 0, 0, 0.55)

    -- Optional: faint blurred image style using your own texture
    -- If you have a background texture, uncomment and point to it.
    -- local art = panel:CreateTexture(nil, "BACKGROUND", nil, 1)
    -- art:SetAllPoints(panel)
    -- art:SetTexture("Interface\\AddOns\\YourAddon\\Media\\yourbg")
    -- art:SetAlpha(0.25)

        -- Logo (same line as title)
    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(48, 48) -- adjust
    logo:SetTexture(UI.icons.logo)
    logo:SetPoint("CENTER", panel, "CENTER", -220, 110)

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("LEFT", logo, "RIGHT", 14, 0)
    title:SetText(UI.text.name)
    title:SetTextColor(1.0, 0.85, 0.05, 1)
    title:SetFont(expressway, 50, "OUTLINE")


    -- Made by (name highlighted)
    local madeBy = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    madeBy:SetPoint("TOP", title, "BOTTOM", 0, -10)
    madeBy:SetText("Made by |cffffcc33"..UI.text.madeByM.."|r")
    madeBy:SetTextColor(1, 1, 1, 0.95)


    -- Version
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    version:SetPoint("TOP", madeBy, "BOTTOM", 0, -10)
    version:SetText("Version: " .. UI.text.version)
    version:SetTextColor(1, 1, 1, 0.9)

    -- Instruction
    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    hint:SetPoint("TOP", version, "BOTTOM", 0, -16)
    hint:SetText("Commands to open the menu: /ucb ; /pcb ; /tcb ; /fcb")
    hint:SetTextColor(1, 1, 1, 0.9)

    local openBtn = CreateOpenOptionsButton(panel, function()
        CloseBlizzardOptions()
        OpenYourConfig()
    end)
    openBtn:SetPoint("TOP", hint, "BOTTOM", 0, -35)

    -- Link buttons row under Open Options
    local linkRow = CreateFrame("Frame", nil, panel)
    linkRow:SetSize(520, 40)
    linkRow:SetPoint("TOP", openBtn, "BOTTOM", 0, -18)

    local b1 = CreateLinkButton(linkRow, "GitHub",  UI.links.github,  UI.icons.github)
    b1:SetPoint("LEFT", linkRow, "LEFT", 0, 0)

    local b2 = CreateLinkButton(linkRow, "Discord", UI.links.discord, UI.icons.discord)
    b2:SetPoint("LEFT", b1, "RIGHT", 20, 0)

    local b3 = CreateLinkButton(linkRow, "Donate",  UI.links.donate,  UI.icons.donate)
    b3:SetPoint("LEFT", b2, "RIGHT", 20, 0)


    return panel
end

-- ---------- Register Panel ----------
local function RegisterPanel(panel)
    -- Retail (Dragonflight+) Settings API
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, UI.text.name)
        Settings.RegisterAddOnCategory(category)
        return
    end
end

-- Public init
function UCB.UCB_RegisterLandingPanel()
    local panel = BuildLandingPanel()
    RegisterPanel(panel)
end
