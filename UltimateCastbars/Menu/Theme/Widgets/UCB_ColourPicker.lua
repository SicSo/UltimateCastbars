local _, UCB = ...

--[[-----------------------------------------------------------------------------
ColorPicker Widget - UCBColourButtonTemplate version
Uses the custom 3-part button + 4th colour texture overlay
-----------------------------------------------------------------------------]]
local Type, Version = "UCB_ColorPicker", 31
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local pairs = pairs
local CreateFrame, UIParent = CreateFrame, UIParent

local INVERTED_ALPHA = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE)

local C_TEXT       = {r = 1.0, g = 0.82, b = 0.0, a = 1} -- gold
local C_TEXT_HOVER = {r = 1.0, g = 1.0,  b = 1.0, a = 1} -- white
local C_TEXT_DIM   = {r = 0.6, g = 0.6,  b = 0.6, a = 1}

local COLOUR_SWATCH_TEXTURE = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\ColourButton\\ColourRight.png"
local COLOUR_SWATCH_TEXTURE_WIDTH = 556
local COLOUR_SWATCH_TEXTURE_HEIGHT = 598

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
		self.text:SetTextColor(C_TEXT_HOVER.r, C_TEXT_HOVER.g, C_TEXT_HOVER.b, C_TEXT_HOVER.a)
	end
	self:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	local self = frame.obj
	if not self.disabled then
		self.text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b, C_TEXT.a)
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
		self.text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b, C_TEXT.a)
	end,

	["SetLabel"] = function(self, text)
		self.text:SetText(text or "")
	end,

	["SetColor"] = function(self, r, g, b, a)
		self.r = r
		self.g = g
		self.b = b
		self.a = a or 1

		if self.frame.SetColourTexture then
			self.frame:SetColourTexture(
				COLOUR_SWATCH_TEXTURE,
				COLOUR_SWATCH_TEXTURE_WIDTH,
				COLOUR_SWATCH_TEXTURE_HEIGHT
			)
			self.frame:SetColourTextureScale(0.6)
			self.frame:SetColourTextureVertexColor(r or 1, g or 1, b or 1, a or 1)
			self.frame:SetColourTextureShown(true)
			self.frame:SetColourTextureAnchor("CENTER", "CENTER", 3, 0)
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
			self.text:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b, C_TEXT_DIM.a)

			if self.frame.SetColourTextureVertexColor then
				self.frame:SetColourTextureVertexColor(
					self.r or 1,
					self.g or 1,
					self.b or 1,
					(self.a or 1) * 0.7
				)
			end
		else
			self.frame:Enable()
			self.text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b, C_TEXT.a)

			if self.frame.SetColourTextureVertexColor then
				self.frame:SetColourTextureVertexColor(
					self.r or 1,
					self.g or 1,
					self.b or 1,
					self.a or 1
				)
			end
		end
	end,
}

local function Constructor()
	local frame = CreateFrame("Button", nil, UIParent, "UCBColourButtonTemplate")
	frame:Hide()
	frame:SetHeight(24)
	frame:SetWidth(260)

	frame:EnableMouse(true)
	frame:HookScript("OnEnter", Control_OnEnter)
	frame:HookScript("OnLeave", Control_OnLeave)
	frame:HookScript("OnClick", ColorSwatch_OnClick)

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("LEFT", frame, "LEFT", 10, 0)
	text:SetPoint("RIGHT", frame, "RIGHT", -40, 0)
	text:SetJustifyH("LEFT")
	text:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b, C_TEXT.a)

	local widget = {
		text  = text,
		frame = frame,
		type  = Type,
	}

	for method, func in pairs(methods) do
		widget[method] = func
	end

	frame.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)