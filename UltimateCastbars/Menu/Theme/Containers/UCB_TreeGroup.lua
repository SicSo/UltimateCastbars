local _, UCB = ...

UCB.Theme = UCB.Theme or {}
UCB.UIOptions = UCB.UIOptions or {}

local Theme = UCB.Theme
local UIOptions = UCB.UIOptions

local PLUS_NORMAL   = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\PlusBox\\plus_box.png"
local PLUS_HOVER    = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\PlusBox\\plus_box_highlight.png"
local PLUS_DISABLED = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\PlusBox\\plus_box_disabled.png"

local MINUS_NORMAL   = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\MinusBox\\minus_box.png"
local MINUS_HOVER    = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\MinusBox\\minus_box_highlight.png"
local MINUS_DISABLED = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\MinusBox\\minus_box_disabled.png"

--[[-----------------------------------------------------------------------------
TreeGroup Container
Container that uses a tree control to switch between groups.
-------------------------------------------------------------------------------]]
local Type, Version = "UCB_TreeGroup", 49
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local next, pairs, ipairs, assert, type = next, pairs, ipairs, assert, type
local math_min, math_max, floor = math.min, math.max, math.floor
local select, tremove, unpack, tconcat = select, table.remove, unpack, table.concat

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

-- Recycling functions
local new, del
do
	local pool = setmetatable({}, { __mode = "k" })

	function new()
		local t = next(pool)
		if t then
			pool[t] = nil
			return t
		else
			return {}
		end
	end

	function del(t)
		for k in pairs(t) do
			t[k] = nil
		end
		pool[t] = true
	end
end

local DEFAULT_TREE_WIDTH = 175
local DEFAULT_TREE_SIZABLE = true

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
local TOGGLE_TEXCOORD_MIN = 0.1318359375
local TOGGLE_TEXCOORD_MAX = 0.861328125

local function SetToggleTexCoords(toggle)
	local tex = toggle.ucbTexture
	if tex then
		tex:SetTexCoord(
			TOGGLE_TEXCOORD_MIN,
			TOGGLE_TEXCOORD_MAX,
			TOGGLE_TEXCOORD_MIN,
			TOGGLE_TEXCOORD_MAX
		)
	end

	local normal = toggle:GetNormalTexture()
	local pushed = toggle:GetPushedTexture()
	local disabled = toggle:GetDisabledTexture()
	local highlight = toggle:GetHighlightTexture()

	if normal then
		normal:SetTexCoord(TOGGLE_TEXCOORD_MIN, TOGGLE_TEXCOORD_MAX, TOGGLE_TEXCOORD_MIN, TOGGLE_TEXCOORD_MAX)
	end
	if pushed then
		pushed:SetTexCoord(TOGGLE_TEXCOORD_MIN, TOGGLE_TEXCOORD_MAX, TOGGLE_TEXCOORD_MIN, TOGGLE_TEXCOORD_MAX)
	end
	if disabled then
		disabled:SetTexCoord(TOGGLE_TEXCOORD_MIN, TOGGLE_TEXCOORD_MAX, TOGGLE_TEXCOORD_MIN, TOGGLE_TEXCOORD_MAX)
	end
	if highlight then
		highlight:SetTexCoord(TOGGLE_TEXCOORD_MIN, TOGGLE_TEXCOORD_MAX, TOGGLE_TEXCOORD_MIN, TOGGLE_TEXCOORD_MAX)
	end
end

local function UpdateToggleTexture(button)
	local toggle = button.toggle
	if not toggle then return end

	if not button.treeline or not button.treeline.hasChildren then
		toggle:Hide()
		return
	end

	local disabled = button.treeline.disabled
	local expanded = (button.obj.status or button.obj.localstatus).groups[button.uniquevalue]
	local hover = button.isToggleHover == true

	local normalPath
	local hoverPath
	local disabledPath

	if expanded then
		normalPath = MINUS_NORMAL
		hoverPath = MINUS_HOVER
		disabledPath = MINUS_DISABLED
	else
		normalPath = PLUS_NORMAL
		hoverPath = PLUS_HOVER
		disabledPath = PLUS_DISABLED
	end

	local texturePath
	if disabled then
		texturePath = disabledPath
	elseif hover then
		texturePath = hoverPath
	else
		texturePath = normalPath
	end

	local tex = toggle.ucbTexture
	if not tex then
		tex = toggle:CreateTexture(nil, "ARTWORK", nil, 1)
		tex:SetAllPoints(toggle)
		toggle.ucbTexture = tex
	end

	tex:SetTexture(texturePath)
	SetToggleTexCoords(toggle)
	--tex:SetTexCoord(0, 1, 0, 1)
	tex:SetAllPoints(toggle)
	tex:Show()

	if disabled then
		toggle:Disable()
	else
		toggle:Enable()
	end

	toggle:Show()
end

local function GetButtonUniqueValue(line)
	local parent = line.parent
	if parent and parent.value then
		return GetButtonUniqueValue(parent) .. "\001" .. line.value
	else
		return line.value
	end
end

local function UpdateButton(button, treeline, selected, canExpand, isExpanded)
	local text = treeline.text or ""
	local icon = treeline.icon
	local iconCoords = treeline.iconCoords
	local level = treeline.level
	local value = treeline.value
	local uniquevalue = treeline.uniquevalue
	local disabled = treeline.disabled
	local toggle = button.toggle

	button.treeline = treeline
	button.value = value
	button.uniquevalue = uniquevalue
	--button.isToggleHover = false

	if selected then
		button:LockHighlight()
		button.selected = true
	else
		button:UnlockHighlight()
		button.selected = false
	end

	button.level = level

	if level == 1 then
		button:SetNormalFontObject("GameFontNormal")
		button:SetHighlightFontObject("GameFontHighlight")
		button.text:SetPoint("LEFT", (icon and 16 or 0) + 8, 2)
	else
		button:SetNormalFontObject("GameFontHighlightSmall")
		button:SetHighlightFontObject("GameFontHighlightSmall")
		button.text:SetPoint("LEFT", (icon and 16 or 0) + 8 * level, 2)
	end

	if disabled then
		button:EnableMouse(false)
		button.text:SetText("|cff808080" .. text .. FONT_COLOR_CODE_CLOSE)
	else
		button.text:SetText(text)
		button:EnableMouse(true)
	end

	if icon then
		button.icon:SetTexture(icon)
		button.icon:SetPoint("LEFT", 8 * level, (level == 1) and 0 or 1)
	else
		button.icon:SetTexture(nil)
	end

	if iconCoords then
		button.icon:SetTexCoord(unpack(iconCoords))
	else
		button.icon:SetTexCoord(0, 1, 0, 1)
	end

	if canExpand then
		button.treeline.hasChildren = true
		UpdateToggleTexture(button)
	else
		button.treeline.hasChildren = nil
		toggle:Hide()
	end
end

local function ShouldDisplayLevel(tree)
	local result = false
	for _, v in ipairs(tree) do
		if v.children == nil and v.visible ~= false then
			result = true
		elseif v.children then
			result = result or ShouldDisplayLevel(v.children)
		end
		if result then
			return result
		end
	end
	return false
end

local function addLine(self, v, tree, level, parent)
	local line = new()
	line.value = v.value
	line.text = v.text
	line.icon = v.icon
	line.iconCoords = v.iconCoords
	line.disabled = v.disabled
	line.tree = tree
	line.level = level
	line.parent = parent
	line.visible = v.visible
	line.uniquevalue = GetButtonUniqueValue(line)

	if v.children then
		line.hasChildren = true
	else
		line.hasChildren = nil
	end

	self.lines[#self.lines + 1] = line
	return line
end

-- fire an update after one frame to catch the treeframe's height
local function FirstFrameUpdate(frame)
	local self = frame.obj
	frame:SetScript("OnUpdate", nil)
	self:RefreshTree(nil, true)
end

local function BuildUniqueValue(...)
	local n = select("#", ...)
	if n == 1 then
		return ...
	else
		return (...) .. "\001" .. BuildUniqueValue(select(2, ...))
	end
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Expand_OnClick(frame)
	local button = frame.button
	local self = button.obj
	local status = (self.status or self.localstatus).groups
	status[button.uniquevalue] = not status[button.uniquevalue]
	self:RefreshTree()
end

local function Button_OnClick(frame)
	local self = frame.obj
	self:Fire("OnClick", frame.uniquevalue, frame.selected)

	if not frame.selected then
		self:SetSelected(frame.uniquevalue)
		frame.selected = true
		frame:LockHighlight()
		self:RefreshTree()
	end

	AceGUI:ClearFocus()
end

local function Button_OnDoubleClick(button)
	local self = button.obj
	local status = (self.status or self.localstatus).groups
	status[button.uniquevalue] = not status[button.uniquevalue]
	self:RefreshTree()
end

local function Button_OnEnter(frame)
	local self = frame.obj

	self:Fire("OnButtonEnter", frame.uniquevalue, frame)

	if self.enabletooltips then
		local tooltip = AceGUI.tooltip
		tooltip:SetOwner(frame, "ANCHOR_NONE")
		tooltip:ClearAllPoints()
		tooltip:SetPoint("LEFT", frame, "RIGHT")
		tooltip:SetText(frame.text:GetText() or "", 1, 0.82, 0, 1, true)
		tooltip:Show()
	end
end

local function Button_OnLeave(frame)
	local self = frame.obj

	self:Fire("OnButtonLeave", frame.uniquevalue, frame)

	if self.enabletooltips then
		AceGUI.tooltip:Hide()
	end
end

local function Toggle_OnEnter(toggle)
	local button = toggle.button
	if not button then return end
	button.isToggleHover = true
	UpdateToggleTexture(button)
end

local function Toggle_OnLeave(toggle)
	local button = toggle.button
	if not button then return end
	button.isToggleHover = false
	UpdateToggleTexture(button)
end

local function OnScrollValueChanged(frame, value)
	if frame.obj.noupdate then return end

	local self = frame.obj
	local status = self.status or self.localstatus
	status.scrollvalue = floor(value + 0.5)
	self:RefreshTree()
	AceGUI:ClearFocus()
end

local function Tree_OnSizeChanged(frame)
	frame.obj:RefreshTree()
end

local function Tree_OnMouseWheel(frame, delta)
	local self = frame.obj
	if self.showscroll then
		local scrollbar = self.scrollbar
		local min, max = scrollbar:GetMinMaxValues()
		local value = scrollbar:GetValue()
		local newvalue = math_min(max, math_max(min, value - delta))
		if value ~= newvalue then
			scrollbar:SetValue(newvalue)
		end
	end
end

local function Dragger_OnLeave(frame)
	frame:SetBackdropColor(1, 1, 1, 0)
end

local function Dragger_OnEnter(frame)
	frame:SetBackdropColor(1, 1, 1, 0.8)
end

local function Dragger_OnMouseDown(frame)
	local treeframe = frame:GetParent()
	treeframe:StartSizing("RIGHT")
end

local function Dragger_OnMouseUp(frame)
	local treeframe = frame:GetParent()
	local self = treeframe.obj
	local treeframeParent = treeframe:GetParent()

	treeframe:StopMovingOrSizing()
	treeframe:SetUserPlaced(false)

	-- Without this, :GetHeight can get stuck on the current height,
	-- causing the tree contents to not resize.
	treeframe:SetHeight(0)
	treeframe:ClearAllPoints()
	treeframe:SetPoint("TOPLEFT", treeframeParent, "TOPLEFT", 0, 0)
	treeframe:SetPoint("BOTTOMLEFT", treeframeParent, "BOTTOMLEFT", 0, 0)

	local status = self.status or self.localstatus
	status.treewidth = treeframe:GetWidth()

	treeframe.obj:Fire("OnTreeResize", treeframe:GetWidth())
	treeframe.obj:OnWidthSet(status.fullwidth)
	treeframe.obj:DoLayout()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetTreeWidth(DEFAULT_TREE_WIDTH, DEFAULT_TREE_SIZABLE)
		self:EnableButtonTooltips(true)
		self.frame:SetScript("OnUpdate", FirstFrameUpdate)
	end,

	["OnRelease"] = function(self)
		self.status = nil
		self.tree = nil
		self.frame:SetScript("OnUpdate", nil)

		for k, v in pairs(self.localstatus) do
			if k == "groups" then
				for k2 in pairs(v) do
					v[k2] = nil
				end
			else
				self.localstatus[k] = nil
			end
		end

		self.localstatus.scrollvalue = 0
		self.localstatus.treewidth = DEFAULT_TREE_WIDTH
		self.localstatus.treesizable = DEFAULT_TREE_SIZABLE
	end,

	["EnableButtonTooltips"] = function(self, enable)
		self.enabletooltips = enable
	end,

	["CreateButton"] = function(self)
		local num = AceGUI:GetNextWidgetNum("TreeGroupButton")
		local button = CreateFrame("Button", ("AceGUI30TreeButton%d"):format(num), self.treeframe, "OptionsListButtonTemplate")
		button.obj = self
		button.isToggleHover = false

		local icon = button:CreateTexture(nil, "OVERLAY")
		icon:SetWidth(20)
		icon:SetHeight(20)
		button.icon = icon

		button:SetScript("OnClick", Button_OnClick)
		button:SetScript("OnDoubleClick", Button_OnDoubleClick)
		button:SetScript("OnEnter", Button_OnEnter)
		button:SetScript("OnLeave", Button_OnLeave)

		local toggle = button.toggle
		toggle:SetSize(14, 14)
		toggle.button = button
		toggle:RegisterForClicks("LeftButtonUp")
		toggle:SetScript("OnClick", Expand_OnClick)
		toggle:SetScript("OnEnter", Toggle_OnEnter)
		toggle:SetScript("OnLeave", Toggle_OnLeave)

		toggle:SetNormalTexture("")
		toggle:SetPushedTexture("")
		toggle:SetDisabledTexture("")
		toggle:SetHighlightTexture("")

		local normal = toggle:GetNormalTexture()
		local pushed = toggle:GetPushedTexture()
		local disabled = toggle:GetDisabledTexture()
		local highlight = toggle:GetHighlightTexture()

		if normal then normal:SetAlpha(0) normal:Hide() end
		if pushed then pushed:SetAlpha(0) pushed:Hide() end
		if disabled then disabled:SetAlpha(0) disabled:Hide() end
		if highlight then highlight:SetAlpha(0) highlight:Hide() end

		local tex = toggle:CreateTexture(nil, "ARTWORK", nil, 1)
		tex:SetAllPoints(toggle)
		toggle.ucbTexture = tex

		button.text:SetHeight(14) -- Prevents text wrapping

		return button
	end,

	["SetStatusTable"] = function(self, status)
		assert(type(status) == "table")
		self.status = status

		if not status.groups then
			status.groups = {}
		end
		if not status.scrollvalue then
			status.scrollvalue = 0
		end
		if not status.treewidth then
			status.treewidth = DEFAULT_TREE_WIDTH
		end
		if status.treesizable == nil then
			status.treesizable = DEFAULT_TREE_SIZABLE
		end

		self:SetTreeWidth(status.treewidth, status.treesizable)
		self:RefreshTree()
	end,

	["SetTree"] = function(self, tree, filter)
		self.filter = filter
		if tree then
			assert(type(tree) == "table")
		end
		self.tree = tree
		self:RefreshTree()
	end,

	["BuildLevel"] = function(self, tree, level, parent)
		local groups = (self.status or self.localstatus).groups

		for _, v in ipairs(tree) do
			if v.children then
				if not self.filter or ShouldDisplayLevel(v.children) then
					local line = addLine(self, v, tree, level, parent)
					if groups[line.uniquevalue] then
						self:BuildLevel(v.children, level + 1, line)
					end
				end
			elseif v.visible ~= false or not self.filter then
				addLine(self, v, tree, level, parent)
			end
		end
	end,

	["RefreshTree"] = function(self, scrollToSelection, fromOnUpdate)
		local buttons = self.buttons
		local lines = self.lines

		while lines[1] do
			local t = tremove(lines)
			for k in pairs(t) do
				t[k] = nil
			end
			del(t)
		end

		if not self.tree then return end

		local status = self.status or self.localstatus
		local groupstatus = status.groups
		local tree = self.tree
		local treeframe = self.treeframe

		status.scrollToSelection = status.scrollToSelection or scrollToSelection

		self:BuildLevel(tree, 1)

		local numlines = #lines
		local maxlines = floor(((self.treeframe:GetHeight() or 0) - 20) / 18)
		if maxlines <= 0 then return end

		if self.frame:GetParent() == UIParent and not fromOnUpdate then
			self.frame:SetScript("OnUpdate", FirstFrameUpdate)
			return
		end

		local first, last

		scrollToSelection = status.scrollToSelection
		status.scrollToSelection = nil

		if numlines <= maxlines then
			status.scrollvalue = 0
			self:ShowScroll(false)
			first, last = 1, numlines
		else
			self:ShowScroll(true)

			self.noupdate = true
			self.scrollbar:SetMinMaxValues(0, numlines - maxlines)

			if numlines - status.scrollvalue < maxlines then
				status.scrollvalue = numlines - maxlines
			end

			self.noupdate = nil
			first, last = status.scrollvalue + 1, status.scrollvalue + maxlines

			if scrollToSelection and status.selected then
				local show
				for i, line in ipairs(lines) do
					if line.uniquevalue == status.selected then
						show = i
						break
					end
				end

				if show then
					if show < first then
						status.scrollvalue = show - 1
					elseif show > last then
						status.scrollvalue = show - maxlines
					end
					first, last = status.scrollvalue + 1, status.scrollvalue + maxlines
				end
			end

			if self.scrollbar:GetValue() ~= status.scrollvalue then
				self.scrollbar:SetValue(status.scrollvalue)
			end
		end

		local buttonnum = 1
		for i = first, last do
			local line = lines[i]
			local button = buttons[buttonnum]

			if not button then
				button = self:CreateButton()
				buttons[buttonnum] = button

				button:SetParent(treeframe)
				button:SetFrameLevel(treeframe:GetFrameLevel() + 1)
				button:ClearAllPoints()

				if buttonnum == 1 then
					if self.showscroll then
						button:SetPoint("TOPRIGHT", -22, -10)
						button:SetPoint("TOPLEFT", 0, -10)
					else
						button:SetPoint("TOPRIGHT", 0, -10)
						button:SetPoint("TOPLEFT", 0, -10)
					end
				else
					button:SetPoint("TOPRIGHT", buttons[buttonnum - 1], "BOTTOMRIGHT", 0, 0)
					button:SetPoint("TOPLEFT", buttons[buttonnum - 1], "BOTTOMLEFT", 0, 0)
				end
			end

			UpdateButton(button, line, status.selected == line.uniquevalue, line.hasChildren, groupstatus[line.uniquevalue])
			button:Show()
			buttonnum = buttonnum + 1
		end

		for i = buttonnum, #buttons do
			buttons[i]:Hide()
		end
	end,

	["SetSelected"] = function(self, value)
		local status = self.status or self.localstatus
		if status.selected ~= value then
			status.selected = value
			self:Fire("OnGroupSelected", value)
		end
	end,

	["Select"] = function(self, uniquevalue, ...)
		self.filter = false

		local status = self.status or self.localstatus
		local groups = status.groups
		local path = { ... }

		for i = 1, #path do
			groups[tconcat(path, "\001", 1, i)] = true
		end

		status.selected = uniquevalue
		self:RefreshTree(true)
		self:Fire("OnGroupSelected", uniquevalue)
	end,

	["SelectByPath"] = function(self, ...)
		self:Select(BuildUniqueValue(...), ...)
	end,

	["SelectByValue"] = function(self, uniquevalue)
		self:Select(uniquevalue, ("\001"):split(uniquevalue))
	end,

	["ShowScroll"] = function(self, show)
		self.showscroll = show

		if show then
			self.scrollbar:Show()
			if self.buttons[1] then
				self.buttons[1]:SetPoint("TOPRIGHT", self.treeframe, "TOPRIGHT", -22, -10)
			end
		else
			self.scrollbar:Hide()
			if self.buttons[1] then
				self.buttons[1]:SetPoint("TOPRIGHT", self.treeframe, "TOPRIGHT", 0, -10)
			end
		end
	end,

	["OnWidthSet"] = function(self, width)
		local content = self.content
		local treeframe = self.treeframe
		local status = self.status or self.localstatus
		status.fullwidth = width

		local contentwidth = width - status.treewidth - 20
		if contentwidth < 0 then
			contentwidth = 0
		end

		content:SetWidth(contentwidth)
		content.width = contentwidth

		local maxtreewidth = math_min(400, width - 50)

		if maxtreewidth > 100 and status.treewidth > maxtreewidth then
			self:SetTreeWidth(maxtreewidth, status.treesizable)
		end

		if treeframe.SetResizeBounds then
			treeframe:SetResizeBounds(100, 1, maxtreewidth, 1600)
		else
			treeframe:SetMaxResize(maxtreewidth, 1600)
		end
	end,

	["OnHeightSet"] = function(self, height)
		local content = self.content
		local contentheight = height - 20

		if contentheight < 0 then
			contentheight = 0
		end

		content:SetHeight(contentheight)
		content.height = contentheight
	end,

	["SetTreeWidth"] = function(self, treewidth, resizable)
		if not resizable then
			if type(treewidth) == "number" then
				resizable = false
			elseif type(treewidth) == "boolean" then
				resizable = treewidth
				treewidth = DEFAULT_TREE_WIDTH
			else
				resizable = false
				treewidth = DEFAULT_TREE_WIDTH
			end
		end

		self.treeframe:SetWidth(treewidth)
		self.dragger:EnableMouse(resizable)

		local status = self.status or self.localstatus
		status.treewidth = treewidth
		status.treesizable = resizable

		if status.fullwidth then
			self:OnWidthSet(status.fullwidth)
		end
	end,

	["GetTreeWidth"] = function(self)
		local status = self.status or self.localstatus
		return status.treewidth or DEFAULT_TREE_WIDTH
	end,

	["LayoutFinished"] = function(self, width, height)
		if self.noAutoHeight then return end
		self:SetHeight((height or 0) + 20)
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local PaneBackdrop = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border-Maw.blp",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 5, bottom = 3 }
}

local DraggerBackdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = nil,
	tile = true,
	tileSize = 16,
	edgeSize = 1,
	insets = { left = 3, right = 3, top = 7, bottom = 7 }
}

local function Constructor()
	local num = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", nil, UIParent)

	local treeframe = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	treeframe:SetPoint("TOPLEFT")
	treeframe:SetPoint("BOTTOMLEFT")
	treeframe:SetWidth(DEFAULT_TREE_WIDTH)
	treeframe:EnableMouseWheel(true)
	treeframe:SetBackdrop(PaneBackdrop)
	treeframe:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
	treeframe:SetResizable(true)

	if treeframe.SetResizeBounds then
		treeframe:SetResizeBounds(100, 1, 400, 1600)
	else
		treeframe:SetMinResize(100, 1)
		treeframe:SetMaxResize(400, 1600)
	end

	treeframe:SetScript("OnUpdate", FirstFrameUpdate)
	treeframe:SetScript("OnSizeChanged", Tree_OnSizeChanged)
	treeframe:SetScript("OnMouseWheel", Tree_OnMouseWheel)

	local dragger = CreateFrame("Frame", nil, treeframe, "BackdropTemplate")
	dragger:SetWidth(8)
	dragger:SetPoint("TOP", treeframe, "TOPRIGHT")
	dragger:SetPoint("BOTTOM", treeframe, "BOTTOMRIGHT")
	dragger:SetBackdrop(DraggerBackdrop)
	dragger:SetBackdropColor(1, 1, 1, 0)
	dragger:SetScript("OnEnter", Dragger_OnEnter)
	dragger:SetScript("OnLeave", Dragger_OnLeave)
	dragger:SetScript("OnMouseDown", Dragger_OnMouseDown)
	dragger:SetScript("OnMouseUp", Dragger_OnMouseUp)

	local scrollbar = CreateFrame("Slider", ("AceConfigDialogTreeGroup%dScrollBar"):format(num), treeframe, "UIPanelScrollBarTemplate")
	scrollbar:SetScript("OnValueChanged", nil)
	scrollbar:SetPoint("TOPRIGHT", -10, -26)
	scrollbar:SetPoint("BOTTOMRIGHT", -10, 26)
	scrollbar:SetMinMaxValues(0, 0)
	scrollbar:SetValueStep(1)
	scrollbar:SetValue(0)
	scrollbar:SetWidth(16)
	scrollbar:SetScript("OnValueChanged", OnScrollValueChanged)

	local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND")
	scrollbg:SetAllPoints(scrollbar)
	scrollbg:SetColorTexture(0, 0, 0, 0.4)

	local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	border:SetPoint("TOPLEFT", treeframe, "TOPRIGHT")
	border:SetPoint("BOTTOMRIGHT")
	border:SetBackdrop(PaneBackdrop)
	border:SetBackdropColor(0.1, 0.1, 0.1, 0.5)

	local content = CreateFrame("Frame", nil, border)
	content:SetPoint("TOPLEFT", 5, -10)
	content:SetPoint("BOTTOMRIGHT", -5, 10)

	local widget = {
		frame = frame,
		lines = {},
		levels = {},
		buttons = {},
		hasChildren = {},
		localstatus = { groups = {}, scrollvalue = 0, treewidth = DEFAULT_TREE_WIDTH, treesizable = DEFAULT_TREE_SIZABLE },
		filter = false,
		treeframe = treeframe,
		dragger = dragger,
		scrollbar = scrollbar,
		border = border,
		content = content,
		type = Type
	}

	for method, func in pairs(methods) do
		widget[method] = func
	end

	treeframe.obj = widget
	dragger.obj = widget
	scrollbar.obj = widget

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)