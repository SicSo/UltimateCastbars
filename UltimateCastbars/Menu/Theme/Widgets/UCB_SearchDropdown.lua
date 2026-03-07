local _, UCB = ...

local AceGUI = UCB.AG

local Type, Version = "UCB_SearchDropdown", 2
if (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- ============================================================
-- Styling (match your GUI.lua vibe; tweak if you want)
-- ============================================================
local C_PANEL   = { r=0.05, g=0.05, b=0.05, a=0.90 }
local C_BORDER  = { r=0.25, g=0.25, b=0.25, a=0.50 }

local C_ELEMENT = { r=0.055, g=0.055, b=0.060, a=1.00 }
local C_HOVER   = { r=0.085, g=0.085, b=0.090, a=1.00 }

local C_TEXT    = { r=0.90, g=0.90, b=0.90, a=1.00 }
local C_TEXTDIM = { r=0.60, g=0.60, b=0.60, a=1.00 }
--local C_ACCENT  = { r=0.45, g=0.45, b=0.95, a=1.00 }

local C_GOLD    = { r=1.00, g=0.82, b=0.10, a=1.00 }
local C_ACCENT = C_GOLD

-- Radio textures (you said you can import textures)
local RADIO_OFF_TEX = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\radio-off.tga"
local RADIO_ON_TEX  = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\radio-on.tga"

local texture = "Interface\\Addons\\UltimateCastbars\\gfx\\Assets\\Statusbar\\ShareMedia\\Smoothv2.tga"

-- Sizes
local RADIO_SIZE = 14
local ICON_SIZE  = 18

-- ============================================================
-- Backdrop helper
-- ============================================================
local function CreateElementBackdrop(frame)
	if not frame.SetBackdrop then Mixin(frame, BackdropTemplateMixin) end
	frame:SetBackdrop({
		--bgFile = "Interface\\Buttons\\WHITE8x8",
		bgFile = texture,
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, C_ELEMENT.a)
	frame:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, C_BORDER.a)
end

-- Only one open at a time (like your GUI.lua)
local currentOpenMenu
local function CloseOpenMenu()
	if currentOpenMenu and currentOpenMenu:IsShown() then
		currentOpenMenu:Hide()
	end
	currentOpenMenu = nil
end

-- ============================================================
-- Minimal AceGUI callback support
-- ============================================================
local function Fire(self, event, ...)
	if self.callbacks and self.callbacks[event] then
		self.callbacks[event](self, event, ...)
	end
end

-- ============================================================
-- Helpers
-- ============================================================
local function SetChevronOpen(widget, isOpen)
	-- 180° flip for "up"
	widget.arrow:SetRotation(isOpen and math.pi or 0)
end
local function NormalizeOption(v, key)
	-- Supports:
	--   KEY = "text"
	--   KEY = { text="..", icon=spellID OR "texturePath" OR fileID }
	if type(v) == "table" then
		return (v.text or v.label or tostring(key)), v.icon
	end
	return tostring(v), nil
end

local function BuildSortedOptions(list)
	local sorted = {}
	if type(list) ~= "table" then return sorted end

	-- custom order support via _order = { key1, key2, ... }
	if list._order and type(list._order) == "table" then
		for _, k in ipairs(list._order) do
			if list[k] ~= nil then
				local text, icon = NormalizeOption(list[k], k)
				table.insert(sorted, { key = k, text = text, icon = icon })
			end
		end
		return sorted
	end

	-- default alphabetical by display text
	for k, v in pairs(list) do
		if k ~= "_order" then
			local text, icon = NormalizeOption(v, k)
			table.insert(sorted, { key = k, text = text, icon = icon })
		end
	end

	table.sort(sorted, function(a, b)
		return tostring(a.text) < tostring(b.text)
	end)

	return sorted
end

local function PassesSearch(text, query)
	if not query or query == "" then return true end
	text = tostring(text):lower()
	query = tostring(query):lower()
	return text:find(query, 1, true) ~= nil
end

local function ResolveIconTexture(icon)
	-- icon can be:
	--   spellID (number) -> C_Spell.GetSpellTexture(spellID)
	--   fileID (number)  -> SetTexture(fileID) works
	--   texture path (string)
	if not icon then return nil end

	if type(icon) == "number" then
		if C_Spell and C_Spell.GetSpellTexture then
			local tex = C_Spell.GetSpellTexture(icon)
			if tex then return tex end
		end
		return icon
	end

	if type(icon) == "string" then
		return icon
	end

	return nil
end

local function SetRadio(btn, checked)
	if not btn or not btn.Radio then return end
	btn.Radio:SetTexture(checked and RADIO_ON_TEX or RADIO_OFF_TEX)
end

local function ApplySelectionVisuals(widget)
	-- Ensure menu buttons reflect current value:
	--  - radio on/off
	--  - selected text colored accent
	for _, b in ipairs(widget.menuButtons or {}) do
		if b._key ~= nil then
			local isSel = (b._key == widget.value)
			SetRadio(b, isSel)
			if b.Text then
				if isSel then
					b.Text:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
				else
					b.Text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b, 1)
				end
			end
		end
	end
end

-- ============================================================
-- Widget methods (AceConfigDialog select needs these)
-- ============================================================
local function ShowTooltipFromRaw(owner, raw, fallbackText)
	if type(raw) ~= "table" then return end

	local title = raw.name or raw.title or fallbackText or raw.text
	local desc  = raw.desc or raw.description

	if (not title or title == "") and (not desc or desc == "") then return end

	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")

	if title and title ~= "" then
		GameTooltip:SetText(title, C_GOLD.r, C_GOLD.g, C_GOLD.b, 1)
	end
	if desc and desc ~= "" then
		GameTooltip:AddLine(desc, C_TEXT.r, C_TEXT.g, C_TEXT.b, true) -- wrap
	end

	GameTooltip:Show()
end

local methods = {}

function methods:SetDescription(desc)
	self.desc = desc
end

function methods:OnAcquire()
	self.disabled = false
	self.value = nil
	self.list = {}
	self.sorted = {}
	self.searchQuery = ""
	self.desc = nil
	self.label:SetText("")
	self.buttonText:SetText("Select...")
	self.searchBox:SetText("")
	self:RebuildMenu()
end

function methods:OnRelease()
	CloseOpenMenu()
end

function methods:SetCallback(event, func)
	self.callbacks = self.callbacks or {}
	self.callbacks[event] = func
end

function methods:SetLabel(text)
	self.label:SetText(text or "")
end

function methods:SetDisabled(disabled)
	self.disabled = not not disabled
	self.button:SetEnabled(not self.disabled)
	self.searchBox:SetEnabled(not self.disabled)
	self.searchBox:EnableMouse(not self.disabled)

	if self.disabled then
		self.label:SetTextColor(C_TEXTDIM.r, C_TEXTDIM.g, C_TEXTDIM.b, 1)
		self.buttonText:SetTextColor(C_TEXTDIM.r, C_TEXTDIM.g, C_TEXTDIM.b, 1)
	else
		self.label:SetTextColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, C_GOLD.a)
		self.buttonText:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b, 1)
	end
end

function methods:SetWidth(width)
	self.frame:SetWidth(width)
end

function methods:SetList(list)
	self.list = list or {}
	self.sorted = BuildSortedOptions(self.list)
	self:RebuildMenu()
	self:UpdateText()
end

function methods:SetValue(value)
	self.value = value
	self:UpdateText()
	-- If menu is visible, update radios/text immediately
	if self.menuFrame and self.menuFrame:IsShown() then
		ApplySelectionVisuals(self)
	end
end

function methods:GetValue()
	return self.value
end

function methods:UpdateText()
	local v = self.value
	local display, icon = nil, nil

	if self.list and v ~= nil then
		display, icon = NormalizeOption(self.list[v], v)
	end

	self.buttonText:SetText(display or (v ~= nil and tostring(v)) or "Select...")

	-- main button icon
	if self.selectedIcon then
		local tex = ResolveIconTexture(icon)
		if tex then
			self.selectedIcon:SetTexture(tex)
			self.selectedIcon:SetTexCoord(5/64, 59/64, 5/64, 59/64) -- optional crop
			self.selectedIcon:Show()
		else
			self.selectedIcon:SetTexCoord(0, 1, 0, 1)
			self.selectedIcon:Hide()
		end
	end
end

function methods:RebuildMenu()
	-- wipe old buttons
	for _, b in ipairs(self.menuButtons or {}) do
		b:Hide()
		b:SetParent(nil)
	end
	self.menuButtons = {}

	local y = -2
	local widthPadL, widthPadR = 2, 2
	local itemH = 22

	-- search box
	self.searchBox:ClearAllPoints()
	self.searchBox:SetPoint("TOPLEFT", self.menuFrame, "TOPLEFT", 6, -6)
	self.searchBox:SetPoint("TOPRIGHT", self.menuFrame, "TOPRIGHT", -6, -6)

	y = y - (20 + 8) -- search height + spacing

	local shownCount = 0
	local query = self.searchQuery or ""

	for _, opt in ipairs(self.sorted or {}) do
		if PassesSearch(opt.text, query) then
			shownCount = shownCount + 1

			local btn = CreateFrame("Button", nil, self.menuFrame)
			btn:SetPoint("TOPLEFT", widthPadL, y)
			btn:SetPoint("TOPRIGHT", -widthPadR, y)
			btn:SetHeight(itemH)

			-- store key (important for visuals + updates)
			btn._key = opt.key

			-- Highlight texture on hover
			btn.Highlight = btn:CreateTexture(nil, "HIGHLIGHT")
			btn.Highlight:SetAllPoints()
			btn.Highlight:SetColorTexture(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.30)

			-- RADIO (furthest right) - unchanged
			btn.Radio = btn:CreateTexture(nil, "OVERLAY")
			btn.Radio:SetSize(RADIO_SIZE, RADIO_SIZE)
			btn.Radio:SetPoint("RIGHT", -8, 0)
			btn.Radio:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, C_GOLD.a) -- if you want gold

			-- ICON (left side)
			btn.Icon = btn:CreateTexture(nil, "OVERLAY")
			btn.Icon:SetSize(ICON_SIZE, ICON_SIZE)
			btn.Icon:SetPoint("LEFT", 8, 0)

			-- TEXT (between icon and radio)
			btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			btn.Text:SetJustifyH("LEFT")
			btn.Text:SetPoint("LEFT", btn.Icon, "RIGHT", 8, 0)
			btn.Text:SetPoint("RIGHT", btn.Radio, "LEFT", -8, 0)
			btn.Text:SetText(opt.text)

			-- Icon texture (spellID/path/fileID)
			local iconTex = ResolveIconTexture(opt.icon)
			if iconTex then
				btn.Icon:SetTexture(iconTex)
				btn.Icon:SetTexCoord(5/64, 59/64, 5/64, 59/64) -- optional crop
				btn.Icon:Show()
			else
				btn.Icon:SetTexCoord(0, 1, 0, 1)
				btn.Icon:Hide()

				-- If no icon, let text start at the normal left padding
				btn.Text:ClearAllPoints()
				btn.Text:SetPoint("LEFT", 8, 0)
				btn.Text:SetPoint("RIGHT", btn.Radio, "LEFT", -8, 0)
			end

			-- Initial selection visuals
			local isSel = (opt.key == self.value)
			SetRadio(btn, isSel)
			if isSel then
				btn.Text:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
			else
				btn.Text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b, 1)
			end

			btn:SetScript("OnClick", function()
				self.value = opt.key
				self:UpdateText()

				-- Update radios/text without needing a rebuild
				ApplySelectionVisuals(self)

				self.menuFrame:Hide()
				Fire(self, "OnValueChanged", opt.key)
			end)

			btn:SetScript("OnEnter", function()
				local raw = self.list and self.list[btn._key]
				ShowTooltipFromRaw(btn, raw, opt.text)
			end)

			btn:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)

			table.insert(self.menuButtons, btn)
			y = y - itemH
		end
	end

	-- empty state
	if shownCount == 0 then
		local msg = self.menuEmpty
		msg:Show()
		msg:ClearAllPoints()
		msg:SetPoint("TOPLEFT", self.menuFrame, "TOPLEFT", 8, y - 2)
		msg:SetPoint("TOPRIGHT", self.menuFrame, "TOPRIGHT", -8, y - 2)
		msg:SetText("No matches")
		y = y - itemH
	else
		self.menuEmpty:Hide()
	end

	-- menu height (top padding already accounted)
	local totalHeight = math.abs(y) + 6
	self.menuFrame:SetHeight(totalHeight)
end

-- ============================================================
-- Constructor
-- ============================================================
local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetSize(260, 50)

	-- Label
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("TOPLEFT", 0, 0)
	label:SetPoint("TOPRIGHT", 0, 0)
	label:SetJustifyH("LEFT")
	label:SetTextColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, C_GOLD.a)
	--label:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b, 1)

	-- Main button
	--local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
	local button = CreateFrame("Button", nil, frame, "UCB_BlackThreeSlice")
	button:SetPoint("TOPLEFT", 0, -16)
	button:SetPoint("TOPRIGHT", 0, -16)
	button:SetHeight(24)
	--button:SetNormalTexture(texture)
	--CreateElementBackdrop(button)

	-- Button text
	local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	buttonText:SetPoint("LEFT", 8, 0)
	buttonText:SetPoint("RIGHT", -20, 0)
	buttonText:SetJustifyH("LEFT")
	buttonText:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b, 1)

	local selectedIcon = button:CreateTexture(nil, "OVERLAY")
	selectedIcon:SetSize(ICON_SIZE, ICON_SIZE)
	selectedIcon:SetPoint("LEFT", 6, 0)
	selectedIcon:Hide()

	-- Shift text so it doesn't overlap the icon
	buttonText:ClearAllPoints()
	buttonText:SetPoint("LEFT", selectedIcon, "RIGHT", 6, 0)
	buttonText:SetPoint("RIGHT", -20, 0)

	-- Arrow
	local arrow = button:CreateTexture(nil, "OVERLAY")
	arrow:SetPoint("RIGHT", -8, 0)
	arrow:SetSize(12, 12)
	arrow:SetTexture("Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\chevron-down-rounded.tga")
	arrow:SetVertexColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, C_GOLD.a)

	-- Menu frame (parented to UIParent so it floats above config panels)
	local menuFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	menuFrame:ClearAllPoints()
	menuFrame:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
	menuFrame:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", 0, -2)
	menuFrame:SetFrameStrata("TOOLTIP")
	menuFrame:SetFrameLevel(button:GetFrameLevel() + 100)
	menuFrame:SetClampedToScreen(true)
	CreateElementBackdrop(menuFrame)
	menuFrame:SetBackdropColor(C_PANEL.r, C_PANEL.g, C_PANEL.b, C_PANEL.a)
	menuFrame:Hide()

	-- Search box inside menu
	local searchBox = CreateFrame("EditBox", nil, menuFrame, "InputBoxTemplate")
	searchBox:SetAutoFocus(false)
	searchBox:SetHeight(20)
	searchBox:SetTextInsets(6, 6, 0, 0)

	-- Empty label
	local empty = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	empty:SetJustifyH("LEFT")
	empty:SetTextColor(C_TEXTDIM.r, C_TEXTDIM.g, C_TEXTDIM.b, 1)
	empty:Hide()

	local widget = {
		type = Type,
		frame = frame,

		label = label,
		button = button,
		buttonText = buttonText,
		arrow = arrow,
		selectedIcon = selectedIcon,

		menuFrame = menuFrame,
		searchBox = searchBox,
		menuEmpty = empty,
		menuButtons = {},

		list = {},
		sorted = {},
		value = nil,
		searchQuery = "",
	}

	for k, v in pairs(methods) do
		widget[k] = v
	end

	-- Menu open/close tracking
	menuFrame:SetScript("OnHide", function()
		if currentOpenMenu == menuFrame then currentOpenMenu = nil end
	end)

	-- Hover effect
	button:SetScript("OnEnter", function()
		--button:SetBackdropColor(C_HOVER.r, C_HOVER.g, C_HOVER.b, 1)
		--button:SetBackdropBorderColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 1)
	end)
	button:SetScript("OnLeave", function()
		--button:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)
		--button:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, C_BORDER.a)
	end)

	-- Click toggles menu
	button:SetScript("OnClick", function()
		if widget.disabled then return end

		if menuFrame:IsShown() then
			menuFrame:Hide()
			currentOpenMenu = nil
			SetChevronOpen(widget, false)
			return
		end

		CloseOpenMenu()
		ApplySelectionVisuals(widget)

		menuFrame:Show()
		currentOpenMenu = menuFrame
		SetChevronOpen(widget, true)
	end)

	-- Search behavior
	searchBox:SetScript("OnTextChanged", function()
		widget.searchQuery = searchBox:GetText() or ""
		widget:RebuildMenu()
		-- Keep selection visuals accurate after rebuild
		ApplySelectionVisuals(widget)
	end)

	searchBox:SetScript("OnEscapePressed", function()
		searchBox:SetText("")
		searchBox:ClearFocus()
	end)

	-- Focus search when menu opens
	menuFrame:SetScript("OnShow", function()
		searchBox:SetFocus()
		searchBox:HighlightText()
	end)

	menuFrame:HookScript("OnHide", function()
		SetChevronOpen(widget, false)
	end)

	menuFrame:HookScript("OnShow", function()
		SetChevronOpen(widget, true)
	end)

	button:SetScript("OnEnter", function()
	-- your hover visuals
	--button:SetBackdropColor(C_HOVER.r, C_HOVER.g, C_HOVER.b, 1)
	--button:SetBackdropBorderColor(C_GOLD.r, C_GOLD.g, C_GOLD.b, 1)

	-- tooltip from the select option itself (label/desc)
	local title = widget.label and widget.label:GetText()
	local desc  = widget.desc

	if (title and title ~= "") or (desc and desc ~= "") then
			GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
			if title and title ~= "" then
				GameTooltip:SetText(title, C_GOLD.r, C_GOLD.g, C_GOLD.b, 1)
			end
			if desc and desc ~= "" then
				GameTooltip:AddLine(desc, C_TEXT.r, C_TEXT.g, C_TEXT.b, true)
			end
			GameTooltip:Show()
		end
	end)

	button:SetScript("OnLeave", function()
		-- your unhover visuals
		--button:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)
		--button:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, C_BORDER.a)

		GameTooltip:Hide()
	end)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)