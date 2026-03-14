local _, UCB = ...

UCB.Theme = UCB.Theme or {}
UCB.UIOptions = UCB.UIOptions or {}

local Theme = UCB.Theme
local UIOptions = UCB.UIOptions

--[[-----------------------------------------------------------------------------
Global textures
You can override these anywhere before this widget is created.
-----------------------------------------------------------------------------]]

-- Normal state textures
local UCB_EDITBOX_NORMAL_LEFT_TEXTURE   = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\LeftNormal.png"
local UCB_EDITBOX_NORMAL_RIGHT_TEXTURE  = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\RightNormal.png"
local UCB_EDITBOX_NORMAL_MIDDLE_TEXTURE = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\MidNormal.png"

-- Active state textures (hover or focused/editing)
local UCB_EDITBOX_ACTIVE_LEFT_TEXTURE   = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\LeftGlow.png"
local UCB_EDITBOX_ACTIVE_RIGHT_TEXTURE  = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\RightGlow.png"
local UCB_EDITBOX_ACTIVE_MIDDLE_TEXTURE = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\MidGlow.png"

-- Disabled state textures
local UCB_EDITBOX_DISABLED_LEFT_TEXTURE   = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\LeftDisabled.png"
local UCB_EDITBOX_DISABLED_RIGHT_TEXTURE  = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\RightDisabled.png"
local UCB_EDITBOX_DISABLED_MIDDLE_TEXTURE = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\MidDisabled.png"

-- Shared texcoords for all states
local UCB_EDITBOX_LEFT_TEXCOORD   = { 0, 1, 0, 1 }
local UCB_EDITBOX_RIGHT_TEXCOORD  = { 0, 1, 0, 1 }
local UCB_EDITBOX_MIDDLE_TEXCOORD = { 0, 0.25, 0, 1 }

-- Default source texture pixel sizes
local UCB_EDITBOX_LEFT_WIDTH_PX   = 256
local UCB_EDITBOX_LEFT_HEIGHT_PX  = 197
local UCB_EDITBOX_MID_WIDTH_PX    = 939
local UCB_EDITBOX_MID_HEIGHT_PX   = 197
local UCB_EDITBOX_RIGHT_WIDTH_PX  = 247
local UCB_EDITBOX_RIGHT_HEIGHT_PX = 197

--[[-----------------------------------------------------------------------------
EditBox Widget
-----------------------------------------------------------------------------]]
local Type, Version = "UCB_EditBox", 32
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local tostring, pairs, unpack, type = tostring, pairs, unpack, type

-- WoW APIs
local PlaySound = PlaySound
local GetCursorInfo, ClearCursor = GetCursorInfo, ClearCursor
local CreateFrame, UIParent = CreateFrame, UIParent
local _G = _G

--[[-----------------------------------------------------------------------------
Support functions
-----------------------------------------------------------------------------]]
if not AceGUIEditBoxInsertLink then
	if ChatFrameUtil and ChatFrameUtil.InsertLink then
		hooksecurefunc(ChatFrameUtil, "InsertLink", function(...) return _G.AceGUIEditBoxInsertLink(...) end)
	elseif ChatEdit_InsertLink then
		hooksecurefunc("ChatEdit_InsertLink", function(...) return _G.AceGUIEditBoxInsertLink(...) end)
	end
end

function _G.AceGUIEditBoxInsertLink(text)
	for i = 1, AceGUI:GetWidgetCount(Type) do
		local editbox = _G["AceGUI-3.0EditBox"..i]
		if editbox and editbox:IsVisible() and editbox:HasFocus() then
			editbox:Insert(text)
			return true
		end
	end
end

local function CopyTexcoord(texcoord, fallback)
	if texcoord then
		return { unpack(texcoord) }
	end
	return { unpack(fallback) }
end

local function NormalizeRegionInfo(info, fallbackFile, fallbackTexcoord, fallbackWidth, fallbackHeight)
	if type(info) == "string" then
		return {
			file = info,
			texcoord = CopyTexcoord(fallbackTexcoord, fallbackTexcoord),
			width = fallbackWidth,
			height = fallbackHeight,
		}
	end

	info = info or {}

	return {
		file = info.file or fallbackFile,
		texcoord = CopyTexcoord(info.texcoord, fallbackTexcoord),
		width = info.width or info.widthPx or fallbackWidth,
		height = info.height or info.heightPx or fallbackHeight,
	}
end

local function CreateTextureStateSet(stateInfo, defaults)
	stateInfo = stateInfo or {}

	return {
		left = NormalizeRegionInfo(
			stateInfo.left,
			defaults.left.file,
			defaults.left.texcoord,
			defaults.left.width,
			defaults.left.height
		),
		middle = NormalizeRegionInfo(
			stateInfo.middle,
			defaults.middle.file,
			defaults.middle.texcoord,
			defaults.middle.width,
			defaults.middle.height
		),
		right = NormalizeRegionInfo(
			stateInfo.right,
			defaults.right.file,
			defaults.right.texcoord,
			defaults.right.width,
			defaults.right.height
		),
	}
end

local function GetDefaultTextureSet()
	return {
		normal = {
			left = {
				file = UCB_EDITBOX_NORMAL_LEFT_TEXTURE,
				texcoord = CopyTexcoord(UCB_EDITBOX_LEFT_TEXCOORD, UCB_EDITBOX_LEFT_TEXCOORD),
				width = UCB_EDITBOX_LEFT_WIDTH_PX,
				height = UCB_EDITBOX_LEFT_HEIGHT_PX,
			},
			middle = {
				file = UCB_EDITBOX_NORMAL_MIDDLE_TEXTURE,
				texcoord = CopyTexcoord(UCB_EDITBOX_MIDDLE_TEXCOORD, UCB_EDITBOX_MIDDLE_TEXCOORD),
				width = UCB_EDITBOX_MID_WIDTH_PX,
				height = UCB_EDITBOX_MID_HEIGHT_PX,
			},
			right = {
				file = UCB_EDITBOX_NORMAL_RIGHT_TEXTURE,
				texcoord = CopyTexcoord(UCB_EDITBOX_RIGHT_TEXCOORD, UCB_EDITBOX_RIGHT_TEXCOORD),
				width = UCB_EDITBOX_RIGHT_WIDTH_PX,
				height = UCB_EDITBOX_RIGHT_HEIGHT_PX,
			},
		},
		active = {
			left = {
				file = UCB_EDITBOX_ACTIVE_LEFT_TEXTURE,
				texcoord = CopyTexcoord(UCB_EDITBOX_LEFT_TEXCOORD, UCB_EDITBOX_LEFT_TEXCOORD),
				width = UCB_EDITBOX_LEFT_WIDTH_PX,
				height = UCB_EDITBOX_LEFT_HEIGHT_PX,
			},
			middle = {
				file = UCB_EDITBOX_ACTIVE_MIDDLE_TEXTURE,
				texcoord = CopyTexcoord(UCB_EDITBOX_MIDDLE_TEXCOORD, UCB_EDITBOX_MIDDLE_TEXCOORD),
				width = UCB_EDITBOX_MID_WIDTH_PX,
				height = UCB_EDITBOX_MID_HEIGHT_PX,
			},
			right = {
				file = UCB_EDITBOX_ACTIVE_RIGHT_TEXTURE,
				texcoord = CopyTexcoord(UCB_EDITBOX_RIGHT_TEXCOORD, UCB_EDITBOX_RIGHT_TEXCOORD),
				width = UCB_EDITBOX_RIGHT_WIDTH_PX,
				height = UCB_EDITBOX_RIGHT_HEIGHT_PX,
			},
		},
		disabled = {
			left = {
				file = UCB_EDITBOX_DISABLED_LEFT_TEXTURE,
				texcoord = CopyTexcoord(UCB_EDITBOX_LEFT_TEXCOORD, UCB_EDITBOX_LEFT_TEXCOORD),
				width = UCB_EDITBOX_LEFT_WIDTH_PX,
				height = UCB_EDITBOX_LEFT_HEIGHT_PX,
			},
			middle = {
				file = UCB_EDITBOX_DISABLED_MIDDLE_TEXTURE,
				texcoord = CopyTexcoord(UCB_EDITBOX_MIDDLE_TEXCOORD, UCB_EDITBOX_MIDDLE_TEXCOORD),
				width = UCB_EDITBOX_MID_WIDTH_PX,
				height = UCB_EDITBOX_MID_HEIGHT_PX,
			},
			right = {
				file = UCB_EDITBOX_DISABLED_RIGHT_TEXTURE,
				texcoord = CopyTexcoord(UCB_EDITBOX_RIGHT_TEXCOORD, UCB_EDITBOX_RIGHT_TEXCOORD),
				width = UCB_EDITBOX_RIGHT_WIDTH_PX,
				height = UCB_EDITBOX_RIGHT_HEIGHT_PX,
			},
		},
	}
end

local function GetScaledWidthFromHeight(sourceWidth, sourceHeight, targetHeight)
	if not sourceWidth or not sourceHeight or sourceHeight == 0 or not targetHeight or targetHeight <= 0 then
		return nil
	end

	return (sourceWidth / sourceHeight) * targetHeight
end

local function SetRegionTextureFromInfo(region, info, isMiddle)
	if not region or not info then
		return
	end

	if info.file then
		if isMiddle then
			region:SetTexture(info.file, "REPEAT", "CLAMP")
			region:SetHorizTile(true)
			region:SetVertTile(false)
		else
			region:SetTexture(info.file)
		end
	end

	if info.texcoord then
		region:SetTexCoord(unpack(info.texcoord))
	end
end

local function GetTextureStateName(editbox)
	local widget = editbox.obj
	if widget and widget.disabled then
		return "disabled"
	elseif editbox.__ucbHasFocus or editbox.__ucbIsHovered then
		return "active"
	else
		return "normal"
	end
end

local function GetTextureState(editbox)
	local stateName = GetTextureStateName(editbox)
	return editbox.__ucbTextureSet and editbox.__ucbTextureSet[stateName]
end

local function SyncEditBoxSideWidths(editbox)
	local state = GetTextureState(editbox)
	if not state then
		return
	end

	local height = editbox:GetHeight()
	if not height or height <= 0 then
		return
	end

	local leftWidth = GetScaledWidthFromHeight(state.left.width, state.left.height, height)
	local rightWidth = GetScaledWidthFromHeight(state.right.width, state.right.height, height)

	if leftWidth and editbox.Left then
		editbox.Left:SetWidth(leftWidth)
	end

	if rightWidth and editbox.Right then
		editbox.Right:SetWidth(rightWidth)
	end
end

local function UpdateEditBoxTextures(editbox)
	local state = GetTextureState(editbox)
	if not state then
		return
	end

	SetRegionTextureFromInfo(editbox.Left, state.left, false)
	SetRegionTextureFromInfo(editbox.Middle, state.middle, true)
	SetRegionTextureFromInfo(editbox.Right, state.right, false)

	SyncEditBoxSideWidths(editbox)
end

local function ShowButton(self)
	if not self.disablebutton then
		self.button:Show()
		self.editbox:SetTextInsets(25, 10, 0, 1)
	end
end

local function HideButton(self)
	self.button:Hide()
	self.editbox:SetTextInsets(25, 10, 0, 1)
end

--[[-----------------------------------------------------------------------------
Scripts
-----------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
end

local function EditBox_OnMouseEnter(frame)
	frame.__ucbIsHovered = true
	UpdateEditBoxTextures(frame)
	Control_OnEnter(frame)
end

local function EditBox_OnMouseLeave(frame)
	frame.__ucbIsHovered = false
	UpdateEditBoxTextures(frame)
	Control_OnLeave(frame)
end

local function Frame_OnShowFocus(frame)
	frame.obj.editbox:SetFocus()
	frame:SetScript("OnShow", nil)
end

local function EditBox_OnEscapePressed(frame)
	AceGUI:ClearFocus()
end

local function EditBox_OnEnterPressed(frame)
	local self = frame.obj
	local value = frame:GetText()
	local cancel = self:Fire("OnEnterPressed", value)
	if not cancel then
		PlaySound(856)
		HideButton(self)
	end
end

local function EditBox_OnReceiveDrag(frame)
	local self = frame.obj
	local type, id, info, extra = GetCursorInfo()
	local name
	if type == "item" then
		name = info
	elseif type == "spell" then
		if C_Spell and C_Spell.GetSpellName then
			name = C_Spell.GetSpellName(extra)
		else
			name = GetSpellInfo(id, info)
		end
	elseif type == "macro" then
		name = GetMacroInfo(id)
	end
	if name then
		self:SetText(name)
		self:Fire("OnEnterPressed", name)
		ClearCursor()
		HideButton(self)
		AceGUI:ClearFocus()
	end
end

local function EditBox_OnTextChanged(frame)
	local self = frame.obj
	local value = frame:GetText()
	if tostring(value) ~= tostring(self.lasttext) then
		self:Fire("OnTextChanged", value)
		self.lasttext = value
		ShowButton(self)
	end
end

local function EditBox_OnFocusGained(frame)
	frame.__ucbHasFocus = true
	UpdateEditBoxTextures(frame)
	AceGUI:SetFocus(frame.obj)
end

local function EditBox_OnFocusLost(frame)
	frame.__ucbHasFocus = false
	UpdateEditBoxTextures(frame)
end

local function EditBox_OnSizeChanged(frame)
	SyncEditBoxSideWidths(frame)
end

local function Button_OnClick(frame)
	local editbox = frame.obj.editbox
	editbox:ClearFocus()
	EditBox_OnEnterPressed(editbox)
end

--[[-----------------------------------------------------------------------------
Methods
-----------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetWidth(200)
		self:SetDisabled(false)
		self:SetLabel()
		self:SetText()
		self:DisableButton(false)
		self:SetMaxLetters(0)
		self:SetTextureSet(self.textureSet or GetDefaultTextureSet())

		self.editbox.__ucbHasFocus = false
		self.editbox.__ucbIsHovered = false
		UpdateEditBoxTextures(self.editbox)
	end,

	["OnRelease"] = function(self)
		self:ClearFocus()
		self.editbox.__ucbHasFocus = false
		self.editbox.__ucbIsHovered = false
		UpdateEditBoxTextures(self.editbox)
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.editbox:EnableMouse(false)
			self.editbox:ClearFocus()
			self.editbox.__ucbHasFocus = false
			self.editbox.__ucbIsHovered = false
			self.editbox:SetTextColor(0.5, 0.5, 0.5)
			self.label:SetTextColor(0.5, 0.5, 0.5)
		else
			self.editbox:EnableMouse(true)
			self.editbox:SetTextColor(1, 1, 1)
			self.label:SetTextColor(1, .82, 0)
		end
		UpdateEditBoxTextures(self.editbox)
	end,

	["SetText"] = function(self, text)
		self.lasttext = text or ""
		self.editbox:SetText(text or "")
		self.editbox:SetCursorPosition(0)
		HideButton(self)
	end,

	["GetText"] = function(self, text)
		return self.editbox:GetText()
	end,

	["SetLabel"] = function(self, text)
		if text and text ~= "" then
			self.label:SetText(text)
			self.label:Show()
			self.editbox:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -18)
			self:SetHeight(44)
			self.alignoffset = 30
		else
			self.label:SetText("")
			self.label:Hide()
			self.editbox:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
			self:SetHeight(26)
			self.alignoffset = 12
		end
		SyncEditBoxSideWidths(self.editbox)
	end,

	["DisableButton"] = function(self, disabled)
		self.disablebutton = disabled
		if disabled then
			HideButton(self)
		end
	end,

	["SetMaxLetters"] = function(self, num)
		self.editbox:SetMaxLetters(num or 0)
	end,

	["ClearFocus"] = function(self)
		self.editbox:ClearFocus()
		self.editbox.__ucbHasFocus = false
		UpdateEditBoxTextures(self.editbox)
		self.frame:SetScript("OnShow", nil)
	end,

	["SetFocus"] = function(self)
		self.editbox:SetFocus()
		self.editbox.__ucbHasFocus = true
		UpdateEditBoxTextures(self.editbox)
		if not self.frame:IsShown() then
			self.frame:SetScript("OnShow", Frame_OnShowFocus)
		end
	end,

	["HighlightText"] = function(self, from, to)
		self.editbox:HighlightText(from, to)
	end,

	["SetTextureSet"] = function(self, textureSet)
		local defaults = GetDefaultTextureSet()

		self.textureSet = {
			normal = CreateTextureStateSet(textureSet and textureSet.normal, defaults.normal),
			active = CreateTextureStateSet(textureSet and textureSet.active, defaults.active),
			disabled = CreateTextureStateSet(textureSet and textureSet.disabled, defaults.disabled),
		}

		self.editbox.__ucbTextureSet = self.textureSet
		UpdateEditBoxTextures(self.editbox)
	end,

	["SetTextureState"] = function(self, stateName, leftInfo, middleInfo, rightInfo)
		local current = self.textureSet or GetDefaultTextureSet()

		current[stateName] = CreateTextureStateSet({
			left = leftInfo,
			middle = middleInfo,
			right = rightInfo,
		}, current[stateName] or GetDefaultTextureSet()[stateName])

		self:SetTextureSet(current)
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-----------------------------------------------------------------------------]]
local function Constructor()
	local num = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	local editbox = CreateFrame("EditBox", "AceGUI-3.0EditBox"..num, frame, "UCBInputBoxTemplate")
	editbox:SetAutoFocus(false)

	editbox:SetScript("OnEnter", EditBox_OnMouseEnter)
	editbox:SetScript("OnLeave", EditBox_OnMouseLeave)
	editbox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
	editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
	editbox:SetScript("OnTextChanged", EditBox_OnTextChanged)
	editbox:SetScript("OnReceiveDrag", EditBox_OnReceiveDrag)
	editbox:SetScript("OnMouseDown", EditBox_OnReceiveDrag)
	editbox:SetScript("OnEditFocusGained", EditBox_OnFocusGained)
	editbox:SetScript("OnEditFocusLost", EditBox_OnFocusLost)
	editbox:SetScript("OnSizeChanged", EditBox_OnSizeChanged)

	editbox:SetTextInsets(25, 10, 0, 1)
	editbox:SetMaxLetters(256)
	editbox:SetPoint("BOTTOMLEFT", 6, 0)
	editbox:SetPoint("BOTTOMRIGHT")
	editbox:SetHeight(25)
	editbox:SetWidth(120)

	editbox.__ucbHasFocus = false
	editbox.__ucbIsHovered = false
	editbox.__ucbTextureSet = GetDefaultTextureSet()

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", 15, 0)
	label:SetPoint("TOPRIGHT", 0, 0)
	label:SetJustifyH("LEFT")
	label:SetHeight(20)

	local button = CreateFrame("Button", nil, editbox, "UCB_BlackThreeSlice")
	button:SetWidth(40)
	button:SetHeight(15)
	button:SetPoint("RIGHT", -22, 20)
	button:SetText(OKAY)
	button:SetScript("OnClick", Button_OnClick)
	button:Hide()

	local font, _, flags = button:GetFontString():GetFont()
	button:GetFontString():SetFont(font, 9, flags)

	local widget = {
		alignoffset = 30,
		editbox = editbox,
		label = label,
		button = button,
		frame = frame,
		type = Type,
		disabled = false,
		textureSet = GetDefaultTextureSet(),
	}

	for method, func in pairs(methods) do
		widget[method] = func
	end

	editbox.obj, button.obj = widget, widget

	UpdateEditBoxTextures(editbox)

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)