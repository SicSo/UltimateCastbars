local _, UCB = ...

UCB.UIOptions = UCB.UIOptions or {}

--[[-----------------------------------------------------------------------------
UCB Custom Frame Container (AceGUI)
Uses 8 separate border textures instead of SetBackdrop edgeFile atlas
-------------------------------------------------------------------------------]]
local Type, Version = "UCB_Frame1", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local pairs, assert, type = pairs, assert, type
local wipe = table.wipe

local CreateFrame, UIParent, PlaySound = CreateFrame, UIParent, PlaySound

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local BORDER_SIZE = 64
local CONTENT_PAD = 8
local BOTTOM_EXTRA = 28

local BORDER_PATH = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Test\\"

-- ---------------------------------------------------------------------------
-- Scripts
-- ---------------------------------------------------------------------------
local function Button_OnClick(frame)
	PlaySound(799) -- SOUNDKIT.GS_TITLE_OPTION_EXIT
	frame.obj:Hide()
end

local function Frame_OnShow(frame) frame.obj:Fire("OnShow") end
local function Frame_OnClose(frame) frame.obj:Fire("OnClose") end
local function Frame_OnMouseDown() AceGUI:ClearFocus() end

local function Title_OnMouseDown(frame)
	frame:GetParent():StartMoving()
	AceGUI:ClearFocus()
end

local function MoverSizer_OnMouseUp(mover)
	local frame = mover:GetParent()
	frame:StopMovingOrSizing()

	local self = frame.obj
	local status = self.status or self.localstatus
	status.width  = frame:GetWidth()
	status.height = frame:GetHeight()
	status.top    = frame:GetTop()
	status.left   = frame:GetLeft()
end

local function SizerSE_OnMouseDown(frame)
	frame:GetParent():StartSizing("BOTTOMRIGHT")
	AceGUI:ClearFocus()
end

local function SizerS_OnMouseDown(frame)
	frame:GetParent():StartSizing("BOTTOM")
	AceGUI:ClearFocus()
end

local function SizerE_OnMouseDown(frame)
	frame:GetParent():StartSizing("RIGHT")
	AceGUI:ClearFocus()
end

-- ---------------------------------------------------------------------------
-- Border helpers
-- ---------------------------------------------------------------------------
local function CreateBorderTexture(parent, layer, texture)
	local tex = parent:CreateTexture(nil, layer or "BORDER")
	tex:SetTexture(texture)
	tex:SetVertexColor(1, 1, 1, 1)
	return tex
end

local function LayoutBorder(self)
	local frame = self.frame
	local border = self.border

	if not border then return end

	local w = frame:GetWidth() or 0
	local h = frame:GetHeight() or 0
	local bs = self.borderSize or BORDER_SIZE

	-- Corners
	border.tl:ClearAllPoints()
	border.tl:SetPoint("TOPLEFT", frame, "TOPLEFT", -bs, bs)
	border.tl:SetSize(bs, bs)

	border.tr:ClearAllPoints()
	border.tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT", bs, bs)
	border.tr:SetSize(bs, bs)

	border.bl:ClearAllPoints()
	border.bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -bs, -bs)
	border.bl:SetSize(bs, bs)

	border.br:ClearAllPoints()
	border.br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", bs, -bs)
	border.br:SetSize(bs, bs)

	-- Edges
	border.top:ClearAllPoints()
	border.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, bs)
	border.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, bs)
	border.top:SetHeight(bs)

	border.bottom:ClearAllPoints()
	border.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, -bs)
	border.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, -bs)
	border.bottom:SetHeight(bs)

	border.left:ClearAllPoints()
	border.left:SetPoint("TOPLEFT", frame, "TOPLEFT", -bs, 0)
	border.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -bs, 0)
	border.left:SetWidth(bs)

	border.right:ClearAllPoints()
	border.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", bs, 0)
	border.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", bs, 0)
	border.right:SetWidth(bs)
end

-- ---------------------------------------------------------------------------
-- Methods
-- ---------------------------------------------------------------------------
local methods = {
	OnAcquire = function(self)
		self.frame:SetParent(UIParent)
		self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
		self.frame:SetFrameLevel(100)

		self:SetTitle(self.title or "")
		self:ApplyStatus()
		self:EnableResize(true)
		self:Show()
	end,

	OnRelease = function(self)
		self.status = nil
		wipe(self.localstatus)
	end,

	OnWidthSet = function(self, width)
		local content = self.content
		local contentwidth = width - (CONTENT_PAD * 2)
		if contentwidth < 0 then contentwidth = 0 end
		content:SetWidth(contentwidth)
		content.width = contentwidth

		LayoutBorder(self)
	end,

	OnHeightSet = function(self, height)
		local content = self.content
		local contentheight = height - (CONTENT_PAD * 2) - BOTTOM_EXTRA
		if contentheight < 0 then contentheight = 0 end
		content:SetHeight(contentheight)
		content.height = contentheight

		LayoutBorder(self)
	end,

	SetTitle = function(self, title)
		self.title = title
		self.titletext:SetText(title or "")
		self.titlebg:SetWidth((self.titletext:GetWidth() or 0) + 10)
	end,

	Hide = function(self) self.frame:Hide() end,
	Show = function(self)
		self.frame:Show()
		LayoutBorder(self)
	end,

	EnableResize = function(self, state)
		local func = state and "Show" or "Hide"
		self.sizer_se[func](self.sizer_se)
		self.sizer_s[func](self.sizer_s)
		self.sizer_e[func](self.sizer_e)
	end,

	SetStatusTable = function(self, status)
		assert(type(status) == "table")
		self.status = status
		self:ApplyStatus()
	end,

	ApplyStatus = function(self)
		local status = self.status or self.localstatus
		local frame = self.frame

		self:SetWidth(status.width or 700)
		self:SetHeight(status.height or 500)

		frame:ClearAllPoints()
		if status.top and status.left then
			frame:SetPoint("TOP", UIParent, "BOTTOM", 0, status.top)
			frame:SetPoint("LEFT", UIParent, "LEFT", status.left, 0)
		else
			frame:SetPoint("CENTER")
		end

		LayoutBorder(self)
	end,
}

-- ---------------------------------------------------------------------------
-- Backdrops
-- ---------------------------------------------------------------------------
local FrameBackdrop = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	tile = true,
	tileSize = 32,
	insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------
local function Constructor()
	local gold = UCB.UIOptions.GOLD or { r = 1, g = 0.82, b = 0 }

	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame:Hide()

	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetFrameLevel(100)
	frame:SetBackdrop(FrameBackdrop)
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetToplevel(true)

	if frame.SetResizeBounds then
		frame:SetResizeBounds(400, 200)
	else
		frame:SetMinResize(400, 200)
	end

	frame:SetScript("OnShow", Frame_OnShow)
	frame:SetScript("OnHide", Frame_OnClose)
	frame:SetScript("OnMouseDown", Frame_OnMouseDown)

	-- Manual border textures
	local border = {
		top         = CreateBorderTexture(frame, "BORDER", BORDER_PATH .. "top.tga"),
		bottom      = CreateBorderTexture(frame, "BORDER", BORDER_PATH .. "bottom.tga"),
		left        = CreateBorderTexture(frame, "BORDER", BORDER_PATH .. "left.tga"),
		right       = CreateBorderTexture(frame, "BORDER", BORDER_PATH .. "right.tga"),
		tl          = CreateBorderTexture(frame, "BORDER", BORDER_PATH .. "top_left.tga"),
		tr          = CreateBorderTexture(frame, "BORDER", BORDER_PATH .. "top_right.tga"),
		bl          = CreateBorderTexture(frame, "BORDER", BORDER_PATH .. "bottom_left.tga"),
		br          = CreateBorderTexture(frame, "BORDER", BORDER_PATH .. "bottom_right.tga"),
	}

	-- Optional tint if you want it
	for _, tex in pairs(border) do
		tex:SetVertexColor(gold.r or 1, gold.g or 1, gold.b or 1, 1)
	end

	-- Close button
	local closebutton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	closebutton:SetScript("OnClick", Button_OnClick)
	closebutton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
	closebutton:SetSize(100, 20)
	closebutton:SetText(CLOSE)

	-- Title textures
	local titlebg = frame:CreateTexture(nil, "OVERLAY")
	titlebg:SetTexture(131080) -- UI-DialogBox-Header
	titlebg:SetTexCoord(0.31, 0.67, 0, 0.63)
	titlebg:SetPoint("TOP", frame, "TOP", 0, 12)
	titlebg:SetSize(100, 40)

	local title = CreateFrame("Frame", nil, frame)
	title:EnableMouse(true)
	title:SetScript("OnMouseDown", Title_OnMouseDown)
	title:SetScript("OnMouseUp", MoverSizer_OnMouseUp)
	title:SetAllPoints(titlebg)

	local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titletext:SetPoint("TOP", titlebg, "TOP", 0, -14)

	local titlebg_l = frame:CreateTexture(nil, "OVERLAY")
	titlebg_l:SetTexture(131080)
	titlebg_l:SetTexCoord(0.21, 0.31, 0, 0.63)
	titlebg_l:SetPoint("RIGHT", titlebg, "LEFT")
	titlebg_l:SetSize(30, 40)

	local titlebg_r = frame:CreateTexture(nil, "OVERLAY")
	titlebg_r:SetTexture(131080)
	titlebg_r:SetTexCoord(0.67, 0.77, 0, 0.63)
	titlebg_r:SetPoint("LEFT", titlebg, "RIGHT")
	titlebg_r:SetSize(30, 40)

	-- Resizers
	local sizer_se = CreateFrame("Frame", nil, frame)
	sizer_se:SetPoint("BOTTOMRIGHT")
	sizer_se:SetSize(25, 25)
	sizer_se:EnableMouse(true)
	sizer_se:SetScript("OnMouseDown", SizerSE_OnMouseDown)
	sizer_se:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

	local sizer_s = CreateFrame("Frame", nil, frame)
	sizer_s:SetPoint("BOTTOMRIGHT", -25, 0)
	sizer_s:SetPoint("BOTTOMLEFT")
	sizer_s:SetHeight(25)
	sizer_s:EnableMouse(true)
	sizer_s:SetScript("OnMouseDown", SizerS_OnMouseDown)
	sizer_s:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

	local sizer_e = CreateFrame("Frame", nil, frame)
	sizer_e:SetPoint("BOTTOMRIGHT", 0, 25)
	sizer_e:SetPoint("TOPRIGHT")
	sizer_e:SetWidth(25)
	sizer_e:EnableMouse(true)
	sizer_e:SetScript("OnMouseDown", SizerE_OnMouseDown)
	sizer_e:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

	-- Container content region
	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", frame, "TOPLEFT", CONTENT_PAD, -CONTENT_PAD)
	content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_PAD, BOTTOM_EXTRA)

	local widget = {
		localstatus = {},
		titletext   = titletext,
		titlebg     = titlebg,
		sizer_se    = sizer_se,
		sizer_s     = sizer_s,
		sizer_e     = sizer_e,
		content     = content,
		frame       = frame,
		border      = border,
		borderSize  = BORDER_SIZE,
		type        = Type,
	}

	for method, func in pairs(methods) do
		widget[method] = func
	end

	closebutton.obj = widget
	frame.obj = widget

	LayoutBorder(widget)

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)