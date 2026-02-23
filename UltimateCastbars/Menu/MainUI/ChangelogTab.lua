local _, UCB = ...

local AG = UCB and UCB.AG
if not (UCB and AG) then return end

UCB.GUIWidgets = UCB.GUIWidgets or {}
local GUIWidgets = UCB.GUIWidgets


-- =========================================================
-- Changelog Window (collapsible list, BetterFriendlist-ish)
-- =========================================================

GUIWidgets._changelogUI = GUIWidgets._changelogUI or nil

local YELLOW = "|cFFFFD100"
local GREY   = "|cFFB0B0B0"
local WHITE  = "|cFFFFFFFF"
local RESET  = "|r"

local function FormatBody(md)
    if not md or md == "" then return "" end

    local out = {}

    for line in (md .. "\n"):gmatch("(.-)\n") do
        -- section headings
        local h3 = line:match("^###%s+(.+)")
        if h3 then
            out[#out + 1] = ""
            out[#out + 1] = YELLOW .. h3 .. RESET
        else
            -- bullets
            line = line:gsub("^%s*[-*]%s+", "    • ")
            out[#out + 1] = line
        end
    end

    -- trim leading blank lines
    while out[1] == "" do table.remove(out, 1) end
    return table.concat(out, "\n")
end

local function ParseChangelog(md)
    local entries = {}
    local cur

    local function push()
        if not cur then return end
        cur.body = FormatBody(table.concat(cur._lines, "\n"))
        cur._lines = nil
        entries[#entries + 1] = cur
    end

    for line in (md or ""):gmatch("[^\r\n]+") do
        -- Supports:
        -- ## Version 1.2.3 - 2026-02-21
        -- ## 1.2.3 - 2026-02-21
        -- ## Version 1.2.3 (2026-02-21)
        local ver, date =
            line:match("^##+%s*[Vv]ersion%s*([%w%._%-]+)%s*%-%s*(%d%d%d%d%-%d%d%-%d%d)") or
            line:match("^##+%s*([%w%._%-]+)%s*%-%s*(%d%d%d%d%-%d%d%-%d%d)") or
            line:match("^##+%s*[Vv]ersion%s*([%w%._%-]+)%s*%((%d%d%d%d%-%d%d%-%d%d)%)")

        if ver then
            push()
            cur = { version = ver, date = date or "", _lines = {} }
        elseif cur then
            cur._lines[#cur._lines + 1] = line
        end
    end

    push()
    return entries
end

local function EnsureChangelogUI(self)
    if self._changelogUI and self._changelogUI.frame then
        return self._changelogUI
    end

    local f = CreateFrame("Frame", "UCB_ChangelogFrame", UIParent, "BackdropTemplate")
    f:SetToplevel(true)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(500)
    f:SetClampedToScreen(true)
    f:SetSize(600, 500)
    f:SetPoint("CENTER")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.80)
    f:SetBackdropBorderColor(0.10, 0.10, 0.10, 0.90)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText(YELLOW .. "UltimateCastbars Changelog" .. RESET)
    f.title = title

    -- Close button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

    -- Separator line under title (no support bar)
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -40)
    sep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -40)
    sep:SetColorTexture(1, 1, 1, 0.15)

    -- ScrollFrame
    local sf = CreateFrame("ScrollFrame", "UCB_ChangelogScroll", f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -50)
    sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -34, 14)

    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(1, 1)
    sf:SetScrollChild(content)

    -- Make scrollbar less “blizzard bright”
    local sb = _G[sf:GetName() .. "ScrollBar"]
    if sb then
        sb:SetAlpha(0.8)
    end

    self._changelogUI = {
        frame = f,
        scroll = sf,
        content = content,
        items = {},
        entries = {},
    }

    -- Relayout on resize so wrapping stays correct
    f:SetScript("OnSizeChanged", function()
        if self._changelogUI then
            self:RefreshChangelogLayout()
        end
    end)

    return self._changelogUI
end

function GUIWidgets:RefreshChangelogLayout()
    local ui = self._changelogUI
    if not ui or not ui.frame or not ui.frame:IsShown() then return end

    local content = ui.content
    local scroll = ui.scroll

    local contentWidth = scroll:GetWidth() - 8
    if contentWidth < 200 then contentWidth = 200 end
    content:SetWidth(contentWidth)

    local y = -6
    local leftPad = 10
    local rightPad = 12
    local datePad = 24
    local gap = 8

    for i, it in ipairs(ui.items) do
        if it.inUse then
            it.header:ClearAllPoints()
            it.header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
            it.header:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
            it.header:SetHeight(30)

            it.arrow:SetPoint("LEFT", it.header, "LEFT", leftPad, 0)
            it.versionFS:SetPoint("LEFT", it.arrow, "RIGHT", 10, 0)
            it.dateFS:SetPoint("RIGHT", it.header, "RIGHT", -rightPad, 0)

            y = y - 30 - 2

            if it.expanded then
                it.body:ClearAllPoints()
                it.body:SetPoint("TOPLEFT", it.header, "BOTTOMLEFT", leftPad + 26, -4)
                it.body:SetWidth(contentWidth - (leftPad + 26) - datePad)
                it.body:Show()

                local h = it.body:GetStringHeight()
                it.body:SetHeight(h)

                y = y - h - gap
            else
                it.body:Hide()
            end
        else
            it.header:Hide()
            it.body:Hide()
        end
    end

    content:SetHeight(-y + 10)
end

function GUIWidgets:OpenChangelogWindow(windowTitle, mdText)
    local ui = EnsureChangelogUI(self)

    ui.frame.title:SetText(YELLOW .. (windowTitle or "Changelog") .. RESET)

    local entries = ParseChangelog(mdText or "")
    ui.entries = entries

    -- Ensure enough reusable item widgets
    for i = 1, #entries do
        if not ui.items[i] then
            local header = CreateFrame("Button", nil, ui.content)
            header:EnableMouse(true)

            local arrow = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            arrow:SetTextColor(1, 0.82, 0, 1)

            local versionFS = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            versionFS:SetTextColor(1, 0.82, 0, 1)

            local dateFS = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            dateFS:SetTextColor(1, 0.82, 0, 1)

            local body = ui.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            body:SetJustifyH("LEFT")
            body:SetJustifyV("TOP")
            body:SetTextColor(1, 1, 1, 0.95)

            ui.items[i] = {
                header = header,
                arrow = arrow,
                versionFS = versionFS,
                dateFS = dateFS,
                body = body,
                expanded = false,
                inUse = false,
            }
        end
    end

    -- Populate items
    for i, it in ipairs(ui.items) do
        local e = entries[i]
        if e then
            it.inUse = true
            it.header:Show()

            -- Default: first entry expanded, like your screenshot
            it.expanded = (i == 1)

            it.arrow:SetText(it.expanded and "v" or ">")
            it.versionFS:SetText("Version " .. (e.version or ""))
            it.dateFS:SetText(e.date or "")

            it.body:SetText(e.body or "")

            it.header:SetScript("OnEnter", function()
                it.versionFS:SetTextColor(1, 0.90, 0.25, 1)
                it.dateFS:SetTextColor(1, 0.90, 0.25, 1)
            end)
            it.header:SetScript("OnLeave", function()
                it.versionFS:SetTextColor(1, 0.82, 0, 1)
                it.dateFS:SetTextColor(1, 0.82, 0, 1)
            end)
            it.header:SetScript("OnClick", function()
                it.expanded = not it.expanded
                it.arrow:SetText(it.expanded and "v" or ">")
                self:RefreshChangelogLayout()
            end)
        else
            it.inUse = false
        end
    end

    ui.frame:Show()
    ui.frame:Raise()
    ui.scroll:SetVerticalScroll(0)
    self:RefreshChangelogLayout()
end

function GUIWidgets:CreateTopBarButton(parent, opts)
    -- opts: { text="", icon="path", onClick=function() end, width=190, height=24, iconSize=16, scale=1.3 }
    local scale   = opts.scale or 1.3
    local height  = (opts.height or 22) * scale
    local width   = (opts.width or 180) * scale
    local iconSz  = (opts.iconSize or 14) * scale
    local gap     = 6 * scale

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetFrameStrata(parent:GetFrameStrata() or "DIALOG")
    btn:SetFrameLevel((parent:GetFrameLevel() or 0) + 200)

    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    btn:SetBackdropColor(0.10, 0.10, 0.10, 0.50)
    btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.80)

    -- Center container (everything is centered as a group)
    local content = CreateFrame("Frame", nil, btn)
    content:SetPoint("CENTER", btn, "CENTER", 0, 0)
    content:SetHeight(height)
    btn.content = content

    -- Icon (LEFT)
    local icon = content:CreateTexture(nil, "ARTWORK")
    icon:SetSize(iconSz, iconSz)
    if opts.icon then icon:SetTexture(opts.icon) end
    btn.icon = icon

    -- Main text
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetJustifyH("LEFT")
    text:SetText(opts.text or "")
    btn.text = text

    -- "(New)" (RIGHT, only shown when needed)
    local newFS = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    newFS:SetText("|cFFFFD100(New)|r")
    newFS:Hide()
    btn.newFS = newFS

    -- Scale fonts a bit (like your footer buttons)
    do
        local f, _, flags = text:GetFont()
        if f then text:SetFont(f, (select(2, text:GetFont()) or 12) * scale, flags) end
        local nf, _, nflags = newFS:GetFont()
        if nf then newFS:SetFont(nf, (select(2, newFS:GetFont()) or 11) * scale, nflags) end
    end

    local function Layout()
        -- Calculate widths so we can center the whole group
        local iconW = (opts.icon and iconSz) or 0
        local textW = text:GetStringWidth() or 0
        local newW  = (newFS:IsShown() and (newFS:GetStringWidth() or 0)) or 0

        local total = 0
        if iconW > 0 then total = total + iconW end
        if iconW > 0 and textW > 0 then total = total + gap end
        total = total + textW
        if newW > 0 then total = total + gap + newW end

        content:SetWidth(total)

        -- Anchor the trio inside content: [icon] [text] [(New)]
        local x = 0
        if iconW > 0 then
            icon:ClearAllPoints()
            icon:SetPoint("LEFT", content, "LEFT", 0, 0)
            x = iconW + gap
        end

        text:ClearAllPoints()
        text:SetPoint("LEFT", content, "LEFT", x, 0)

        if newW > 0 then
            newFS:ClearAllPoints()
            newFS:SetPoint("LEFT", text, "RIGHT", gap, 0)
        end
    end

    -- Public helpers
    function btn:SetMainText(t)
        text:SetText(t or "")
        Layout()
    end
    function btn:SetShowNew(show)
        newFS:SetShown(show and true or false)
        Layout()
    end

    -- Hover/press behavior (same as footer)
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

    btn:SetScript("OnClick", function(self)
    if opts.onClick then opts.onClick(self) end
    end)

    -- initial layout
    Layout()

    return btn
end