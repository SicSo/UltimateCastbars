UCBColourButtonMixin = {};

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

function UCBColourButtonMixin:OnLoad()
	self.__ucbHovered = false;
	self.__ucbPressed = false;

	self.__ucbColorTextureData = self.__ucbColorTextureData or {
        point = "CENTER",
        relativePoint = "CENTER",
        offsetX = 0,
        offsetY = 0,
        shown = false,
        file = nil,
        fileWidth = nil,
        fileHeight = nil,
        texCoord = nil,
        scale = 0.6,
    };

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
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\ColourButton\\LeftNormal.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 820,
				fileHeight = 1052,
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\ColourButton\\MidNormal.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 728,
				fileHeight = 1052,
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\ColourButton\\RightNormalEmpty.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 1229,
				fileHeight = 1052,
			},
		},

		hover = {
			left = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\ColourButton\\LeftHover.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 820,
				fileHeight = 1052,
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\ColourButton\\MidHover.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 728,
				fileHeight = 1052,
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\ColourButton\\RightHoverEmpty.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 1229,
				fileHeight = 1052,
			},
		},

		pressed = {
			left = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\ColourButton\\LeftNormal.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 820,
				fileHeight = 1052,
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\ColourButton\\MidNormal.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 728,
				fileHeight = 1052,
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\ColourButton\\RightNormalEmpty.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 1229,
				fileHeight = 1052,
			},
		},

		disabled = {
			left = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\ColourButton\\LeftDisabled.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 820,
				fileHeight = 1052,
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\ColourButton\\MidDisabled.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 728,
				fileHeight = 1052,
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\ColourButton\\RightDisabledEmpty.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 1229,
				fileHeight = 1052,
			},
		},
	};

	if self.ColorTexture then
		self.ColorTexture:Hide();
	end

	self:UpdateVisualState();
	self:UpdateColorTextureLayout();
end

function UCBColourButtonMixin:OnEnable()
	self:SetHoverTextStyle(false)
	self:UpdateVisualState()
end

function UCBColourButtonMixin:OnDisable()
	self.__ucbHovered = false
	self.__ucbPressed = false
	self:SetHoverTextStyle(false)
	self:UpdateVisualState()
end

function UCBColourButtonMixin:OnEnter()
	self.__ucbHovered = true
	self:SetHoverTextStyle(true)
	self:UpdateVisualState()
end

function UCBColourButtonMixin:OnLeave()
	self.__ucbHovered = false
	self.__ucbPressed = false
	self:SetHoverTextStyle(false)
	self:UpdateVisualState()
end

function UCBColourButtonMixin:OnMouseDown()
	if not self:IsEnabled() then
		return;
	end

	self.__ucbPressed = true;
	self:UpdateVisualState();
end

function UCBColourButtonMixin:OnMouseUp()
	if not self:IsEnabled() then
		return;
	end

	self.__ucbPressed = false;
	self:UpdateVisualState();
end

function UCBColourButtonMixin:OnSizeChanged()
	self:SyncSideWidthsFromHeight();
	self:UpdateMiddleTilingFromHeight();
	self:UpdateColorTextureLayout();
end

function UCBColourButtonMixin:GetTextureState()
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

function UCBColourButtonMixin:GetCurrentStateData()
	local stateName = self:GetTextureState();
	return self.textureStates and self.textureStates[stateName];
end

function UCBColourButtonMixin:SyncSideWidthsFromHeight()
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

function UCBColourButtonMixin:UpdateMiddleTilingFromHeight()
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

function UCBColourButtonMixin:UpdateColorTextureLayout()
	if not self.ColorTexture then
		return;
	end

	local data = self.__ucbColorTextureData;
	if not data or not data.shown or not data.file then
		self.ColorTexture:Hide();
		return;
	end

	local baseHeight = self:GetHeight();
    if not baseHeight or baseHeight <= 0 then
        return;
    end

    local scale = tonumber(data.scale) or 1;
    local targetHeight = baseHeight * scale;

    local targetWidth = GetTextureAspectWidthFromHeight(data.fileWidth, data.fileHeight, targetHeight);
	if not targetWidth or targetWidth <= 0 then
		if self.Right and self.Right:GetWidth() and self.Right:GetWidth() > 0 then
			targetWidth = self.Right:GetWidth();
		else
			targetWidth = targetHeight;
		end
	end

	self.ColorTexture:ClearAllPoints();

	if self.Right then
		self.ColorTexture:SetPoint(
			data.point or "CENTER",
			self.Right,
			data.relativePoint or "CENTER",
			data.offsetX or 0,
			data.offsetY or 0
		);
	else
		self.ColorTexture:SetPoint(
			data.point or "CENTER",
			self,
			data.relativePoint or "CENTER",
			data.offsetX or 0,
			data.offsetY or 0
		);
	end

	self.ColorTexture:SetSize(targetWidth, targetHeight);
	self.ColorTexture:Show();
end

function UCBColourButtonMixin:UpdateVisualState()
	local state = self:GetCurrentStateData();
	if not state then
		return;
	end

	ApplyRegionTexture(self.Left, state.left);
	ApplyRegionTexture(self.Right, state.right);
	ApplyRegionTexture(self.Middle, state.middle);

	self:SyncSideWidthsFromHeight();
	self:UpdateMiddleTilingFromHeight();
	self:UpdateColorTextureLayout();
end

function UCBColourButtonMixin:SetSideWidth(sideWidth)
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
	self:UpdateColorTextureLayout();
end

function UCBColourButtonMixin:SetupTextureStates(textureStates)
	if not textureStates then
		return;
	end

	self.textureStates = textureStates;
	self:UpdateVisualState();
end

function UCBColourButtonMixin:SetTexturesForState(stateName, leftFile, middleFile, rightFile)
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

function UCBColourButtonMixin:SetStateTextureSizes(stateName, leftWidth, leftHeight, middleWidth, middleHeight, rightWidth, rightHeight)
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

function UCBColourButtonMixin:SetColorTexture(textureFile, fileWidth, fileHeight, texCoord)
	if not self.ColorTexture then
		return;
	end

	self.__ucbColorTextureData = self.__ucbColorTextureData or {};

	self.__ucbColorTextureData.file = textureFile;
	self.__ucbColorTextureData.fileWidth = fileWidth;
	self.__ucbColorTextureData.fileHeight = fileHeight;
	self.__ucbColorTextureData.texCoord = texCoord;
	self.__ucbColorTextureData.shown = textureFile ~= nil;

	if textureFile then
		self.ColorTexture:SetTexture(textureFile);

		if texCoord then
			self.ColorTexture:SetTexCoord(unpack(texCoord));
		else
			self.ColorTexture:SetTexCoord(0, 1, 0, 1);
		end

		self:UpdateColorTextureLayout();
	else
		self.ColorTexture:Hide();
	end
end

function UCBColourButtonMixin:SetColourTexture(textureFile, fileWidth, fileHeight, texCoord)
	self:SetColorTexture(textureFile, fileWidth, fileHeight, texCoord);
end

function UCBColourButtonMixin:SetColorTextureShown(shown)
	if not self.ColorTexture then
		return;
	end

	self.__ucbColorTextureData = self.__ucbColorTextureData or {};
	self.__ucbColorTextureData.shown = shown and true or false;

	if self.__ucbColorTextureData.shown and self.__ucbColorTextureData.file then
		self:UpdateColorTextureLayout();
	else
		self.ColorTexture:Hide();
	end
end

function UCBColourButtonMixin:SetColourTextureShown(shown)
	self:SetColorTextureShown(shown);
end

function UCBColourButtonMixin:SetColorTextureOffsets(offsetX, offsetY)
	self.__ucbColorTextureData = self.__ucbColorTextureData or {};
	self.__ucbColorTextureData.offsetX = tonumber(offsetX) or 0;
	self.__ucbColorTextureData.offsetY = tonumber(offsetY) or 0;
	self:UpdateColorTextureLayout();
end

function UCBColourButtonMixin:SetColourTextureOffsets(offsetX, offsetY)
	self:SetColorTextureOffsets(offsetX, offsetY);
end

function UCBColourButtonMixin:SetColorTextureAnchor(point, relativePoint, offsetX, offsetY)
	self.__ucbColorTextureData = self.__ucbColorTextureData or {};
	self.__ucbColorTextureData.point = point or "CENTER";
	self.__ucbColorTextureData.relativePoint = relativePoint or "CENTER";
	self.__ucbColorTextureData.offsetX = tonumber(offsetX) or self.__ucbColorTextureData.offsetX or 0;
	self.__ucbColorTextureData.offsetY = tonumber(offsetY) or self.__ucbColorTextureData.offsetY or 0;
	self:UpdateColorTextureLayout();
end

function UCBColourButtonMixin:SetColourTextureAnchor(point, relativePoint, offsetX, offsetY)
	self:SetColorTextureAnchor(point, relativePoint, offsetX, offsetY);
end

function UCBColourButtonMixin:SetColorTextureVertexColor(r, g, b, a)
	if not self.ColorTexture then
		return;
	end

	self.ColorTexture:SetVertexColor(r or 1, g or 1, b or 1, a == nil and 1 or a);
end

function UCBColourButtonMixin:SetColourTextureVertexColor(r, g, b, a)
	self:SetColorTextureVertexColor(r, g, b, a);
end

function UCBColourButtonMixin:SetColourTextureScale(scale)
	self.__ucbColorTextureData = self.__ucbColorTextureData or {};
	self.__ucbColorTextureData.scale = tonumber(scale) or 1;
	self:UpdateColorTextureLayout();
end

function UCBColourButtonMixin:SetColorTextureScale(scale)
	self:SetColourTextureScale(scale);
end

function UCBColourButtonMixin:SetHoverTextStyle(enabled)
	local text = self:GetFontString()
	if not text then
		return
	end

	local font, size, flags = text:GetFont()
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