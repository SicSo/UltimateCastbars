local _, UCB = ...

UCB.UIOptions = UCB.UIOptions or {}

--[[-----------------------------------------------------------------------------
UCB Custom Frame Container (AceGUI)
-------------------------------------------------------------------------------]]
local Type, Version = "UCB_Frame", 2
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local pairs, assert, type, ipairs = pairs, assert, type, ipairs
local wipe = table.wipe

local CreateFrame, UIParent, PlaySound = CreateFrame, UIParent, PlaySound

local FOOTER_SCALE         = 1
local FOOTER_BAR_HEIGHT    = 45
local FOOTER_BAR_OFFSET    = 10
local FOOTER_TOTAL_BOTTOM  = FOOTER_BAR_HEIGHT + FOOTER_BAR_OFFSET + 4

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
-- Backdrops
-- ---------------------------------------------------------------------------
local FrameBackdrop = {
	bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	tile = true, tileSize = 1, edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

local function GetGold()
	local gold = UCB.UIOptions and UCB.UIOptions.GOLD
	if gold then
		return gold.r or 1, gold.g or 0.82, gold.b or 0
	end
	return 1, 0.82, 0
end

-- ---------------------------------------------------------------------------
-- Footer helpers
-- ---------------------------------------------------------------------------
local function OpenFooterLinkPopup(link)
	local GUIWidgets = UCB and UCB.GUIWidgets
	if not GUIWidgets then return end

	if GUIWidgets.OpenLinkPopup then
		GUIWidgets:OpenLinkPopup(link.title or link.text or "Link", link.url or "")
	elseif link.url then
		print((link.title or link.text or "Link") .. ": " .. tostring(link.url))
	end
end

local function CreateFooterButton(parent, opts)
	local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
	btn:SetHeight(30)
	btn:SetWidth((opts.width or 110))

	btn:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 }
	})
	btn:SetBackdropColor(0.10, 0.10, 0.10, 0.50)
	btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.80)

	local icon = btn:CreateTexture(nil, "ARTWORK")
	icon:SetSize(18, 18)
	icon:SetPoint("LEFT", 8, 0)
	if opts.icon then icon:SetTexture(opts.icon) end
	btn.icon = icon

	local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("LEFT", icon, "RIGHT", 8, 0)
	text:SetText(opts.text or "")
	btn.text = text

	do
		local fontPath, fontSize, fontFlags = text:GetFont()
		if fontPath and fontSize then
			text:SetFont(fontPath, opts.textSize or fontSize, fontFlags)
		end
	end

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
	btn:SetScript("OnClick", function()
		if opts.onClick then opts.onClick() end
	end)

	return btn
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
		self.footerData = nil
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
		local contentheight = height - (27 + FOOTER_TOTAL_BOTTOM)
		if contentheight < 0 then contentheight = 0 end
		content:SetHeight(contentheight)
		content.height = contentheight
	end,

	SetTitle = function(self, title)
		self.title = title
		self.titletext:SetText(title or "")
		self.titlebg:SetWidth((self.titletext:GetWidth() or 0) + 10)
	end,

	SetScale = function(self, scale)
		self.frame:SetScale(scale)
	end,

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

	SetFooterData = function(self, footerData)
		self.footerData = footerData or {}

		local bar = self.footerBar
		local center = self.footerCenter
		if not (bar and center) then return end

		local goldR, goldG, goldB = GetGold()
		bar:SetBackdropColor(0.05, 0.05, 0.05, 0.55)
		bar:SetBackdropBorderColor(goldR, goldG, goldB, 1)

		if self.footerLogo then
			if footerData and footerData.logo then
				self.footerLogo:SetTexture(footerData.logo)
				self.footerLogo:Show()
			else
				self.footerLogo:SetTexture(nil)
				self.footerLogo:Hide()
			end
		end

		if self.footerTitle then
			self.footerTitle:SetText((footerData and footerData.title) or "Addon")
		end

		if self.footerMadeByName then
			self.footerMadeByName:SetText((footerData and footerData.madeByName) or "YourName")
		end

		if self.footerButtons then
			for _, btn in ipairs(self.footerButtons) do
				btn:Hide()
				btn:SetParent(nil)
			end
		end
		self.footerButtons = {}

		local links = (footerData and footerData.links) or {}
		local totalWidth = 0
		local gap = 10

		for i, link in ipairs(links) do
			local btn = CreateFooterButton(center, {
				text = link.text,
				icon = link.icon,
				width = link.width or 110,
				onClick = function()
					OpenFooterLinkPopup(link)
				end
			})

			if i == 1 then
				btn:SetPoint("LEFT", center, "LEFT", 0, 0)
			else
				btn:SetPoint("LEFT", self.footerButtons[i - 1], "RIGHT", gap, 0)
			end

			self.footerButtons[i] = btn
			totalWidth = totalWidth + btn:GetWidth()
			if i > 1 then
				totalWidth = totalWidth + gap
			end
		end

		center:SetWidth(totalWidth)
	end,
}

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------
local function Constructor()
	local goldR, goldG, goldB = GetGold()

	local titleTextSize = 14
	local madebyTextSize = 12

	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame:Hide()

	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetFrameLevel(100)
	frame:SetBackdrop(FrameBackdrop)
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetBackdropBorderColor(goldR, goldG, goldB, 1)
	frame:SetToplevel(true)

	if frame.SetResizeBounds then
		frame:SetResizeBounds(400, 200)
	else
		frame:SetMinResize(400, 200)
	end

	frame:SetScript("OnShow", Frame_OnShow)
	frame:SetScript("OnHide", Frame_OnClose)
	frame:SetScript("OnMouseDown", Frame_OnMouseDown)

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

	-- Footer bar
	local footerBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	footerBar:SetHeight(FOOTER_BAR_HEIGHT)
	footerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", FOOTER_BAR_OFFSET, FOOTER_BAR_OFFSET)
	footerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -FOOTER_BAR_OFFSET, FOOTER_BAR_OFFSET)
	footerBar:SetBackdrop({
		--bgFile = "Interface\\Buttons\\WHITE8x8",
		--edgeFile = "Interface\\Buttons\\WHITE8x8",
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\maw_white.png",

		tile = true, tileSize = 32, edgeSize = 16,
		insets = { left = 1, right = 1, top = 1, bottom = 1 }
	})
	footerBar:SetBackdropColor(0.05, 0.05, 0.05, 0.55)
	footerBar:SetBackdropBorderColor(goldR, goldG, goldB, 1)

	local footerLogo = footerBar:CreateTexture(nil, "ARTWORK")
	footerLogo:SetSize(26, 26)
	footerLogo:SetPoint("LEFT", footerBar, "LEFT", 7, 0)

	local footerTitle = footerBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	footerTitle:SetPoint("LEFT", footerLogo, "RIGHT", 4, 0)
	footerTitle:SetText("Addon")
	do
		local fontPath, fontSize, fontFlags = footerTitle:GetFont()
		if fontPath and fontSize then
			footerTitle:SetFont(fontPath, titleTextSize, fontFlags)
		end
	end

	local madeByPrefix = footerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	madeByPrefix:SetPoint("LEFT", footerTitle, "RIGHT", 10, 0)
	madeByPrefix:SetText("Made by ")
	madeByPrefix:SetTextColor(0.85, 0.85, 0.85, 0.90)

	local madeByName = footerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	madeByName:SetPoint("LEFT", madeByPrefix, "RIGHT", 0, 0)
	madeByName:SetText("YourName")
	madeByName:SetTextColor(0.90, 0.75, 0.10, 0.95)

	do
		local fp, fs, ff = madeByPrefix:GetFont()
		if fp and fs then
			madeByPrefix:SetFont(fp, madebyTextSize, ff)
		end
		local np, ns, nf = madeByName:GetFont()
		if np and ns then
			madeByName:SetFont(np, madebyTextSize, nf)
		end
	end

	local footerCenter = CreateFrame("Frame", nil, footerBar)
	footerCenter:SetHeight(30)
	footerCenter:SetPoint("CENTER", footerBar, "CENTER", 0, 0)
	footerCenter:SetWidth(1)

	-- Close button now lives inside footer
	local closebutton = CreateFrame("Button", nil, footerBar, "UCB_BlackThreeSlice")
	closebutton:SetScript("OnClick", Button_OnClick)
	closebutton:SetPoint("RIGHT", footerBar, "RIGHT", -10, 0)
	closebutton:SetSize(100, 30)
	closebutton:SetText(CLOSE)

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
	content:SetPoint("TOPLEFT", 0, 0)
	content:SetPoint("BOTTOMRIGHT", 0, FOOTER_TOTAL_BOTTOM)

	local widget = {
		localstatus      = {},
		titletext        = titletext,
		titlebg          = titlebg,
		sizer_se         = sizer_se,
		sizer_s          = sizer_s,
		sizer_e          = sizer_e,
		content          = content,
		frame            = frame,
		type             = Type,

		footerBar        = footerBar,
		footerLogo       = footerLogo,
		footerTitle      = footerTitle,
		footerMadeByName = madeByName,
		footerCenter     = footerCenter,
		footerButtons    = {},
		closebutton      = closebutton,
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	closebutton.obj = widget
	frame.obj = widget

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)