UCB_BlackThreeSliceMixin = {}

local function ParseCoords(coords)
    if type(coords) == "table" then
        return coords
    end

    assert(type(coords) == "string", "coords must be a string or table")

    local left, right, top, bottom =
        coords:match("^%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*$")

    assert(left and right and top and bottom, "Invalid coord string: " .. tostring(coords))

    return {
        tonumber(left),
        tonumber(right),
        tonumber(top),
        tonumber(bottom),
    }
end

local function CopyCoords(coords)
    return { coords[1], coords[2], coords[3], coords[4] }
end

function UCB_BlackThreeSliceMixin:GetCoordsForState(state)
    if not self:IsEnabled() then
        state = "DISABLED"
    end

    if state == "PUSHED" then
        return self.pressedLeft, self.pressedCenter, self.pressedRight
    elseif state == "DISABLED" then
        return self.disabledLeft, self.disabledCenter, self.disabledRight
    end

    return self.normalLeft, self.normalCenter, self.normalRight
end

function UCB_BlackThreeSliceMixin:ApplyRegion(tex, coords, logicalWidth)
    tex:SetTexture(self.file)
    tex:SetTexCoord(unpack(coords))
    tex:SetSize(logicalWidth, self.artHeight)
    tex:SetScale(1)
end

function UCB_BlackThreeSliceMixin:UpdateScale()
    local buttonWidth = self:GetWidth()
    local buttonHeight = self:GetHeight()

    if not self.artHeight or self.artHeight <= 0 then
        return
    end

    local scale = buttonHeight / self.artHeight

    self.Left:SetScale(scale)
    self.Right:SetScale(scale)
	self.Highlight:SetScale(scale)

    local leftWidth = self.leftWidth * scale
    local rightWidth = self.rightWidth * scale
    local totalCapWidth = leftWidth + rightWidth

    local leftCoords = self.currentLeftCoords or self.normalLeft
    local centerCoords = self.currentCenterCoords or self.normalCenter
    local rightCoords = self.currentRightCoords or self.normalRight

    if totalCapWidth > buttonWidth then
        local overflow = totalCapWidth - buttonWidth
        local newLeftWidth = leftWidth
        local newRightWidth = rightWidth

        if (leftWidth - overflow) > rightWidth then
            newLeftWidth = leftWidth - overflow
        elseif (rightWidth - overflow) > leftWidth then
            newRightWidth = rightWidth - overflow
        else
            if leftWidth ~= rightWidth then
                local unevenAmount = math.abs(leftWidth - rightWidth)
                overflow = overflow - unevenAmount
                newLeftWidth = math.min(leftWidth, rightWidth)
                newRightWidth = newLeftWidth
            end

            local splitOverflow = overflow / 2
            newLeftWidth = newLeftWidth - splitOverflow
            newRightWidth = newRightWidth - splitOverflow
        end

        newLeftWidth = math.max(0, newLeftWidth)
        newRightWidth = math.max(0, newRightWidth)

        local leftPercentage = (leftWidth > 0) and (newLeftWidth / leftWidth) or 0
        local leftTrim = CopyCoords(leftCoords)
        leftTrim[2] = leftTrim[1] + ((leftTrim[2] - leftTrim[1]) * leftPercentage)
        self.Left:SetTexCoord(unpack(leftTrim))
        self.Left:SetWidth(newLeftWidth / scale)

        local rightPercentage = (rightWidth > 0) and (newRightWidth / rightWidth) or 0
        local rightTrim = CopyCoords(rightCoords)
        rightTrim[1] = rightTrim[2] - ((rightTrim[2] - rightTrim[1]) * rightPercentage)
        self.Right:SetTexCoord(unpack(rightTrim))
        self.Right:SetWidth(newRightWidth / scale)

        leftWidth = newLeftWidth
        rightWidth = newRightWidth
    else
        self.Left:SetTexCoord(unpack(leftCoords))
        self.Left:SetWidth(self.leftWidth)

        self.Right:SetTexCoord(unpack(rightCoords))
        self.Right:SetWidth(self.rightWidth)
    end

    local centerWidthOnScreen = math.max(0, buttonWidth - leftWidth - rightWidth)
    local centerSourceWidth = self.centerWidth

    if centerSourceWidth and centerSourceWidth > 0 then
        local repeatCount = centerWidthOnScreen / centerSourceWidth
        local u1 = centerCoords[1]
        local u2 = u1 + ((centerCoords[2] - centerCoords[1]) * repeatCount)
        self.Center:SetTexCoord(u1, u2, centerCoords[3], centerCoords[4])
    else
        self.Center:SetTexCoord(unpack(centerCoords))
    end
end

function UCB_BlackThreeSliceMixin:UpdateButton(state)
    state = state or self:GetButtonState()

    local leftCoords, centerCoords, rightCoords = self:GetCoordsForState(state)

    self.currentState = state
    self.currentLeftCoords = leftCoords
    self.currentCenterCoords = centerCoords
    self.currentRightCoords = rightCoords

    self:ApplyRegion(self.Left, leftCoords, self.leftWidth)
    self:ApplyRegion(self.Right, rightCoords, self.rightWidth)

    self.Center:SetTexture(self.file)
    self.Center:SetTexCoord(unpack(centerCoords))
    self.Center:SetVertTile(false)
    self.Center:SetHorizTile(true)

    self:UpdateScale()
end

function UCB_BlackThreeSliceMixin:InitButton()
    self.normalLeft = ParseCoords(self.normalLeft)
    self.normalCenter = ParseCoords(self.normalCenter)
    self.normalRight = ParseCoords(self.normalRight)

    self.pressedLeft = ParseCoords(self.pressedLeft)
    self.pressedCenter = ParseCoords(self.pressedCenter)
    self.pressedRight = ParseCoords(self.pressedRight)

    self.disabledLeft = ParseCoords(self.disabledLeft)
    self.disabledCenter = ParseCoords(self.disabledCenter)
    self.disabledRight = ParseCoords(self.disabledRight)

    self.highlightTexCoords = ParseCoords(self.highlightTexCoords)

    self.leftWidth = tonumber(self.leftWidth) or 114
    self.centerWidth = tonumber(self.centerWidth) or 64
    self.rightWidth = tonumber(self.rightWidth) or 292
    self.artHeight = tonumber(self.artHeight) or 128

	self.highlightWidth = tonumber(self.highlightWidth) or 441
	self.highlightHeight = tonumber(self.highlightHeight) or 128

	self.Highlight:SetTexture(self.fileRed)
	self.Highlight:SetTexCoord(unpack(self.highlightTexCoords))

	self.Highlight:SetBlendMode("ADD")
	self.Highlight:SetDesaturated(true)
	self.Highlight:SetVertexColor(1, 0.82, 0.0, 1)

	self.Highlight:SetSize(self:GetWidth(), self:GetHeight())
	self.Highlight:ClearAllPoints()
	self.Highlight:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    self.Highlight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
	--self.Highlight:SetPoint("CENTER", self, "CENTER")
	self.Highlight:Hide()
end

function UCB_BlackThreeSliceMixin:OnLoad()
    self:InitButton()
    self:EnableMouse(true)
    self:UpdateButton("NORMAL")
end

function UCB_BlackThreeSliceMixin:OnSizeChanged()
    self:UpdateScale()
end

function UCB_BlackThreeSliceMixin:OnEnable()
    self:UpdateButton("NORMAL")
end

function UCB_BlackThreeSliceMixin:OnDisable()
    self:UpdateButton("DISABLED")
end

function UCB_BlackThreeSliceMixin:OnMouseDown()
    self:UpdateButton("PUSHED")
end

function UCB_BlackThreeSliceMixin:OnMouseUp()
    self:UpdateButton("NORMAL")
end

function UCB_BlackThreeSliceMixin:OnEnter()
    self.Highlight:Show()
end

function UCB_BlackThreeSliceMixin:OnLeave()
    self.Highlight:Hide()
end