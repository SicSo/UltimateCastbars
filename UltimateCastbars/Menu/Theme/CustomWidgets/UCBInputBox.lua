UCBInputBoxMixin = {}

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
	elseif isMiddle and info.texCoord then
		region:SetTexCoord(unpack(info.texCoord));
	end

	if isMiddle then
		region:SetHorizTile(true);
		region:SetVertTile(false);
	end
end

local function GetTextureAspectWidthFromHeight(fileWidth, fileHeight, targetHeight)
	if not fileWidth or not fileHeight or fileHeight == 0 or not targetHeight then
		return nil;
	end

	return (fileWidth / fileHeight) * targetHeight;
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
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\EditBox\\SmallLeft.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 850,
				fileHeight = 599,
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\EditBox\\SmallMid.png",
				texCoord = { 0.75, 1, 0, 1 },
				fileWidth = 3607,
				fileHeight = 599,
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\EditBox\\SmallRight.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 850,
				fileHeight = 599,
			},
		},

		active = {
			left = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\EditBox\\SmallLeftHover.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 850,
				fileHeight = 599,
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\EditBox\\SmallMidHover.png",
				texCoord = { 0.75, 1, 0, 1 },
				fileWidth = 3607,
				fileHeight = 599,
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\EditBox\\SmallRightHover.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 850,
				fileHeight = 599,
			},
		},

		disabled = {
			left = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\EditBox\\SmallLeftDisabled.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 850,
				fileHeight = 599,
			},
			middle = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\EditBox\\SmallMidDisabled.png",
				texCoord = { 0.75, 1, 0, 1 },
				fileWidth = 3607,
				fileHeight = 599,
			},
			right = {
				file = "Interface\\AddOns\\UltimateCastbars\\gfx\\UITextures\\EditBox\\SmallRightDisabled.png",
				texCoord = { 0, 1, 0, 1 },
				fileWidth = 850,
				fileHeight = 599,
			},
		},
	};

	self:UpdateVisualState();
end

function UCBInputBoxMixin:OnSizeChanged()
	self:SyncSideWidthsFromHeight();
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

function UCBInputBoxMixin:GetCurrentStateData()
	local stateName = self:GetTextureState();
	return self.textureStates and self.textureStates[stateName];
end

function UCBInputBoxMixin:SyncSideWidthsFromHeight()
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
end

function UCBInputBoxMixin:UpdateVisualState()
	local state = self:GetCurrentStateData();
	if not state then
		return;
	end

	ApplyRegionTexture(self.Left, state.left);
	ApplyRegionTexture(self.Middle, state.middle);
	ApplyRegionTexture(self.Right, state.right);

	self:SyncSideWidthsFromHeight();
end