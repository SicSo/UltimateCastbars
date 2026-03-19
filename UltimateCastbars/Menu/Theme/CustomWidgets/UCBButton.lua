UCBButtonMixin = {};

local function ApplyRegionTexture(region, info)
	if not region or not info then
		return;
	end

	local isMiddle = region == region:GetParent().Middle;

	if info.file then
		if isMiddle then
			region:SetTexture(info.file, "REPEAT", "CLAMP");
		else
			region:SetTexture(info.file);
		end
	end

	if not isMiddle and info.texCoord then
		region:SetTexCoord(unpack(info.texCoord));
	end
end

local function GetTextureAspectWidthFromHeight(fileWidth, fileHeight, targetHeight)
	if not fileWidth or not fileHeight or fileHeight == 0 or not targetHeight then
		return nil;
	end

	return (fileWidth / fileHeight) * targetHeight;
end

function UCBButtonMixin:OnLoad()
	self.__ucbHovered = false;
	self.__ucbPressed = false;

	local sideWidth = tonumber(self.sideWidth) or 20;
	self.sideWidth = sideWidth;

	if self.Left then
		self.Left:SetWidth(sideWidth);
	end

	if self.Right then
		self.Right:SetWidth(sideWidth);
	end

	self.textureStates = self.textureStates or {
		normal = {
			left = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Button\\LeftNormal.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 694,
				fileHeight = 876,
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Button\\MidNormal.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 1370,
				fileHeight = 876,
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Button\\RightNormal.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 694,
				fileHeight = 876,
			},
		},

		hover = {
			left = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Button\\LeftHover.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 694,
				fileHeight = 876,
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Button\\MidHover.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 1370,
				fileHeight = 876,
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Button\\RightHover.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 694,
				fileHeight = 876,
			},
		},

		pressed = {
			left = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Button\\LeftPress.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 694,
				fileHeight = 876,
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Button\\MidPress.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 1370,
				fileHeight = 876,
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Button\\RightPress.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 694,
				fileHeight = 876,
			},
		},

		disabled = {
			left = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Button\\LeftDisabled.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 694,
				fileHeight = 876,
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Button\\MidDisabled.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 1370,
				fileHeight = 876,
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\Button\\RightDisabled.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 694,
				fileHeight = 876,
			},
		},
	};

	self:UpdateVisualState();
end

function UCBButtonMixin:OnEnable()
	self:UpdateVisualState();
end

function UCBButtonMixin:OnDisable()
	self.__ucbHovered = false
	self.__ucbPressed = false
	self:SetHoverTextStyle(false)
	self:UpdateVisualState()
end

function UCBButtonMixin:OnEnter()
	self.__ucbHovered = true
	self:SetHoverTextStyle(true)
	self:UpdateVisualState()
end

function UCBButtonMixin:OnLeave()
	self.__ucbHovered = false
	self.__ucbPressed = false
	self:SetHoverTextStyle(false)
	self:UpdateVisualState()
end

function UCBButtonMixin:OnMouseDown()
	if not self:IsEnabled() then
		return;
	end

	self.__ucbPressed = true;
	self:UpdateVisualState();
end

function UCBButtonMixin:OnMouseUp()
	if not self:IsEnabled() then
		return;
	end

	self.__ucbPressed = false;
	self:UpdateVisualState();
end

function UCBButtonMixin:OnSizeChanged()
	self:SyncSideWidthsFromHeight();
	self:UpdateMiddleTilingFromHeight();
end

function UCBButtonMixin:GetTextureState()
	if not self:IsEnabled() then
		return "disabled";
	end

	if self.__ucbPressed then
		return "pressed";
	end

	if self.__ucbHovered then
		return "hover";
	end

	return "normal";
end

function UCBButtonMixin:GetCurrentStateData()
	local stateName = self:GetTextureState();
	return self.textureStates and self.textureStates[stateName];
end

function UCBButtonMixin:SyncSideWidthsFromHeight()
	local state = self:GetCurrentStateData();
	if not state then
		return;
	end

	local height = self:GetHeight();
	if not height or height <= 0 then
		return;
	end

	local leftInfo = state.left;
	local rightInfo = state.right;

	local leftWidth = leftInfo and GetTextureAspectWidthFromHeight(leftInfo.fileWidth, leftInfo.fileHeight, height);
	local rightWidth = rightInfo and GetTextureAspectWidthFromHeight(rightInfo.fileWidth, rightInfo.fileHeight, height);

	if leftWidth and self.Left then
		self.Left:SetWidth(leftWidth);
	end

	if rightWidth and self.Right then
		self.Right:SetWidth(rightWidth);
	end

	if leftWidth and rightWidth and leftWidth == rightWidth then
		self.sideWidth = leftWidth;
	end
end

function UCBButtonMixin:UpdateMiddleTilingFromHeight()
	local state = self:GetCurrentStateData();
	if not state or not state.middle or not self.Middle then
		return;
	end

	local middleInfo = state.middle;

	if middleInfo.file then
		self.Middle:SetTexture(middleInfo.file, "REPEAT", "CLAMP");
	end

	local buttonHeight = self:GetHeight();
	if not buttonHeight or buttonHeight <= 0 then
		return;
	end

	local middleWidth = self:GetWidth();
	if self.Left then
		middleWidth = middleWidth - self.Left:GetWidth();
	end
	if self.Right then
		middleWidth = middleWidth - self.Right:GetWidth();
	end
	middleWidth = math.max(0, middleWidth);

	local tileWidth = GetTextureAspectWidthFromHeight(
		middleInfo.fileWidth,
		middleInfo.fileHeight,
		buttonHeight
	);

	if not tileWidth or tileWidth <= 0 then
		self.Middle:SetTexCoord(0, 1, 0, 1);
		return;
	end

	local baseTexCoord = middleInfo.texCoord or { 0, 1, 0, 1 };
	local u1 = baseTexCoord[1] or 0;
	local u2 = baseTexCoord[2] or 1;
	local v1 = baseTexCoord[3] or 0;
	local v2 = baseTexCoord[4] or 1;

	local baseURange = u2 - u1;
	if baseURange == 0 then
		baseURange = 1;
	end

	local repeatCount = middleWidth / tileWidth;
	local tiledU2 = u1 + (baseURange * repeatCount);

	self.Middle:SetTexCoord(u1, tiledU2, v1, v2);
	self.Middle:SetVertTile(false);
end

function UCBButtonMixin:UpdateVisualState()
	local state = self:GetCurrentStateData();
	if not state then
		return;
	end

	ApplyRegionTexture(self.Left, state.left);
	ApplyRegionTexture(self.Right, state.right);
	ApplyRegionTexture(self.Middle, state.middle);

	self:SyncSideWidthsFromHeight();
	self:UpdateMiddleTilingFromHeight();
end

function UCBButtonMixin:SetSideWidth(sideWidth)
	sideWidth = tonumber(sideWidth);
	if not sideWidth then
		return;
	end

	self.sideWidth = sideWidth;

	if self.Left then
		self.Left:SetWidth(sideWidth);
	end

	if self.Right then
		self.Right:SetWidth(sideWidth);
	end

	self:UpdateMiddleTilingFromHeight();
end

function UCBButtonMixin:SetupTextureStates(textureStates)
	if not textureStates then
		return;
	end

	self.textureStates = textureStates;
	self:UpdateVisualState();
end

function UCBButtonMixin:SetTexturesForState(stateName, leftFile, middleFile, rightFile)
	if not self.textureStates then
		self.textureStates = {};
	end

	self.textureStates[stateName] = {
		left = {
			file = leftFile,
			texCoord = { 0, 1, 0, 1 },
		},
		middle = {
			file = middleFile,
			texCoord = { 0, 1, 0, 1 },
		},
		right = {
			file = rightFile,
			texCoord = { 0, 1, 0, 1 },
		},
	};

	self:UpdateVisualState();
end

function UCBButtonMixin:SetStateTextureSizes(stateName, leftWidth, leftHeight, middleWidth, middleHeight, rightWidth, rightHeight)
	if not self.textureStates or not self.textureStates[stateName] then
		return;
	end

	local state = self.textureStates[stateName];

	if state.left then
		state.left.fileWidth = leftWidth;
		state.left.fileHeight = leftHeight;
	end

	if state.middle then
		state.middle.fileWidth = middleWidth;
		state.middle.fileHeight = middleHeight;
	end

	if state.right then
		state.right.fileWidth = rightWidth;
		state.right.fileHeight = rightHeight;
	end

	self:UpdateVisualState();
end

function UCBButtonMixin:SetHoverTextStyle(enabled)
	local text = self:GetFontString()
	if not text then
		return
	end

	local font, size = text:GetFont()
	if not font or not size then
		return
	end

	if enabled then
		text:SetFont(font, size, "THICKOUTLINE")
		text:SetShadowOffset(2, -2)
		text:SetShadowColor(0, 0, 0, 1)
	else
		text:SetFont(font, size, "")
		text:SetShadowOffset(0, 0)
		text:SetShadowColor(0, 0, 0, 0)
	end
end