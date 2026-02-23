local _, UCB = ...

UCB_DB = UCB_DB or {}

local AG = UCB and UCB.AG
if not (UCB and AG) then return end

UCB.GUIWidgets = UCB.GUIWidgets or {}
local GUIWidgets = UCB.GUIWidgets

-- =========================================================
-- Changelog Window (Keep-a-Changelog markdown -> collapsible UI)
-- Supports headers like:
--   ## [2.4.0] - 2026-02-22
--   ## 2.4.0 - 2026-02-22
--   ## Version 2.4.0 - 2026-02-22
--   ## [Unreleased]
-- =========================================================

GUIWidgets._changelogUI = GUIWidgets._changelogUI or nil

local YELLOW = "|cFFFFD100"
local GREY   = "|cFFB0B0B0"
local WHITE  = "|cFFFFFFFF"
local RESET  = "|r"

-- ---------- Markdown-ish formatting (safe for WoW FontString) ----------
local function StripMarkdown(line)
    if not line or line == "" then return line end

    -- Horizontal rules
    if line:match("^%s*%-%-%-%s*$") then return "" end

    -- Links: [text](url) -> text (url)
    line = line:gsub("%[([^%]]+)%]%(([^%)]+)%)", function(txt, url)
        return txt .. " " .. GREY .. "(" .. url .. ")" .. RESET
    end)

    -- Inline code: `code`
    line = line:gsub("`([^`]+)`", function(code)
        return GREY .. code .. RESET
    end)

    -- Bold: **text**
    line = line:gsub("%*%*([^%*]+)%*%*", function(b)
        return YELLOW .. b .. RESET
    end)

    -- Trim right
    line = line:gsub("%s+$", "")
    return line
end

local function FormatBody(markdownBlock)
    if not markdownBlock or markdownBlock == "" then return "" end

    local out = {}

    for raw in (markdownBlock .. "\n"):gmatch("(.-)\n") do
        local line = StripMarkdown(raw)
        if line ~= "" then
            -- Section headings ### Added/Fixed/Changed etc
            local h3 = line:match("^###%s+(.+)")
            local h4 = line:match("^####%s+(.+)")
            if h3 then
                out[#out + 1] = ""
                out[#out + 1] = YELLOW .. h3 .. RESET
            elseif h4 then
                out[#out + 1] = GREY .. h4 .. RESET
            else
                -- Bullets (preserve indentation)
                local indent, rest = line:match("^(%s*)[-*+]%s+(.+)$")
                if rest then
                    out[#out + 1] = indent .. "• " .. rest
                else
                    out[#out + 1] = line
                end
            end
        end
    end

    -- Trim leading blanks
    while out[1] == "" do table.remove(out, 1) end
    return table.concat(out, "\n")
end

-- ---------- Header parsing ----------
local function ExtractVersionHeader(line)
    line = (line or ""):gsub("%s+$", "")

    -- ✅ Supports: ## Version 0.9.0 - [23-02-2026]
    local ver, date = line:match("^##+%s*[Vv]ersion%s*([%w%._%-]+)%s*%-%s*%[?(%d%d%-%d%d%-%d%d%d%d)%]?%s*$")
    if ver then return ver, date end

    -- (keep any other formats you want below...)
    -- e.g. ## Version 0.9.0 [23-02-2026]
    ver, date = line:match("^##+%s*[Vv]ersion%s*([%w%._%-]+)%s*%[(%d%d%-%d%d%-%d%d%d%d)%]%s*$")
    if ver then return ver, date end

    return nil, nil
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

    for raw in (md or ""):gmatch("[^\r\n]+") do
        local line = raw
        local ver, date = ExtractVersionHeader(line)

        if ver then
            push()
            cur = { version = tostring(ver or ""), date = tostring(date or ""), _lines = {} }
        elseif cur then
            cur._lines[#cur._lines + 1] = line
        end
        -- ignore everything before the first version heading
    end

    push()
    return entries
end

-- ---------- UI ----------
local function EnsureChangelogUI(self)
    if self._changelogUI and self._changelogUI.frame then
        return self._changelogUI
    end

    local f = CreateFrame("Frame", "UCB_ChangelogFrame", UIParent, "BackdropTemplate")
    f:SetToplevel(true)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(500)
    f:SetClampedToScreen(true)
    f:SetSize(700, 520)
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

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText(YELLOW .. "Changelog" .. RESET)
    f.title = title

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -40)
    sep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -40)
    sep:SetColorTexture(1, 1, 1, 0.15)

    local sf = CreateFrame("ScrollFrame", "UCB_ChangelogScroll", f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -50)
    sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -34, 14)

    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(1, 1)
    sf:SetScrollChild(content)

    local sb = sf.ScrollBar or (sf:GetName() and _G[sf:GetName() .. "ScrollBar"])
    if sb then sb:SetAlpha(0.8) end

    self._changelogUI = {
        frame = f,
        scroll = sf,
        content = content,
        rows = {},
        entries = {},
    }

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
    local scroll  = ui.scroll

    local contentWidth = (scroll:GetWidth() or 0) - 10
    if contentWidth < 260 then contentWidth = 260 end
    content:SetWidth(contentWidth)

    local y = -6
    local leftPad  = 10
    local rightPad = 12
    local gap = 10

    for _, row in ipairs(ui.rows) do
        if row.inUse then
            row.header:ClearAllPoints()
            row.header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
            row.header:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
            row.header:SetHeight(30)
            row.header:Show()

            row.bg:SetPoint("TOPLEFT", row.header, "TOPLEFT", 0, 0)
            row.bg:SetPoint("BOTTOMRIGHT", row.header, "BOTTOMRIGHT", 0, 0)

            row.arrow:SetPoint("LEFT", row.header, "LEFT", leftPad, 0)
            row.verFS:SetPoint("LEFT", row.arrow, "RIGHT", 10, 0)
            row.dateFS:SetPoint("RIGHT", row.header, "RIGHT", -rightPad, 0)

            y = y - 30 - 2

            if row.expanded then
                row.body:ClearAllPoints()
                row.body:SetPoint("TOPLEFT", row.header, "BOTTOMLEFT", leftPad + 26, -4)
                row.body:SetWidth(contentWidth - (leftPad + 26) - rightPad)
                row.body:Show()

                local h = row.body:GetStringHeight() or 0
                if h < 1 then h = 1 end
                row.body:SetHeight(h)

                y = y - h - gap
            else
                row.body:Hide()
            end
        else
            row.header:Hide()
            row.body:Hide()
        end
    end

    content:SetHeight(-y + 12)
end

function GUIWidgets:OpenChangelogWindow(windowTitle, mdText)
    local ui = EnsureChangelogUI(self)

    ui.frame.title:SetText(YELLOW .. tostring(windowTitle or "Changelog") .. RESET)

    local entries = ParseChangelog(mdText or "")
    ui.entries = entries

    -- Ensure enough row widgets
    for i = 1, #entries do
        if not ui.rows[i] then
            local header = CreateFrame("Button", nil, ui.content)
            header:EnableMouse(true)

            local bg = header:CreateTexture(nil, "BACKGROUND")
            bg:SetColorTexture(1, 1, 1, 0.03)

            local arrow = header:CreateTexture(nil, "ARTWORK")
            arrow:SetSize(16, 16)
            arrow:SetTexture("Interface\\AddOns\\UltimateCastbars\\gfx\\Icons\\chevron-right.tga")
            arrow:SetVertexColor(1, 0.82, 0, 1) -- gold tint

            local verFS = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            verFS:SetTextColor(1, 0.82, 0, 1)

            local dateFS = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            dateFS:SetTextColor(1, 0.82, 0, 1)

            local body = ui.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            body:SetJustifyH("LEFT")
            body:SetJustifyV("TOP")
            body:SetTextColor(1, 1, 1, 0.95)

            ui.rows[i] = {
                header = header,
                bg = bg,
                arrow = arrow,
                verFS = verFS,
                dateFS = dateFS,
                body = body,
                expanded = false,
                inUse = false,
            }
        end
    end

    -- Populate rows
    for i, row in ipairs(ui.rows) do
        local e = entries[i]
        if e then
            row.inUse = true

            row.expanded = (i == 1) -- newest open by default
            local RIGHT = "Interface\\AddOns\\UltimateCastbars\\gfx\\Icons\\chevron-right.tga"
            local DOWN  = "Interface\\AddOns\\UltimateCastbars\\gfx\\Icons\\chevron-down.tga"

            row.arrow:SetTexture(row.expanded and DOWN or RIGHT)
            row.arrow:SetVertexColor(1, 0.82, 0, 1)

            -- Match the file style: Version + date
            row.verFS:SetText("Version " .. (e.version or ""))
            row.dateFS:SetText(e.date or "")

            row.body:SetText(e.body or "")

            row.header:SetScript("OnEnter", function()
                row.bg:SetColorTexture(1, 1, 1, 0.06)
                row.verFS:SetTextColor(1, 0.90, 0.25, 1)
                row.dateFS:SetTextColor(1, 0.90, 0.25, 1)
            end)
            row.header:SetScript("OnLeave", function()
                row.bg:SetColorTexture(1, 1, 1, 0.03)
                row.verFS:SetTextColor(1, 0.82, 0, 1)
                row.dateFS:SetTextColor(1, 0.82, 0, 1)
            end)

            row.header:SetScript("OnClick", function()
                row.expanded = not row.expanded
                row.arrow:SetTexture(row.expanded and DOWN or RIGHT)
                self:RefreshChangelogLayout()
            end)
        else
            row.inUse = false
        end
    end

    ui.frame:Show()
    ui.frame:Raise()
    ui.scroll:SetVerticalScroll(0)
    self:RefreshChangelogLayout()
end

function GUIWidgets:CreateTopBarButton(parent, opts)
    -- opts: { text="", icon="path", onClick=function(btn) end, width=150, height=18, iconSize=14, scale=1.3 }

    local scale   = opts.scale or 1.3
    local w       = (opts.width or 150) * scale
    local h       = (opts.height or 18) * scale
    local iconSz  = (opts.iconSize or 14) * scale
    local gap     = 6 * scale

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, h)
    btn:SetFrameStrata(parent:GetFrameStrata() or "DIALOG")
    btn:SetFrameLevel((parent:GetFrameLevel() or 0) + 200)

    -- Same look as footer buttons
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    btn:SetBackdropColor(0.10, 0.10, 0.10, 0.50)
    btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.80)

    -- Center container (so icon + text + (New) are centered as a group)
    local content = CreateFrame("Frame", nil, btn)
    content:SetPoint("CENTER", btn, "CENTER", 0, 0)
    content:SetHeight(h)
    btn.content = content

    -- Icon (LEFT)
    local icon = content:CreateTexture(nil, "ARTWORK")
    icon:SetSize(iconSz, iconSz)
    icon:SetTexture(opts.icon or "")
    icon:SetShown(opts.icon ~= nil and opts.icon ~= "")
    btn.icon = icon

    -- Main text
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetJustifyH("LEFT")
    text:SetText(opts.text or "")
    btn.text = text

    -- (New) (RIGHT, optional)
    local newFS = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    newFS:SetText("|cFFFFD100(New)|r")
    newFS:Hide()
    btn.newFS = newFS

    -- Match footer-ish font scaling
    do
        local f, _, flags = text:GetFont()
        if f then text:SetFont(f, (select(2, text:GetFont()) or 12) * scale, flags) end
        local nf, _, nflags = newFS:GetFont()
        if nf then newFS:SetFont(nf, (select(2, newFS:GetFont()) or 11) * scale, nflags) end
    end

    local function Layout()
        local iconW = (icon:IsShown() and iconSz) or 0
        local textW = text:GetStringWidth() or 0
        local newW  = (newFS:IsShown() and (newFS:GetStringWidth() or 0)) or 0

        local total = 0
        if iconW > 0 then total = total + iconW end
        if iconW > 0 and textW > 0 then total = total + gap end
        total = total + textW
        if newW > 0 then total = total + gap + newW end

        content:SetWidth(total)

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

    function btn:SetMainText(t)
        text:SetText(t or "")
        Layout()
    end

    function btn:SetShowNew(show)
        newFS:SetShown(show and true or false)
        Layout()
    end

    -- Same hover/press behavior as footer buttons
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

    -- IMPORTANT: pass the button to onClick
    btn:SetScript("OnClick", function(self)
        if opts.onClick then opts.onClick(self) end
    end)

    Layout()
    return btn
end