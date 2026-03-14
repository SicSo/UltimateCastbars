local _, UCB = ...

UCB.Theme = UCB.Theme or {}
UCB.UIOptions = UCB.UIOptions or {}

local Theme = UCB.Theme
local UIOptions = UCB.UIOptions

local SLIDER_BUTTON_NORMAL   = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\ThumbNew.png"
local SLIDER_BUTTON_DISABLED = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\ThumbNewDisabled.png"

--[[-----------------------------------------------------------------------------
Slider Widget
Graphical Slider, like, for Range values.
-----------------------------------------------------------------------------]]
local Type, Version = "UCB_Slider", 25
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local min, max, floor = math.min, math.max, math.floor
local tonumber, pairs = tonumber, pairs

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Support functions
-----------------------------------------------------------------------------]]
local function UpdateText(self)
	local value = self.value or 0
	if self.ispercent then
		self.editbox:SetText(("%s%%"):format(floor(value * 1000 + 0.5) / 10))
	else
		self.editbox:SetText(floor(value * 100 + 0.5) / 100)
	end
end

local function UpdateLabels(self)
	local min_value, max_value = (self.min or 0), (self.max or 100)
	if self.ispercent then
		self.lowtext:SetFormattedText("%s%%", (min_value * 100))
		self.hightext:SetFormattedText("%s%%", (max_value * 100))
	else
		self.lowtext:SetText(min_value)
		self.hightext:SetText(max_value)
	end
end

local function UpdateSliderThumbTexture(self)
	local slider = self.slider and self.slider.Slider
	if not slider then
		return
	end

	if self.disabled then
		slider:SetThumbTexture(SLIDER_BUTTON_DISABLED)
	else
		slider:SetThumbTexture(SLIDER_BUTTON_NORMAL)
	end

	--self.slider:SetSliderThumbSize(20, 20)
	local thumb = slider:GetThumbTexture()
	if thumb then
	--	thumb:SetDrawLayer("OVERLAY")
	--	thumb:SetSize(26, 26)
		--thumb:SetRotation(math.rad(90))
	end
end

local function RefreshSliderHoverState(self)
	local slider = self.slider and self.slider.Slider
	if not slider or not slider.SetHovered then
		return
	end

	local shouldHover =
		(self.__sliderHoverCount or 0) > 0
		or self.__editboxHover
		or self.__editboxFocus

	slider:SetHovered(shouldHover and not self.disabled)
end


local function RefreshForcedEditBoxState(self)
	if not self.editbox then
		return
	end

	if self.disabled then
		if self.editbox.ClearForcedTextureState then
			self.editbox:ClearForcedTextureState()
		end
		RefreshSliderHoverState(self)
		return
	end

	if (self.__sliderHoverCount or 0) > 0 or self.__editboxHover or self.__editboxFocus then
		if self.editbox.SetForcedTextureState then
			self.editbox:SetForcedTextureState("active")
		end
	else
		if self.editbox.ClearForcedTextureState then
			self.editbox:ClearForcedTextureState()
		end
	end

	RefreshSliderHoverState(self)
end


--[[-----------------------------------------------------------------------------
Scripts
-----------------------------------------------------------------------------]]
local function FireOnRelease(self, value)
	if self.onRelease then
		self.onRelease(self, value)
	end
	self:Fire("OnMouseUp", value)
end

local function Slider_OnValueChanged(frame, newvalue)
	local self = frame.obj
	if not self then
		return
	end

	if not frame.setup then
		if self.step and self.step > 0 then
			local min_value = self.min or 0
			newvalue = floor((newvalue - min_value) / self.step + 0.5) * self.step + min_value
		end

		if newvalue ~= self.value and not self.disabled then
			self.value = newvalue
			if not self.commitOnRelease then
				self:Fire("OnValueChanged", newvalue)
			end
		end

		if self.value ~= nil then
			UpdateText(self)
		end
	end
end

local function Slider_OnMouseUp(frame)
	local self = frame.obj
	if not self then
		return
	end

	if self.commitOnRelease then
		FireOnRelease(self, self.value)
	else
		self:Fire("OnMouseUp", self.value)
	end
end

local function Slider_OnMouseWheel(frame, v)
	local self = frame.obj
	if not self then
		return
	end

	if not self.disabled then
		local value = self.value
		if v > 0 then
			value = min(value + (self.step or 1), self.max)
		else
			value = max(value - (self.step or 1), self.min)
		end
		self.slider.Slider:SetValue(value)
	end
end

local function Frame_OnMouseDown(frame)
	if frame.obj and frame.obj.slider and frame.obj.slider.Slider then
		frame.obj.slider.Slider:EnableMouseWheel(true)
	end
	AceGUI:ClearFocus()
end

local function EditBox_OnEnterPressed(frame)
	local self = frame.obj
	local value = frame:GetText()

	if self.ispercent then
		value = value:gsub("%%", "")
		value = tonumber(value)
		if value then
			value = value / 100
		end
	else
		value = tonumber(value)
	end

	if value then
		PlaySound(856)
		self:SetValue(value)
		FireOnRelease(self, self.value)
	end

	frame:ClearFocus()
end

local function EditBox_OnEscapePressed(frame)
	frame:ClearFocus()
end

local function Control_OnEnter(frame)
	if frame.obj then
		frame.obj:Fire("OnEnter")
	end
end

local function Control_OnLeave(frame)
	if frame.obj then
		frame.obj:Fire("OnLeave")
	end
end

local function SliderPart_OnEnter(frame)
	local self = frame.obj
	if not self then
		return
	end

	self.__sliderHoverCount = (self.__sliderHoverCount or 0) + 1
	RefreshForcedEditBoxState(self)
	self:Fire("OnEnter")
end

local function SliderPart_OnLeave(frame)
	local self = frame.obj
	if not self then
		return
	end

	self.__sliderHoverCount = max((self.__sliderHoverCount or 1) - 1, 0)
	RefreshForcedEditBoxState(self)
	self:Fire("OnLeave")
end

local function EditBox_OnEnter(frame)
	local self = frame.obj
	if not self then
		return
	end

	self.__editboxHover = true
	RefreshForcedEditBoxState(self)
	self:Fire("OnEnter")
end

local function EditBox_OnLeave(frame)
	local self = frame.obj
	if not self then
		return
	end

	self.__editboxHover = nil
	RefreshForcedEditBoxState(self)
	self:Fire("OnLeave")
end

local function EditBox_OnEditFocusGained(frame)
	local self = frame.obj
	if not self then
		return
	end

	self.__editboxFocus = true
	RefreshForcedEditBoxState(self)
end

local function EditBox_OnEditFocusLost(frame)
	local self = frame.obj
	if not self then
		return
	end

	self.__editboxFocus = nil
	RefreshForcedEditBoxState(self)
end

--[[-----------------------------------------------------------------------------
Methods
-----------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetWidth(200)
		self:SetHeight(44)
		self:SetDisabled(false)
		self:SetIsPercent(nil)
		self:SetSliderValues(0, 100, 1)
		self:SetValue(0)
		self:SetOnRelease(nil)
		self.slider.Slider:EnableMouseWheel(false)
		self.__sliderHoverCount = 0
		self.__editboxHover = nil
		self.__editboxFocus = nil
		RefreshForcedEditBoxState(self)
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled

		if disabled then
			self.slider.Slider:EnableMouse(false)
			if self.slider.Back then
				self.slider.Back:EnableMouse(false)
			end
			if self.slider.Forward then
				self.slider.Forward:EnableMouse(false)
			end

			self.label:SetTextColor(.5, .5, .5)
			self.hightext:SetTextColor(.5, .5, .5)
			self.lowtext:SetTextColor(.5, .5, .5)
			self.editbox:SetTextColor(.5, .5, .5)
			self.editbox:SetEnabled(false)
			self.editbox:ClearFocus()
			self.slider:SetEnabled(false)

			self.__sliderHoverCount = 0
			self.__editboxHover = nil
			self.__editboxFocus = nil
		else
			self.slider.Slider:EnableMouse(true)
			if self.slider.Back then
				self.slider.Back:EnableMouse(true)
			end
			if self.slider.Forward then
				self.slider.Forward:EnableMouse(true)
			end

			self.label:SetTextColor(1, .82, 0)
			self.hightext:SetTextColor(1, 1, 1)
			self.lowtext:SetTextColor(1, 1, 1)
			self.editbox:SetTextColor(1, 1, 1)
			self.editbox:SetEnabled(true)
			self.slider:SetEnabled(true)
		end

		UpdateSliderThumbTexture(self)
		RefreshForcedEditBoxState(self)
	end,

	["SetCommitOnRelease"] = function(self, state)
		self.commitOnRelease = state
	end,

	["SetOnRelease"] = function(self, callback)
		self.onRelease = callback
	end,

	["SetValue"] = function(self, value)
		local frame = self.slider.Slider
		frame.setup = true
		frame:SetValue(value)
		self.value = value
		UpdateText(self)
		frame.setup = nil
	end,

	["GetValue"] = function(self)
		return self.value
	end,

	["SetLabel"] = function(self, text)
		self.label:SetText(text)
	end,

	["SetSliderValues"] = function(self, min_value, max_value, step)
		local frame = self.slider.Slider
		frame.setup = true
		self.min = min_value
		self.max = max_value
		self.step = step
		frame:SetMinMaxValues(min_value or 0, max_value or 100)
		UpdateLabels(self)
		frame:SetValueStep(step or 1)
		if self.value then
			frame:SetValue(self.value)
		end
		frame.setup = nil
	end,

	["SetIsPercent"] = function(self, value)
		self.ispercent = value
		UpdateLabels(self)
		UpdateText(self)
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-----------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:EnableMouse(true)
	frame:SetScript("OnMouseDown", Frame_OnMouseDown)

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT")
	label:SetPoint("TOPRIGHT")
	label:SetJustifyH("CENTER")
	label:SetHeight(13)

	local slider = CreateFrame("Frame", nil, frame, "UCBSliderWithSteppersTemplate")
	slider:SetPoint("TOP", label, "BOTTOM")
	slider:SetPoint("LEFT", 3, 0)
	slider:SetPoint("RIGHT", -3, 0)
	slider:SetHeight(20)

	local realSlider = slider.Slider

	local lowtext = realSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	lowtext:SetPoint("TOPLEFT", realSlider, "BOTTOMLEFT", 2, 3)

	local hightext = realSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	hightext:SetPoint("TOPRIGHT", realSlider, "BOTTOMRIGHT", -2, 3)

	local editbox = CreateFrame("EditBox", nil, frame, "UCBInputBoxTemplate")
	--editbox:SetForcedTextureState("active")
	editbox:SetAutoFocus(false)
	editbox:SetFontObject(GameFontHighlightSmall)
	editbox:SetPoint("TOP", slider, "BOTTOM")
	editbox:SetHeight(14)
	editbox:SetWidth(70)
	editbox:SetJustifyH("CENTER")
	editbox:EnableMouse(true)

	editbox:HookScript("OnEnter", EditBox_OnEnter)
	editbox:HookScript("OnLeave", EditBox_OnLeave)
	editbox:HookScript("OnEditFocusGained", EditBox_OnEditFocusGained)
	editbox:HookScript("OnEditFocusLost", EditBox_OnEditFocusLost)
	editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
	editbox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)

	--editbox:SyncUniformSideWidthsToHeight(152, 741)

	local widget = {
		label       = label,
		slider      = slider,
		lowtext     = lowtext,
		hightext    = hightext,
		editbox     = editbox,
		alignoffset = 25,
		frame       = frame,
		type        = Type,
		onRelease   = nil,
		__sliderHoverCount = 0,
	}

	for method, func in pairs(methods) do
		widget[method] = func
	end

	slider.obj = widget
	realSlider.obj = widget
	editbox.obj = widget
	frame.obj = widget

	if slider.Back then
		slider.Back.obj = widget
	end
	if slider.Forward then
		slider.Forward.obj = widget
	end

	realSlider:SetOrientation("HORIZONTAL")
	realSlider:SetHeight(10)
	realSlider:SetHitRectInsets(0, 0, -10, 0)
	realSlider:SetThumbTexture(SLIDER_BUTTON_NORMAL)
	realSlider:SyncUniformSideWidthsToHeight(35, 31)

	slider:SetSliderThumbSize(10, 20)

	local thumb = realSlider:GetThumbTexture()
	if thumb then
	--	thumb:SetDrawLayer("OVERLAY")
	--	thumb:SetSize(20, 20)
		--thumb:SetRotation(math.rad(90))
	end

	realSlider:SetScript("OnValueChanged", Slider_OnValueChanged)
	realSlider:SetScript("OnMouseUp", Slider_OnMouseUp)
	realSlider:SetScript("OnMouseWheel", Slider_OnMouseWheel)

	realSlider:HookScript("OnEnter", SliderPart_OnEnter)
	realSlider:HookScript("OnLeave", SliderPart_OnLeave)

	if slider.Back then
		slider.Back:HookScript("OnEnter", SliderPart_OnEnter)
		slider.Back:HookScript("OnLeave", SliderPart_OnLeave)
	end

	if slider.Forward then
		slider.Forward:HookScript("OnEnter", SliderPart_OnEnter)
		slider.Forward:HookScript("OnLeave", SliderPart_OnLeave)
	end

	realSlider:HookScript("OnEnter", Control_OnEnter)
	realSlider:HookScript("OnLeave", Control_OnLeave)

	realSlider.setup = true
	realSlider:SetValue(0)
	realSlider.setup = nil

	UpdateSliderThumbTexture(widget)
	RefreshForcedEditBoxState(widget)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)