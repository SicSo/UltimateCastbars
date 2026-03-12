UCBInputBoxMixin = {};

local function ApplyRegionTexture(region, info)
	if not region or not info then
		return;
	end

	if info.file then
		region:SetTexture(info.file);
	end

	if info.texCoord then
		region:SetTexCoord(unpack(info.texCoord));
	elseif info.pixelTexCoord and info.textureSize then
		local texWidth = info.textureSize[1];
		local texHeight = info.textureSize[2];
		local l, r, t, b = unpack(info.pixelTexCoord);

		region:SetTexCoord(
			l / texWidth,
			r / texWidth,
			t / texHeight,
			b / texHeight
		);
	end

	if region == region:GetParent().Middle then
		region:SetHorizTile(true);
		region:SetVertTile(false);
	end
end

function UCBInputBoxMixin:OnLoad()
	if self.Middle then
		self.Middle:SetHorizTile(true);
		self.Middle:SetVertTile(false);
	end

	self.__ucbHovered = false;
	self.__ucbFocused = false;

	self.textureStates = self.textureStates or {
		normal = {
			left = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\SmallLeftNormal.png",
				texCoord = { 0, 1, 0, 1 },
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\SmallMidNormal.png",
				texCoord = { 0, 0.25, 0, 1 },
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\SmallRightNormal.png",
				texCoord = { 0, 1, 0, 1 },
			},
		},

		active = {
			left = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\SmallLeftGlow.png",
				texCoord = { 0, 1, 0, 1 },
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\SmallMidGlow.png",
				texCoord = { 0, 0.25, 0, 1 },
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\SmallRightGlow.png",
				texCoord = { 0, 1, 0, 1 },
			},
		},

		disabled = {
			left = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\SmallLeftDisabled.png",
				texCoord = { 0, 1, 0, 1 },
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\SmallMidDisabled.png",
				texCoord = { 0, 0.25, 0, 1 },
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\InputBox\\SmallRightDisabled.png",
				texCoord = { 0, 1, 0, 1 },
			},
		},
	};

	self:UpdateVisualState();
end

function UCBInputBoxMixin:OnEnable()
	self:UpdateVisualState();
end

function UCBInputBoxMixin:OnDisable()
	self.__ucbHovered = false;
	self.__ucbFocused = false;
	self:UpdateVisualState();
end

function UCBInputBoxMixin:OnEnter()
	self.__ucbHovered = true;
	self:UpdateVisualState();
end

function UCBInputBoxMixin:OnLeave()
	self.__ucbHovered = false;
	self:UpdateVisualState();
end

function UCBInputBoxMixin:OnEditFocusGained()
	self.__ucbFocused = true;
	self:UpdateVisualState();
end

function UCBInputBoxMixin:OnEditFocusLost()
	self.__ucbFocused = false;
	self:UpdateVisualState();
end

function UCBInputBoxMixin:UpdateVisualState()
	local stateName = self:GetTextureState();
	local state = self.textureStates and self.textureStates[stateName];
	if not state then
		return;
	end

	if self.Left and state.left and state.left.file then
		self.Left:SetTexture(state.left.file);
		if state.left.texCoord then
			self.Left:SetTexCoord(unpack(state.left.texCoord));
		end
	end

	if self.Middle and state.middle and state.middle.file then
		self.Middle:SetTexture(state.middle.file);
		if state.middle.texCoord then
			self.Middle:SetTexCoord(unpack(state.middle.texCoord));
		end
		self.Middle:SetHorizTile(true);
		self.Middle:SetVertTile(false);
	end

	if self.Right and state.right and state.right.file then
		self.Right:SetTexture(state.right.file);
		if state.right.texCoord then
			self.Right:SetTexCoord(unpack(state.right.texCoord));
		end
	end
end

function UCBInputBoxMixin:SetTextures(leftFile, middleFile, rightFile)
	if leftFile and self.Left then
		self.Left:SetTexture(leftFile);
	end

	if middleFile and self.Middle then
		self.Middle:SetTexture(middleFile);
		self.Middle:SetHorizTile(true);
		self.Middle:SetVertTile(false);
	end

	if rightFile and self.Right then
		self.Right:SetTexture(rightFile);
	end
end

function UCBInputBoxMixin:SetLeftTexCoord(left, right, top, bottom)
	if self.Left then
		self.Left:SetTexCoord(left, right, top, bottom);
	end
end

function UCBInputBoxMixin:SetRightTexCoord(left, right, top, bottom)
	if self.Right then
		self.Right:SetTexCoord(left, right, top, bottom);
	end
end

function UCBInputBoxMixin:SetMiddleTexCoord(left, right, top, bottom)
	if self.Middle then
		self.Middle:SetTexCoord(left, right, top, bottom);
		self.Middle:SetHorizTile(true);
		self.Middle:SetVertTile(false);
	end
end

function UCBInputBoxMixin:SetLeftTexCoordPixels(textureWidth, textureHeight, left, right, top, bottom)
	if self.Left then
		self.Left:SetTexCoord(
			left / textureWidth,
			right / textureWidth,
			top / textureHeight,
			bottom / textureHeight
		);
	end
end

function UCBInputBoxMixin:SetRightTexCoordPixels(textureWidth, textureHeight, left, right, top, bottom)
	if self.Right then
		self.Right:SetTexCoord(
			left / textureWidth,
			right / textureWidth,
			top / textureHeight,
			bottom / textureHeight
		);
	end
end

function UCBInputBoxMixin:SetMiddleTexCoordPixels(textureWidth, textureHeight, left, right, top, bottom)
	if self.Middle then
		self.Middle:SetTexCoord(
			left / textureWidth,
			right / textureWidth,
			top / textureHeight,
			bottom / textureHeight
		);
		self.Middle:SetHorizTile(true);
		self.Middle:SetVertTile(false);
	end
end

function UCBInputBoxMixin:SetSideWidths(leftWidth, rightWidth)
	if self.Left and leftWidth then
		self.Left:SetWidth(leftWidth)
	end

	if self.Right and rightWidth then
		self.Right:SetWidth(rightWidth)
	end
end

function UCBInputBoxMixin:SetupTextures(textureInfo)
	if not textureInfo then
		return;
	end

	self:SetTextures(
		textureInfo.leftFile,
		textureInfo.middleFile,
		textureInfo.rightFile
	);

	if textureInfo.leftTexCoord and self.Left then
		self.Left:SetTexCoord(unpack(textureInfo.leftTexCoord));
	end

	if textureInfo.rightTexCoord and self.Right then
		self.Right:SetTexCoord(unpack(textureInfo.rightTexCoord));
	end

	if textureInfo.middleTexCoord and self.Middle then
		self.Middle:SetTexCoord(unpack(textureInfo.middleTexCoord));
		self.Middle:SetHorizTile(true);
		self.Middle:SetVertTile(false);
	end

	if textureInfo.middlePixelTexCoord and textureInfo.middleTextureSize and self.Middle then
		local texWidth = textureInfo.middleTextureSize[1];
		local texHeight = textureInfo.middleTextureSize[2];
		local l, r, t, b = unpack(textureInfo.middlePixelTexCoord);

		self:SetMiddleTexCoordPixels(texWidth, texHeight, l, r, t, b);
	end
end

function UCBInputBoxMixin:SetupTextureStates(textureStates)
	if not textureStates then
		return;
	end

	self.textureStates = textureStates;
	self:UpdateVisualState();
end

function UCBInputBoxMixin:SetForcedTextureState(state)
	self._forcedTextureState = state;
	self:UpdateVisualState();
end

function UCBInputBoxMixin:ClearForcedTextureState()
	self._forcedTextureState = nil;
	self:UpdateVisualState();
end

function UCBInputBoxMixin:GetTextureState()
	if not self:IsEnabled() then
		return "disabled";
	end

	if self._forcedTextureState then
		return self._forcedTextureState;
	end

	if self.__ucbFocused or self.__ucbHovered then
		return "active";
	end

	return "normal";
end

function UCBInputBoxMixin:SyncSideWidthsToHeight(leftTextureWidth, leftTextureHeight, rightTextureWidth, rightTextureHeight)
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

function UCBInputBoxMixin:SyncUniformSideWidthsToHeight(textureWidth, textureHeight)
	self:SyncSideWidthsToHeight(textureWidth, textureHeight, textureWidth, textureHeight);
end