local _, UCB = ...



--[[-----------------------------------------------------------------------------
ColorPicker Widget - DandersFrames styled template
Matches GUI:CreateColorPicker button layout/style
-----------------------------------------------------------------------------]]
local Type, Version = "UCB_ColorPicker", 29
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local pairs = pairs
local CreateFrame, UIParent = CreateFrame, UIParent

local INVERTED_ALPHA = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE)

-- Match GUI.lua styling
local C_ELEMENT  = {r = 0.18, g = 0.18, b = 0.18, a = 1}
local C_BORDER   = {r = 0.25, g = 0.25, b = 0.25, a = 1}
local C_HOVER    = {r = 0.22, g = 0.22, b = 0.22, a = 1}
local C_TEXT     = {r = 0.9,  g = 0.9,  b = 0.9,  a = 1}
local C_TEXT_DIM = {r = 0.6,  g = 0.6,  b = 0.6,  a = 1}

local function CreateElementBackdrop(frame)
	if not frame.SetBackdrop then
		Mixin(frame, BackdropTemplateMixin)
	end

	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, C_ELEMENT.a)
	frame:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.5)
end

local function ColorCallback(self, r, g, b, a, isAlpha)
	if INVERTED_ALPHA and a then
		a = 1 - a
	end
	if not self.HasAlpha then
		a = 1
	end

	if r == self.r and g == self.g and b == self.b and a == self.a then
		return
	end

	self:SetColor(r, g, b, a)

	if ColorPickerFrame:IsVisible() then
		self:Fire("OnValueChanged", r, g, b, a)
	else
		if isAlpha then
			self:Fire("OnValueConfirmed", r, g, b, a)
		end
	end
end

local function Control_OnEnter(frame)
	local self = frame.obj
	if not self.disabled then
		frame:SetBackdropColor(C_HOVER.r, C_HOVER.g, C_HOVER.b, 1)
	end
	self:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	local self = frame.obj
	if not self.disabled then
		frame:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)
	end
	self:Fire("OnLeave")
end

local function ColorSwatch_OnClick(frame)
	local self = frame.obj
	if self.disabled then
		AceGUI:ClearFocus()
		return
	end

	local r2, g2, b2, a2 = self.r or 0, self.g or 0, self.b or 0, (self.a or 1)
	if INVERTED_ALPHA then
		a2 = 1 - a2
	end

	UCB.GUI:OpenColorPicker(
		{
			r = r2,
			g = g2,
			b = b2,
			a = a2,
		},
		self.HasAlpha,
		function(newColor)
			local r, g, b, a = newColor.r, newColor.g, newColor.b, newColor.a

			if INVERTED_ALPHA and a then
				a = 1 - a
			end
			if not self.HasAlpha then
				a = 1
			end

			self:SetColor(r, g, b, a)
			self:Fire("OnValueChanged", r, g, b, a)
			self:Fire("OnValueConfirmed", r, g, b, a)
		end,
		function()
			local r, g, b, a = r2, g2, b2, a2

			if INVERTED_ALPHA and a then
				a = 1 - a
			end
			if not self.HasAlpha then
				a = 1
			end

			self:SetColor(r, g, b, a)
			self:Fire("OnValueChanged", r, g, b, a)
			self:Fire("OnValueConfirmed", r, g, b, a)
		end,
		function(newColor)
			local r, g, b, a = newColor.r, newColor.g, newColor.b, newColor.a

			if INVERTED_ALPHA and a then
				a = 1 - a
			end
			if not self.HasAlpha then
				a = 1
			end

			self:SetColor(r, g, b, a)
			self:Fire("OnValueChanged", r, g, b, a)
		end
	)

	AceGUI:ClearFocus()
end

local methods = {
	["OnAcquire"] = function(self)
		self:SetHeight(28)
		self:SetWidth(260)
		self:SetHasAlpha(false)
		self:SetColor(0, 0, 0, 1)
		self:SetDisabled(nil)
		self:SetLabel(nil)
	end,

	["SetLabel"] = function(self, text)
		self.text:SetText(text or "")
	end,

	["SetColor"] = function(self, r, g, b, a)
		self.r = r
		self.g = g
		self.b = b
		self.a = a or 1

		-- Main swatch
		self.colorSwatch:SetColorTexture(r, g, b, a or 1)

		-- Checker visibility for alpha
		if self.HasAlpha and (a or 1) < 1 then
			self.checkers:Show()
		else
			self.checkers:Hide()
		end
	end,

	["SetHasAlpha"] = function(self, hasAlpha)
		self.HasAlpha = hasAlpha
		self:SetColor(self.r or 0, self.g or 0, self.b or 0, self.a or 1)
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled

		if disabled then
			self.frame:Disable()
			self.frame:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)
			self.text:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, 1)
			self.colorSwatch:SetDesaturated(true)
			self.colorSwatch:SetAlpha(0.7)

			if self.swatchBorder.SetBackdropBorderColor then
				self.swatchBorder:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
			end
		else
			self.frame:Enable()
			self.text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b, 1)
			self.colorSwatch:SetDesaturated(false)
			self.colorSwatch:SetAlpha(1)

			if self.swatchBorder.SetBackdropBorderColor then
				self.swatchBorder:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.7)
			end
		end
	end,
}

local function Constructor()
	-- Full-width button like GUI:CreateColorPicker
	local frame = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
	frame:Hide()
	frame:SetHeight(24)
	CreateElementBackdrop(frame)

	frame:EnableMouse(true)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)
	frame:SetScript("OnClick", ColorSwatch_OnClick)

	-- Label on left
	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("LEFT", 8, 0)
	text:SetPoint("RIGHT", -52, 0)
	text:SetJustifyH("LEFT")
	text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

	-- Swatch holder on right (rectangular like GUI)
	local swatchHolder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	swatchHolder:SetSize(40, 16)
	swatchHolder:SetPoint("RIGHT", -6, 0)
	CreateElementBackdrop(swatchHolder)
	swatchHolder:SetBackdropColor(0.05, 0.05, 0.05, 1)
	swatchHolder:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.7)

	-- Checker pattern behind color for alpha preview
	local checkers = swatchHolder:CreateTexture(nil, "BACKGROUND")
	checkers:SetAllPoints()
	checkers:SetTexture(188523) -- Tileset\\Generic\\Checkers
	checkers:SetTexCoord(.25, 0, 0.5, .25)
	checkers:SetDesaturated(true)
	checkers:SetVertexColor(1, 1, 1, 0.65)
	checkers:Hide()

	-- Actual swatch fill
	local colorSwatch = swatchHolder:CreateTexture(nil, "ARTWORK")
	colorSwatch:SetPoint("TOPLEFT", 1, -1)
	colorSwatch:SetPoint("BOTTOMRIGHT", -1, 1)
	colorSwatch:SetColorTexture(0, 0, 0, 1)

	local widget = {
		text        = text,
		frame       = frame,
		colorSwatch = colorSwatch,
		checkers    = checkers,
		swatchBorder = swatchHolder,
		type        = Type,
	}

	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)