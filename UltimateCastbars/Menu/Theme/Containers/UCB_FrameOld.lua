local _, UCB = ...

UCB.UIOptions = UCB.UIOptions or {}

--[[-----------------------------------------------------------------------------
UCB Custom Frame Container (AceGUI)
-------------------------------------------------------------------------------]]
local Type, Version = "UCB_Frame", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local pairs, assert, type = pairs, assert, type
local wipe = table.wipe

local CreateFrame, UIParent, PlaySound = CreateFrame, UIParent, PlaySound

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
-- Methods
-- ---------------------------------------------------------------------------
local methods = {
	OnAcquire = function(self)
		self.frame:SetParent(UIParent)
		self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
		self.frame:SetFrameLevel(100)

		self:SetTitle(self.title or "")
		--self:SetStatusText(self.statusText or "")
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
		local contentwidth = width - 34
		if contentwidth < 0 then contentwidth = 0 end
		content:SetWidth(contentwidth)
		content.width = contentwidth
	end,

	OnHeightSet = function(self, height)
		local content = self.content
		local contentheight = height - 57
		if contentheight < 0 then contentheight = 0 end
		content:SetHeight(contentheight)
		content.height = contentheight
	end,

	SetTitle = function(self, title)
		self.title = title
		self.titletext:SetText(title or "")
		self.titlebg:SetWidth((self.titletext:GetWidth() or 0) + 10)
	end,

	--SetStatusText = function(self, text)
	--	self.statusText = text
	--	self.statustext:SetText(text or "")
	--end,

	Hide = function(self) self.frame:Hide() end,
	Show = function(self) self.frame:Show() end,

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
	end,
}

-- ---------------------------------------------------------------------------
-- Backdrops
-- ---------------------------------------------------------------------------
local FrameBackdrop = {
	bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
	--edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	--edgeFile = "Interface\\Addons\\UltimateCastbars\\gfx\\Assets\\Border\\ShareMedia\\SeerahScalloped.tga",
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	tile = true, tileSize = 1, edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

local PaneBackdrop  = {
	bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 5, bottom = 3 }
}

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------
local function Constructor()


	local gold = UCB.UIOptions.GOLD
	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame:Hide()

	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetFrameLevel(100)
	frame:SetBackdrop(FrameBackdrop)
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetBackdropBorderColor(gold.r, gold.g, gold.b, 1)
	frame:SetToplevel(true)

	if frame.SetResizeBounds then
		frame:SetResizeBounds(400, 200)
	else
		frame:SetMinResize(400, 200)
	end

	frame:SetScript("OnShow", Frame_OnShow)
	frame:SetScript("OnHide", Frame_OnClose)
	frame:SetScript("OnMouseDown", Frame_OnMouseDown)

	-- Close button
	local closebutton = CreateFrame("Button", nil, frame, "UCB_BlackThreeSlice")
	closebutton:SetScript("OnClick", Button_OnClick)
	closebutton:SetPoint("BOTTOMRIGHT", -30, 17)
	closebutton:SetSize(100, 30)
	closebutton:SetText(CLOSE)

	-- Status bar
	--[[
	local statusbg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	statusbg:SetPoint("BOTTOMLEFT", 15, 15)
	statusbg:SetPoint("BOTTOMRIGHT", -132, 15)
	statusbg:SetHeight(24)
	statusbg:SetBackdrop(PaneBackdrop)
	statusbg:SetBackdropColor(0.1, 0.1, 0.1)
	statusbg:SetBackdropBorderColor(0.4, 0.4, 0.4)

	local statustext = statusbg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	statustext:SetPoint("TOPLEFT", 7, -2)
	statustext:SetPoint("BOTTOMRIGHT", -7, 2)
	statustext:SetJustifyH("LEFT")
	statustext:SetText("")
	--]]

	-- Title textures
	local titlebg = frame:CreateTexture(nil, "OVERLAY")
	titlebg:SetTexture(131080) -- UI-DialogBox-Header
	titlebg:SetTexCoord(0.31, 0.67, 0, 0.63)
	titlebg:SetPoint("TOP", 0, 12)
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

	-- Container content region (children go here)
	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", 17, -27)
	content:SetPoint("BOTTOMRIGHT", -17, 40)

	local widget = {
		localstatus = {},
		titletext   = titletext,
		--statustext  = statustext,
		titlebg     = titlebg,
		sizer_se    = sizer_se,
		sizer_s     = sizer_s,
		sizer_e     = sizer_e,
		content     = content,
		frame       = frame,
		type        = Type,
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	closebutton.obj = widget
	frame.obj = widget

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)