UCBSliderMixin = {};

local DEFAULT_SLIDER_LEFT_NORMAL   = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\LeftNormal.png"
local DEFAULT_SLIDER_MIDDLE_NORMAL = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\MidNormal.png"
local DEFAULT_SLIDER_RIGHT_NORMAL  = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\RightNormal.png"

local DEFAULT_SLIDER_LEFT_HOVER    = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\LeftGlow.png"
local DEFAULT_SLIDER_MIDDLE_HOVER  = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\MidGlow.png"
local DEFAULT_SLIDER_RIGHT_HOVER   = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\RightGlow.png"

local DEFAULT_SLIDER_LEFT_DISABLED    = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\LeftDisabled.png"
local DEFAULT_SLIDER_MIDDLE_DISABLED  = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\MidDisabled.png"
local DEFAULT_SLIDER_RIGHT_DISABLED   = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\RightDisabled.png"

local CHEVRON_NORMAL   = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\ChevronNormal.png"
local CHEVRON_HOVER    = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\ChevronHover.png"
local CHEVRON_DISABLED = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Slider\\ChevronDisabled.png"

function UCBSliderMixin:OnLoad()
	self:SetObeyStepOnDrag(self.obeyStepOnDrag);

	if self.Middle then
		self.Middle:SetHorizTile(true);
		self.Middle:SetVertTile(false);
	end

	self.isHovering = false;

	self:ResetHoverTextureSet();

	self:SetDisabledTextureSet(
		DEFAULT_SLIDER_LEFT_DISABLED,
		DEFAULT_SLIDER_MIDDLE_DISABLED,
		DEFAULT_SLIDER_RIGHT_DISABLED
	);

	self:SetScript("OnEnter", function(slider)
		if slider:IsEnabled() then
			slider:SetHovered(true);
		end
	end);

	self:SetScript("OnLeave", function(slider)
		slider:SetHovered(false);
	end);
end

function UCBSliderMixin:Release()
	self:SetScript("OnValueChanged", nil);
	self:SetScript("OnEnter", nil);
	self:SetScript("OnLeave", nil);
end

function UCBSliderMixin:SetHoverTextureSet(
	normalLeft, normalMiddle, normalRight,
	hoverLeft, hoverMiddle, hoverRight
)
	self.NormalLeftTexture = normalLeft;
	self.NormalMiddleTexture = normalMiddle;
	self.NormalRightTexture = normalRight;

	self.HoverLeftTexture = hoverLeft;
	self.HoverMiddleTexture = hoverMiddle;
	self.HoverRightTexture = hoverRight;

	self:UpdateHoverTextures();
end

function UCBSliderMixin:ResetHoverTextureSet()
	self:SetHoverTextureSet(
		DEFAULT_SLIDER_LEFT_NORMAL,
		DEFAULT_SLIDER_MIDDLE_NORMAL,
		DEFAULT_SLIDER_RIGHT_NORMAL,
		DEFAULT_SLIDER_LEFT_HOVER,
		DEFAULT_SLIDER_MIDDLE_HOVER,
		DEFAULT_SLIDER_RIGHT_HOVER
	);
end

function UCBSliderMixin:SetDisabledTextureSet(disabledLeft, disabledMiddle, disabledRight)
	self.DisabledLeftTexture = disabledLeft;
	self.DisabledMiddleTexture = disabledMiddle;
	self.DisabledRightTexture = disabledRight;

	self:UpdateHoverTextures();
end

function UCBSliderMixin:SetHovered(isHovering)
	self.isHovering = isHovering and true or false;
	self:UpdateHoverTextures();
end

function UCBSliderMixin:IsHoveredVisual()
	return self.isHovering;
end

function UCBSliderMixin:UpdateHoverTextures()
	if not self:IsEnabled() then
		self:SetTextures(
			self.DisabledLeftTexture,
			self.DisabledMiddleTexture,
			self.DisabledRightTexture,
			nil
		);
	elseif self.isHovering then
		self:SetTextures(
			self.HoverLeftTexture,
			self.HoverMiddleTexture,
			self.HoverRightTexture,
			nil
		);
	else
		self:SetTextures(
			self.NormalLeftTexture,
			self.NormalMiddleTexture,
			self.NormalRightTexture,
			nil
		);
	end
end

function UCBSliderMixin:SetTextures(leftFile, centerFile, rightFile, thumbFile)
	if leftFile and self.Left then
		self.Left:SetTexture(leftFile);
	end

	if centerFile and self.Middle then
		self.Middle:SetTexture(centerFile);
		self.Middle:SetHorizTile(true);
		self.Middle:SetVertTile(false);
	end

	if rightFile and self.Right then
		self.Right:SetTexture(rightFile);
	end

	if thumbFile and self.Thumb then
		self.Thumb:SetTexture(thumbFile);
	end
end

function UCBSliderMixin:SetCenterTexCoord(left, right, top, bottom)
	if not self.Middle then
		return;
	end

	self.Middle:SetTexCoord(left, right, top, bottom);
	self.Middle:SetHorizTile(true);
	self.Middle:SetVertTile(false);
end

function UCBSliderMixin:SetCenterTexCoordPixels(textureWidth, textureHeight, left, right, top, bottom)
	if not self.Middle then
		return;
	end

	self.Middle:SetTexCoord(
		left / textureWidth,
		right / textureWidth,
		top / textureHeight,
		bottom / textureHeight
	);

	self.Middle:SetHorizTile(true);
	self.Middle:SetVertTile(false);
end

function UCBSliderMixin:SetThumbTexCoord(left, right, top, bottom)
	if self.Thumb then
		self.Thumb:SetTexCoord(left, right, top, bottom);
	end
end

function UCBSliderMixin:SetThumbTexCoordPixels(textureWidth, textureHeight, left, right, top, bottom)
	if self.Thumb then
		self.Thumb:SetTexCoord(
			left / textureWidth,
			right / textureWidth,
			top / textureHeight,
			bottom / textureHeight
		);
	end
end

function UCBSliderMixin:SetLeftTexCoord(left, right, top, bottom)
	if self.Left then
		self.Left:SetTexCoord(left, right, top, bottom);
	end
end

function UCBSliderMixin:SetRightTexCoord(left, right, top, bottom)
	if self.Right then
		self.Right:SetTexCoord(left, right, top, bottom);
	end
end

function UCBSliderMixin:SetLeftTexCoordPixels(textureWidth, textureHeight, left, right, top, bottom)
	if self.Left then
		self.Left:SetTexCoord(
			left / textureWidth,
			right / textureWidth,
			top / textureHeight,
			bottom / textureHeight
		);
	end
end

function UCBSliderMixin:SetRightTexCoordPixels(textureWidth, textureHeight, left, right, top, bottom)
	if self.Right then
		self.Right:SetTexCoord(
			left / textureWidth,
			right / textureWidth,
			top / textureHeight,
			bottom / textureHeight
		);
	end
end

function UCBSliderMixin:SetupTextures(textureInfo)
	if not textureInfo then
		return;
	end

	self:SetTextures(
		textureInfo.leftFile,
		textureInfo.centerFile,
		textureInfo.rightFile,
		textureInfo.thumbFile
	);

	if textureInfo.leftTexCoord and self.Left then
		self.Left:SetTexCoord(unpack(textureInfo.leftTexCoord));
	end

	if textureInfo.rightTexCoord and self.Right then
		self.Right:SetTexCoord(unpack(textureInfo.rightTexCoord));
	end

	if textureInfo.thumbTexCoord and self.Thumb then
		self.Thumb:SetTexCoord(unpack(textureInfo.thumbTexCoord));
	end

	if textureInfo.centerTexCoord and self.Middle then
		self.Middle:SetTexCoord(unpack(textureInfo.centerTexCoord));
		self.Middle:SetHorizTile(true);
		self.Middle:SetVertTile(false);
	end

	if textureInfo.centerPixelTexCoord and textureInfo.centerTextureSize and self.Middle then
		local texWidth = textureInfo.centerTextureSize[1];
		local texHeight = textureInfo.centerTextureSize[2];
		local l, r, t, b = unpack(textureInfo.centerPixelTexCoord);

		self:SetCenterTexCoordPixels(texWidth, texHeight, l, r, t, b);
	end
end

function UCBSliderMixin:SetThumbDimensions(width, height)
	self:SetThumbSize(width, height);
end

function UCBSliderMixin:SyncSideWidthsToHeight(leftTextureWidth, leftTextureHeight, rightTextureWidth, rightTextureHeight)
	local height = self:GetHeight();
	if not height or height <= 0 then
		return;
	end

	if self.Left and leftTextureWidth and leftTextureHeight and leftTextureHeight > 0 then
		self.Left:SetWidth(height * (leftTextureWidth / leftTextureHeight));
	end

	if self.Right and rightTextureWidth and rightTextureHeight and rightTextureHeight > 0 then
		self.Right:SetWidth(height * (rightTextureWidth / rightTextureHeight));
	end
end

function UCBSliderMixin:SyncUniformSideWidthsToHeight(textureWidth, textureHeight)
	self:SyncSideWidthsToHeight(textureWidth, textureHeight, textureWidth, textureHeight);
end

local function NoModification(value)
	return value;
end

function CreateUCBSliderFormatter(labelType, value)
	local formatter = nil;

	if value == nil then
		formatter = NoModification;
	elseif type(value) == "function" then
		formatter = value;
	else
		formatter = function(v)
			return value;
		end
	end

	return formatter;
end

UCBSliderWithSteppersMixin = CreateFromMixins(CallbackRegistryMixin);

UCBSliderWithSteppersMixin:GenerateCallbackEvents({
	"OnValueChanged",
	"OnInteractStart",
	"OnInteractEnd",
});

UCBSliderWithSteppersMixin.Label = EnumUtil.MakeEnum("Left", "Right", "Top", "Min", "Max");

local interactionFlags = {
	Hover = 1,
	Click = 2,
};

function UCBSliderWithSteppersMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self);

	self.InteractionFlags = CreateFromMixins(FlagsMixin);
	self.InteractionFlags:OnLoad();

	self.hoverSources = 0;

	local function AddHover()
		self.hoverSources = self.hoverSources + 1;
		self:SetInteractionFlag(interactionFlags.Hover);
		self.Slider:SetHovered(true);
	end

	local function RemoveHover()
		self.hoverSources = math.max(0, self.hoverSources - 1);

		if self.hoverSources == 0 then
			self:ClearInteractionFlag(interactionFlags.Hover);
			self.Slider:SetHovered(false);
		end
	end

	-- Correct wiring:
	-- Back = decrement
	-- Forward = increment
	self.Back:SetScript("OnClick", function()
		self:OnStepperClicked(false);
	end);

	self.Forward:SetScript("OnClick", function()
		self:OnStepperClicked(true);
	end);

	local function OnMouseDown(slider)
		if slider:IsEnabled() then
			self:SetInteractionFlag(interactionFlags.Click);
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		end
	end
	self.Slider:SetScript("OnMouseDown", OnMouseDown);

	local function OnMouseUp(slider)
		if slider:IsEnabled() then
			self:ClearInteractionFlag(interactionFlags.Click);
		end
	end
	self.Slider:SetScript("OnMouseUp", OnMouseUp);

	self.Slider:SetScript("OnEnter", function(slider)
		if slider:IsEnabled() then
			AddHover();
		end
	end);

	self.Slider:SetScript("OnLeave", function(slider)
		RemoveHover();
	end);

	self.Back:SetScript("OnEnter", function(button)
		if button:IsEnabled() then
			AddHover();
			if button.Icon then
				button.Icon:SetTexture(CHEVRON_HOVER);
				button.Icon:SetRotation(math.rad(-90));
			end
		end
	end);

	self.Back:SetScript("OnLeave", function(button)
		RemoveHover();
		if button.Icon then
			button.Icon:SetTexture(button:IsEnabled() and CHEVRON_NORMAL or CHEVRON_DISABLED);
			button.Icon:SetRotation(math.rad(-90));
		end
	end);

	self.Forward:SetScript("OnEnter", function(button)
		if button:IsEnabled() then
			AddHover();
			if button.Icon then
				button.Icon:SetTexture(CHEVRON_HOVER);
				button.Icon:SetRotation(math.rad(90));
			end
		end
	end);

	self.Forward:SetScript("OnLeave", function(button)
		RemoveHover();
		if button.Icon then
			button.Icon:SetTexture(button:IsEnabled() and CHEVRON_NORMAL or CHEVRON_DISABLED);
			button.Icon:SetRotation(math.rad(90));
		end
	end);

	if self.Back.Icon then
		self.Back.Icon:SetTexture(CHEVRON_NORMAL);
		self.Back.Icon:SetRotation(math.rad(-90));
	end

	if self.Forward.Icon then
		self.Forward.Icon:SetTexture(CHEVRON_NORMAL);
		self.Forward.Icon:SetRotation(math.rad(90));
	end
end

function UCBSliderWithSteppersMixin:OnStepperClicked(forward)
	local value = self.Slider:GetValue();
	local step = self.Slider:GetValueStep();
	local minValue, maxValue = self.Slider:GetMinMaxValues();

	if not step or step == 0 then
		step = 1;
	end

	if forward then
		self.Slider:SetValue(math.min(maxValue, value + step));
	else
		self.Slider:SetValue(math.max(minValue, value - step));
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function UCBSliderWithSteppersMixin:Init(value, minValue, maxValue, steps, formatters)
	self.Slider:SetMinMaxValues(minValue, maxValue);

	local step = 1;
	if steps and steps > 0 then
		step = (maxValue - minValue) / steps;
	end

	self.Slider:SetValueStep(step);
	self.Slider:SetValue(value);

	self.formatters = formatters;
	self:FormatValue(value);

	local function OnValueChanged(slider, newValue)
		self:FormatValue(newValue);
		self:TriggerEvent(UCBSliderWithSteppersMixin.Event.OnValueChanged, newValue);
	end

	self.Slider:SetScript("OnValueChanged", OnValueChanged);
end

function UCBSliderWithSteppersMixin:SetInteractionFlag(flag)
	local wasAnySet = self.InteractionFlags:IsAnySet();
	self.InteractionFlags:Set(flag);

	if not wasAnySet then
		self:TriggerEvent(UCBSliderWithSteppersMixin.Event.OnInteractStart);
	end
end

function UCBSliderWithSteppersMixin:ClearInteractionFlag(flag)
	local wasAnySet = self.InteractionFlags:IsAnySet();
	self.InteractionFlags:Clear(flag);

	if wasAnySet and not self.InteractionFlags:IsAnySet() then
		self:TriggerEvent(UCBSliderWithSteppersMixin.Event.OnInteractEnd);
	end
end

function UCBSliderWithSteppersMixin:FormatValue(value)
	if not self.formatters then
		return;
	end

	for labelID, formatter in pairs(self.formatters) do
		local label = self.Labels[labelID];
		if label then
			label:SetText(formatter(value));
			label:Show();
		end
	end
end

local function ConfigureSlider(self, color, alpha)
	self.Slider.Thumb:SetAlpha(alpha);

	local r, g, b = color:GetRGB();
	self.LeftText:SetVertexColor(r, g, b);
	self.RightText:SetVertexColor(r, g, b);
	self.TopText:SetVertexColor(r, g, b);
	self.MinText:SetVertexColor(r, g, b);
	self.MaxText:SetVertexColor(r, g, b);
end

function UCBSliderWithSteppersMixin:SetEnabled(enabled)
	if enabled then
		ConfigureSlider(self, NORMAL_FONT_COLOR, 1.0);
	else
		ConfigureSlider(self, GRAY_FONT_COLOR, 0.7);
	end

	self.Slider:SetEnabled(enabled);
	self.Slider:UpdateHoverTextures();

	self.Back:SetEnabled(enabled);
	self.Forward:SetEnabled(enabled);

	if self.Back.Icon then
		self.Back.Icon:SetTexture(enabled and CHEVRON_NORMAL or CHEVRON_DISABLED);
		self.Back.Icon:SetRotation(math.rad(-90));
	end

	if self.Forward.Icon then
		self.Forward.Icon:SetTexture(enabled and CHEVRON_NORMAL or CHEVRON_DISABLED);
		self.Forward.Icon:SetRotation(math.rad(90));
	end
end

function UCBSliderWithSteppersMixin:SetValue(value)
	self.Slider:SetValue(value);
end

function UCBSliderWithSteppersMixin:Release()
	self.Slider:Release();

	for _, label in ipairs(self.Labels) do
		label:Hide();
	end
end

function UCBSliderWithSteppersMixin:SetSliderTextures(leftFile, centerFile, rightFile, thumbFile)
	self.Slider:SetTextures(leftFile, centerFile, rightFile, thumbFile);
end

function UCBSliderWithSteppersMixin:SetSliderCenterTexCoord(left, right, top, bottom)
	self.Slider:SetCenterTexCoord(left, right, top, bottom);
end

function UCBSliderWithSteppersMixin:SetSliderCenterTexCoordPixels(textureWidth, textureHeight, left, right, top, bottom)
	self.Slider:SetCenterTexCoordPixels(textureWidth, textureHeight, left, right, top, bottom);
end

function UCBSliderWithSteppersMixin:SetupSliderTextures(textureInfo)
	self.Slider:SetupTextures(textureInfo);
end

function UCBSliderMixin:SetThumbSize(width, height)
	if not self.Thumb then
		return;
	end

	if width then
		self.Thumb:SetWidth(width);
	end

	if height then
		self.Thumb:SetHeight(height);
	end
end

function UCBSliderWithSteppersMixin:SetSliderThumbSize(width, height)
	self.Slider:SetThumbSize(width, height);
end