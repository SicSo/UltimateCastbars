-- UCB_CustomColorPicker.lua
local ADDON, UCB = ...

UCB.UIOptions = UCB.UIOptions or {}

local GUI = UCB.GUI
local UIOptions = UCB.UIOptions
local GetCfg = UCB.GetValueConfig

local testFrame = nil

local C_BG = {r = 0.1, g = 0.1, b = 0.1}
local C_ELEMENT = {r = 0.18, g = 0.18, b = 0.18}
local C_BORDER = {r = 0.25, g = 0.25, b = 0.25}
local C_ACCENT = {r = 0.45, g = 0.45, b = 0.95}
local C_TEXT = {r = 0.9, g = 0.9, b = 0.9}
local C_TEXT_DIM = {r = 0.5, g = 0.5, b = 0.5}

local savedColors, recentColors, preferSquarePicker

local savedPosition = nil
local MAX_RECENT = 27
local MAX_SAVED = 27

local SWATCH_SIZE = 30
local SWATCH_GAP = 2
local SWATCHES_PER_ROW = 9

local function LoadSavedColors()
    local cfg = GetCfg()
    local colorPickerConfig = cfg.misc.colourPicker
    savedColors = colorPickerConfig.savedColours or {}
    recentColors = colorPickerConfig.recentColours or {}
    preferSquarePicker = colorPickerConfig.squarePicker
end

local function SaveColorsToDb()
    local cfg = GetCfg()
    local colorPickerConfig = cfg.misc.colourPicker
    colorPickerConfig.savedColours = savedColors
    colorPickerConfig.recentColours = recentColors
    colorPickerConfig.squarePicker = preferSquarePicker
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == ADDON then
        LoadSavedColors()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

local function ColorKey(r, g, b, a)
    return string.format("%.2f,%.2f,%.2f,%.2f", r, g, b, a or 1)
end

local function HSVtoRGB(h, s, v)
    if s == 0 then return v, v, v end
    h = h / 60
    local i = math.floor(h)
    local f = h - i
    local p = v * (1 - s)
    local q = v * (1 - s * f)
    local t = v * (1 - s * (1 - f))
    i = i % 6
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    else return v, p, q end
end

local function RGBtoHSV(r, g, b)
    local maxv = math.max(r, g, b)
    local minv = math.min(r, g, b)
    local h, s, v = 0, 0, maxv
    local d = maxv - minv
    if maxv ~= 0 then s = d / maxv end
    if maxv ~= minv then
        if maxv == r then
            h = (g - b) / d
            if g < b then h = h + 6 end
        elseif maxv == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h * 60
    end
    return h, s, v
end

local function RGBtoHex(r, g, b, a)
    if a ~= nil then
        return string.format(
            "#%02X%02X%02X%02X",
            math.floor(r * 255 + 0.5),
            math.floor(g * 255 + 0.5),
            math.floor(b * 255 + 0.5),
            math.floor(a * 255 + 0.5)
        )
    end

    return string.format(
        "#%02X%02X%02X",
        math.floor(r * 255 + 0.5),
        math.floor(g * 255 + 0.5),
        math.floor(b * 255 + 0.5)
    )
end

local function HexToRGB(hex)
    hex = (hex or ""):gsub("#", "")
    if #hex == 8 then
        local r = tonumber(hex:sub(1, 2), 16) / 255
        local g = tonumber(hex:sub(3, 4), 16) / 255
        local b = tonumber(hex:sub(5, 6), 16) / 255
        local a = tonumber(hex:sub(7, 8), 16) / 255
        return r or 1, g or 1, b or 1, a or 1
    elseif #hex == 6 then
        local r = tonumber(hex:sub(1, 2), 16) / 255
        local g = tonumber(hex:sub(3, 4), 16) / 255
        local b = tonumber(hex:sub(5, 6), 16) / 255
        return r or 1, g or 1, b or 1, nil
    end
    return 1, 1, 1, nil
end

local function CreateColorPicker(hasAlpha)
    if testFrame then
        testFrame.hasAlpha = hasAlpha
        testFrame:UpdateAlphaVisibility()
        if testFrame.RefreshSavedSwatches then
            testFrame.RefreshSavedSwatches()
        end
        if testFrame.RefreshRecentSwatches then
            testFrame.RefreshRecentSwatches()
        end
        return testFrame
    end

    hasAlpha = hasAlpha ~= false

    local currentHue = 0
    local currentSat = 1
    local currentVal = 1
    local currentAlpha = 1
    local activeTab = "saved"
    local useSquarePicker = preferSquarePicker
    local isUpdatingInputs = false

    testFrame = CreateFrame("Frame", "UCBColorPickerFrame", UIParent, "BackdropTemplate")
    testFrame:SetSize(320, 450)
    testFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    testFrame:SetBackdropColor(C_BG.r, C_BG.g, C_BG.b, 1)
    testFrame:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)
    testFrame:SetMovable(true)
    testFrame:EnableMouse(true)
    testFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    testFrame:SetFrameLevel(500)
    testFrame:SetToplevel(true)
    testFrame.hasAlpha = hasAlpha

    local function UpdatePosition()
        testFrame:ClearAllPoints()
        if savedPosition then
            testFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", savedPosition.x, savedPosition.y)
        else
            testFrame:SetPoint("CENTER")
        end
    end

    local function SavePosition()
        local left = testFrame:GetLeft()
        local bottom = testFrame:GetBottom()
        local width = testFrame:GetWidth()
        local height = testFrame:GetHeight()
        if left and bottom and width and height then
            savedPosition = {
                x = left + width / 2,
                y = bottom + height / 2,
            }
        end
    end

    testFrame.UpdatePosition = UpdatePosition
    testFrame.SavePosition = SavePosition
    UpdatePosition()

    tinsert(UISpecialFrames, "UCBColorPickerFrame")

    testFrame.appliedColor = false
    testFrame:SetScript("OnHide", function(self)
        if not self.appliedColor and self.onCancelCallback then
            self.onCancelCallback()
        end
        self.appliedColor = false
        self.skipOnChange = false
        self:ClearCallbacks()
    end)

    local header = CreateFrame("Frame", nil, testFrame)
    header:SetHeight(28)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() testFrame:StartMoving() end)
    header:SetScript("OnDragStop", function()
        testFrame:StopMovingOrSizing()
        SavePosition()
    end)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", 10, 0)
    title:SetText("UltimateCastbars Color Picker")
    title:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b)

    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", -4, 0)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER")
    closeText:SetText("×")
    closeText:SetTextColor(0.6, 0.6, 0.6)
    closeBtn:SetScript("OnClick", function() testFrame:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeText:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function() closeText:SetTextColor(0.6, 0.6, 0.6) end)

    local pillContainer = CreateFrame("Frame", nil, header, "BackdropTemplate")
    pillContainer:SetSize(110, 18)
    pillContainer:SetPoint("RIGHT", closeBtn, "LEFT", -8, 0)
    pillContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    pillContainer:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)
    pillContainer:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)

    local squareBtn = CreateFrame("Button", nil, pillContainer, "BackdropTemplate")
    squareBtn:SetSize(54, 16)
    squareBtn:SetPoint("LEFT", 1, 0)
    squareBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })

    local squareBtnText = squareBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    squareBtnText:SetPoint("CENTER")
    squareBtnText:SetText("Square")

    local circleBtn = CreateFrame("Button", nil, pillContainer, "BackdropTemplate")
    circleBtn:SetSize(54, 16)
    circleBtn:SetPoint("RIGHT", -1, 0)
    circleBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })

    local circleBtnText = circleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    circleBtnText:SetPoint("CENTER")
    circleBtnText:SetText("Circle")

    local content = CreateFrame("Frame", nil, testFrame)
    content:SetPoint("TOPLEFT", 10, -38)
    content:SetPoint("BOTTOMRIGHT", -10, 45)

    local squareSize = 160
    local hueBarWidth = 20
    local alphaBarWidth = 20

    local squareContainer = CreateFrame("Frame", nil, content)
    squareContainer:SetSize(290, 170)
    squareContainer:SetPoint("TOPLEFT", 0, 0)

    local squareFrame = CreateFrame("Frame", nil, squareContainer, "BackdropTemplate")
    squareFrame:SetSize(squareSize, squareSize)
    squareFrame:SetPoint("TOPLEFT", 0, 0)
    squareFrame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    squareFrame:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)

    local hueLayer = squareFrame:CreateTexture(nil, "BACKGROUND")
    hueLayer:SetAllPoints()
    hueLayer:SetColorTexture(1, 1, 1, 1)

    local blackLayer = squareFrame:CreateTexture(nil, "ARTWORK")
    blackLayer:SetAllPoints()
    blackLayer:SetColorTexture(1, 1, 1, 1)
    blackLayer:SetGradient("VERTICAL", CreateColor(0, 0, 0, 1), CreateColor(0, 0, 0, 0))

    local picker = squareFrame:CreateTexture(nil, "OVERLAY")
    picker:SetSize(14, 14)
    picker:SetTexture("Interface\\Buttons\\UI-ColorPicker-Buttons")
    picker:SetTexCoord(0, 0.15625, 0, 0.625)

    local hueBar = CreateFrame("Frame", nil, squareContainer, "BackdropTemplate")
    hueBar:SetSize(hueBarWidth, squareSize)
    hueBar:SetPoint("LEFT", squareFrame, "RIGHT", 8, 0)
    hueBar:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    hueBar:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)

    local hueColors = {{1,0,0}, {1,1,0}, {0,1,0}, {0,1,1}, {0,0,1}, {1,0,1}, {1,0,0}}
    local numSegments = 6
    local segmentHeight = squareSize / numSegments
    for i = 1, numSegments do
        local segment = hueBar:CreateTexture(nil, "BACKGROUND")
        segment:SetSize(hueBarWidth, segmentHeight)
        segment:SetPoint("TOPLEFT", 0, -((i - 1) * segmentHeight))
        segment:SetColorTexture(1, 1, 1, 1)
        local c1, c2 = hueColors[i], hueColors[i + 1]
        segment:SetGradient("VERTICAL", CreateColor(c2[1], c2[2], c2[3], 1), CreateColor(c1[1], c1[2], c1[3], 1))
    end

    local hueIndicator = hueBar:CreateTexture(nil, "OVERLAY", nil, 2)
    hueIndicator:SetSize(hueBarWidth + 4, 6)
    hueIndicator:SetColorTexture(1, 1, 1, 1)

    local hueIndicatorBorder = hueBar:CreateTexture(nil, "OVERLAY", nil, 1)
    hueIndicatorBorder:SetSize(hueBarWidth + 6, 8)
    hueIndicatorBorder:SetColorTexture(0, 0, 0, 1)

    local alphaBar = CreateFrame("Frame", nil, squareContainer, "BackdropTemplate")
    alphaBar:SetSize(alphaBarWidth, squareSize)
    alphaBar:SetPoint("LEFT", hueBar, "RIGHT", 8, 0)
    alphaBar:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    alphaBar:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)

    local checkerSize = 8
    local checkerWidth = alphaBarWidth - 2
    local checkerHeight = squareSize - 2
    for row = 0, math.ceil(checkerHeight / checkerSize) - 1 do
        for col = 0, math.ceil(checkerWidth / checkerSize) - 1 do
            local checker = alphaBar:CreateTexture(nil, "BACKGROUND")
            local w = math.min(checkerSize, checkerWidth - col * checkerSize)
            local h = math.min(checkerSize, checkerHeight - row * checkerSize)
            checker:SetSize(w, h)
            checker:SetPoint("TOPLEFT", 1 + col * checkerSize, -1 - row * checkerSize)
            local isLight = (row + col) % 2 == 0
            checker:SetColorTexture(isLight and 0.4 or 0.2, isLight and 0.4 or 0.2, isLight and 0.4 or 0.2, 1)
        end
    end

    local alphaGradient = alphaBar:CreateTexture(nil, "ARTWORK")
    alphaGradient:SetPoint("TOPLEFT", 1, -1)
    alphaGradient:SetPoint("BOTTOMRIGHT", -1, 1)
    alphaGradient:SetColorTexture(1, 1, 1, 1)

    local alphaIndicator = alphaBar:CreateTexture(nil, "OVERLAY", nil, 2)
    alphaIndicator:SetSize(alphaBarWidth + 4, 6)
    alphaIndicator:SetColorTexture(1, 1, 1, 1)

    local alphaIndicatorBorder = alphaBar:CreateTexture(nil, "OVERLAY", nil, 1)
    alphaIndicatorBorder:SetSize(alphaBarWidth + 6, 8)
    alphaIndicatorBorder:SetColorTexture(0, 0, 0, 1)

    local circleContainer = CreateFrame("Frame", nil, content)
    circleContainer:SetSize(290, 170)
    circleContainer:SetPoint("TOPLEFT", 0, 0)
    circleContainer:Hide()

    local wheelFrame = CreateFrame("Frame", nil, circleContainer)
    wheelFrame:SetSize(squareSize, squareSize)
    wheelFrame:SetPoint("TOPLEFT", 0, 0)

    local wheelTexture = wheelFrame:CreateTexture(nil, "ARTWORK")
    wheelTexture:SetTexture("Interface\\AddOns\\DandersFrames\\Media\\DF_ColorWheel")
    wheelTexture:SetAllPoints()
    wheelTexture:SetTexelSnappingBias(0)
    wheelTexture:SetSnapToPixelGrid(false)

    local wheelThumb = CreateFrame("Frame", nil, wheelFrame)
    wheelThumb:SetSize(16, 16)
    wheelThumb:SetFrameLevel(wheelFrame:GetFrameLevel() + 5)
    local thumbRing = wheelThumb:CreateTexture(nil, "OVERLAY", nil, 2)
    thumbRing:SetTexture("Interface\\AddOns\\DandersFrames\\Media\\DF_Ring")
    thumbRing:SetAllPoints()

    local circleValueBar = CreateFrame("Frame", nil, circleContainer, "BackdropTemplate")
    circleValueBar:SetSize(hueBarWidth, squareSize)
    circleValueBar:SetPoint("TOPLEFT", squareSize + 8, 0)
    circleValueBar:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    circleValueBar:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)

    local circleValueGradient = circleValueBar:CreateTexture(nil, "BACKGROUND")
    circleValueGradient:SetPoint("TOPLEFT", 1, -1)
    circleValueGradient:SetPoint("BOTTOMRIGHT", -1, 1)
    circleValueGradient:SetColorTexture(1, 1, 1, 1)

    local circleValueIndicator = circleValueBar:CreateTexture(nil, "OVERLAY", nil, 2)
    circleValueIndicator:SetSize(hueBarWidth + 4, 6)
    circleValueIndicator:SetColorTexture(1, 1, 1, 1)

    local circleValueIndicatorBorder = circleValueBar:CreateTexture(nil, "OVERLAY", nil, 1)
    circleValueIndicatorBorder:SetSize(hueBarWidth + 6, 8)
    circleValueIndicatorBorder:SetColorTexture(0, 0, 0, 1)

    local circleAlphaBar = CreateFrame("Frame", nil, circleContainer, "BackdropTemplate")
    circleAlphaBar:SetSize(alphaBarWidth, squareSize)
    circleAlphaBar:SetPoint("LEFT", circleValueBar, "RIGHT", 8, 0)
    circleAlphaBar:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    circleAlphaBar:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)

    for row = 0, math.ceil(checkerHeight / checkerSize) - 1 do
        for col = 0, math.ceil(checkerWidth / checkerSize) - 1 do
            local checker = circleAlphaBar:CreateTexture(nil, "BACKGROUND")
            local w = math.min(checkerSize, checkerWidth - col * checkerSize)
            local h = math.min(checkerSize, checkerHeight - row * checkerSize)
            checker:SetSize(w, h)
            checker:SetPoint("TOPLEFT", 1 + col * checkerSize, -1 - row * checkerSize)
            local isLight = (row + col) % 2 == 0
            checker:SetColorTexture(isLight and 0.4 or 0.2, isLight and 0.4 or 0.2, isLight and 0.4 or 0.2, 1)
        end
    end

    local circleAlphaGradient = circleAlphaBar:CreateTexture(nil, "ARTWORK")
    circleAlphaGradient:SetPoint("TOPLEFT", 1, -1)
    circleAlphaGradient:SetPoint("BOTTOMRIGHT", -1, 1)
    circleAlphaGradient:SetColorTexture(1, 1, 1, 1)

    local circleAlphaIndicator = circleAlphaBar:CreateTexture(nil, "OVERLAY", nil, 2)
    circleAlphaIndicator:SetSize(alphaBarWidth + 4, 6)
    circleAlphaIndicator:SetColorTexture(1, 1, 1, 1)

    local circleAlphaIndicatorBorder = circleAlphaBar:CreateTexture(nil, "OVERLAY", nil, 1)
    circleAlphaIndicatorBorder:SetSize(alphaBarWidth + 6, 8)
    circleAlphaIndicatorBorder:SetColorTexture(0, 0, 0, 1)

    local previewFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    previewFrame:SetSize(55, 55)
    previewFrame:SetPoint("TOPLEFT", squareContainer, "TOPRIGHT", -50, 0)
    previewFrame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    previewFrame:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)

    local previewInner = 53
    for row = 0, math.ceil(previewInner / 8) - 1 do
        for col = 0, math.ceil(previewInner / 8) - 1 do
            local checker = previewFrame:CreateTexture(nil, "BACKGROUND")
            local w = math.min(8, previewInner - col * 8)
            local h = math.min(8, previewInner - row * 8)
            checker:SetSize(w, h)
            checker:SetPoint("TOPLEFT", 1 + col * 8, -1 - row * 8)
            local isLight = (row + col) % 2 == 0
            checker:SetColorTexture(isLight and 0.4 or 0.2, isLight and 0.4 or 0.2, isLight and 0.4 or 0.2, 1)
        end
    end

    local previewTexture = previewFrame:CreateTexture(nil, "ARTWORK")
    previewTexture:SetPoint("TOPLEFT", 1, -1)
    previewTexture:SetPoint("BOTTOMRIGHT", -1, 1)

    local inputFrame = CreateFrame("Frame", nil, content)
    inputFrame:SetSize(290, 24)
    inputFrame:SetPoint("TOPLEFT", squareContainer, "BOTTOMLEFT", 0, -8)

    local function CreateRGBAInput(parent, label, color, xOffset, width)
        local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        container:SetSize(width, 22)
        container:SetPoint("LEFT", xOffset, 0)
        container:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        container:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)

        local lbl = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", 4, 0)
        lbl:SetText(label)
        lbl:SetTextColor(color.r, color.g, color.b)

        local editBox = CreateFrame("EditBox", nil, container)
        editBox:SetSize(width - 22, 18)
        editBox:SetPoint("LEFT", lbl, "RIGHT", 2, 0)
        editBox:SetFontObject("GameFontNormalSmall")
        editBox:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
        editBox:SetAutoFocus(false)
        editBox:SetNumeric(true)
        editBox:SetMaxLetters(3)
        editBox:SetJustifyH("LEFT")
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        return editBox
    end

    local rInput = CreateRGBAInput(inputFrame, "R", {r=1, g=0.4, b=0.4}, 0, 60)
    local gInput = CreateRGBAInput(inputFrame, "G", {r=0.4, g=1, b=0.4}, 64, 60)
    local bInput = CreateRGBAInput(inputFrame, "B", {r=0.4, g=0.6, b=1}, 128, 60)
    local aInput = CreateRGBAInput(inputFrame, "A%", {r=0.8, g=0.8, b=0.8}, 192, 60)
    aInput:GetParent().alphaInput = true

    local hexFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    hexFrame:SetSize(118, 22)
    hexFrame:SetPoint("TOPLEFT", inputFrame, "BOTTOMLEFT", 0, -4)
    hexFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    hexFrame:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)

    local hexLabel = hexFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hexLabel:SetPoint("LEFT", 4, 0)
    hexLabel:SetText("Hex")
    hexLabel:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)

    local hexInput = CreateFrame("EditBox", nil, hexFrame)
    hexInput:SetSize(90, 18)
    hexInput:SetPoint("LEFT", hexLabel, "RIGHT", 4, 0)
    hexInput:SetFontObject("GameFontNormalSmall")
    hexInput:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)
    hexInput:SetAutoFocus(false)
    hexInput:SetMaxLetters(9)
    hexInput:SetJustifyH("LEFT")
    hexInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local function UpdateHueGradient()
        local r, g, b = HSVtoRGB(currentHue, 1, 1)
        hueLayer:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 1), CreateColor(r, g, b, 1))
    end

    local function UpdateAlphaGradient()
        local r, g, b = HSVtoRGB(currentHue, currentSat, currentVal)
        alphaGradient:SetGradient("VERTICAL", CreateColor(r, g, b, 0), CreateColor(r, g, b, 1))
        circleAlphaGradient:SetGradient("VERTICAL", CreateColor(r, g, b, 0), CreateColor(r, g, b, 1))
    end

    local function UpdatePickerPosition()
        local x = currentSat * squareSize
        local y = currentVal * squareSize
        picker:ClearAllPoints()
        picker:SetPoint("CENTER", squareFrame, "BOTTOMLEFT", x, y)
    end

    local function UpdateHueIndicator()
        local y = (currentHue / 360) * squareSize
        hueIndicator:ClearAllPoints()
        hueIndicator:SetPoint("CENTER", hueBar, "TOP", 0, -y)
        hueIndicatorBorder:ClearAllPoints()
        hueIndicatorBorder:SetPoint("CENTER", hueIndicator)
    end

    local function UpdateAlphaIndicator()
        local y = (1 - currentAlpha) * squareSize
        alphaIndicator:ClearAllPoints()
        alphaIndicator:SetPoint("CENTER", alphaBar, "TOP", 0, -y)
        alphaIndicatorBorder:ClearAllPoints()
        alphaIndicatorBorder:SetPoint("CENTER", alphaIndicator)

        circleAlphaIndicator:ClearAllPoints()
        circleAlphaIndicator:SetPoint("CENTER", circleAlphaBar, "TOP", 0, -y)
        circleAlphaIndicatorBorder:ClearAllPoints()
        circleAlphaIndicatorBorder:SetPoint("CENTER", circleAlphaIndicator)
    end

    local function UpdateCircleValueGradient()
        local r, g, b = HSVtoRGB(currentHue, currentSat, 1)
        circleValueGradient:SetGradient("VERTICAL", CreateColor(0, 0, 0, 1), CreateColor(r, g, b, 1))
    end

    local function UpdateCircleValueIndicator()
        local y = (1 - currentVal) * squareSize
        circleValueIndicator:ClearAllPoints()
        circleValueIndicator:SetPoint("CENTER", circleValueBar, "TOP", 0, -y)
        circleValueIndicatorBorder:ClearAllPoints()
        circleValueIndicatorBorder:SetPoint("CENTER", circleValueIndicator)
    end

    local function UpdateWheelThumbPosition()
        local radius = squareSize / 2
        local angle = (currentHue / 360) * 2 * math.pi - math.pi
        local dist = currentSat * radius
        local x = radius + math.cos(angle) * dist
        local y = radius + math.sin(angle) * dist
        wheelThumb:ClearAllPoints()
        wheelThumb:SetPoint("CENTER", wheelFrame, "TOPLEFT", x, -y)
    end

    local function UpdateInputs()
        if isUpdatingInputs then return end
        isUpdatingInputs = true

        local r, g, b = HSVtoRGB(currentHue, currentSat, currentVal)
        rInput:SetText(math.floor(r * 255 + 0.5))
        gInput:SetText(math.floor(g * 255 + 0.5))
        bInput:SetText(math.floor(b * 255 + 0.5))
        aInput:SetText(math.floor(currentAlpha * 100 + 0.5))

        if testFrame.hasAlpha then
            hexInput:SetText(RGBtoHex(r, g, b, currentAlpha))
        else
            hexInput:SetText(RGBtoHex(r, g, b))
        end

        isUpdatingInputs = false
    end

    local function UpdateAllColors()
        local r, g, b = HSVtoRGB(currentHue, currentSat, currentVal)
        previewTexture:SetColorTexture(r, g, b, currentAlpha)

        UpdateHueGradient()
        UpdateAlphaGradient()
        UpdatePickerPosition()
        UpdateHueIndicator()
        UpdateAlphaIndicator()
        UpdateCircleValueGradient()
        UpdateCircleValueIndicator()
        UpdateWheelThumbPosition()
        UpdateInputs()

        if testFrame.onChangeCallback and not testFrame.skipOnChange then
            testFrame.onChangeCallback({
                r = r,
                g = g,
                b = b,
                a = testFrame.hasAlpha and currentAlpha or 1,
            })
        end
    end

    local function OnRGBAInputChanged()
        if isUpdatingInputs then return end

        local r = (tonumber(rInput:GetText()) or 0) / 255
        local g = (tonumber(gInput:GetText()) or 0) / 255
        local b = (tonumber(bInput:GetText()) or 0) / 255
        local a = (tonumber(aInput:GetText()) or 100) / 100

        r = math.max(0, math.min(1, r))
        g = math.max(0, math.min(1, g))
        b = math.max(0, math.min(1, b))
        a = math.max(0, math.min(1, a))

        currentHue, currentSat, currentVal = RGBtoHSV(r, g, b)
        currentAlpha = a
        UpdateAllColors()
    end

    rInput:SetScript("OnEnterPressed", function(self) OnRGBAInputChanged(); self:ClearFocus() end)
    gInput:SetScript("OnEnterPressed", function(self) OnRGBAInputChanged(); self:ClearFocus() end)
    bInput:SetScript("OnEnterPressed", function(self) OnRGBAInputChanged(); self:ClearFocus() end)
    aInput:SetScript("OnEnterPressed", function(self) OnRGBAInputChanged(); self:ClearFocus() end)

    rInput:SetScript("OnTextChanged", function(self, userInput) if userInput then OnRGBAInputChanged() end end)
    gInput:SetScript("OnTextChanged", function(self, userInput) if userInput then OnRGBAInputChanged() end end)
    bInput:SetScript("OnTextChanged", function(self, userInput) if userInput then OnRGBAInputChanged() end end)
    aInput:SetScript("OnTextChanged", function(self, userInput) if userInput then OnRGBAInputChanged() end end)

    hexInput:SetScript("OnEnterPressed", function(self)
        if isUpdatingInputs then return end
        local hex = self:GetText()
        local r, g, b, a = HexToRGB(hex)
        currentHue, currentSat, currentVal = RGBtoHSV(r, g, b)
        if a and testFrame.hasAlpha then
            currentAlpha = a
        end
        UpdateAllColors()
        self:ClearFocus()
    end)

    hexInput:SetScript("OnTextChanged", function(self, userInput)
        if not userInput or isUpdatingInputs then return end
        local hex = self:GetText()
        if hex:match("^#%x%x%x%x%x%x") then
            local r, g, b, a = HexToRGB(hex)
            if r and g and b then
                currentHue, currentSat, currentVal = RGBtoHSV(r, g, b)
                if a and testFrame.hasAlpha then
                    currentAlpha = a
                end
                UpdateAllColors()
            end
        end
    end)

    local isDraggingSquare, isDraggingHue, isDraggingAlpha, isDraggingCircleValue = false, false, false, false

    squareFrame:EnableMouse(true)
    squareFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDraggingSquare = true
            local scale = self:GetEffectiveScale()
            local cursorX, cursorY = GetCursorPosition()
            cursorX, cursorY = cursorX / scale, cursorY / scale
            currentSat = math.max(0, math.min(1, (cursorX - self:GetLeft()) / squareSize))
            currentVal = math.max(0, math.min(1, (cursorY - self:GetBottom()) / squareSize))
            UpdateAllColors()
        end
    end)
    squareFrame:SetScript("OnMouseUp", function() isDraggingSquare = false end)
    squareFrame:SetScript("OnUpdate", function(self)
        if isDraggingSquare then
            local scale = self:GetEffectiveScale()
            local cursorX, cursorY = GetCursorPosition()
            cursorX, cursorY = cursorX / scale, cursorY / scale
            currentSat = math.max(0, math.min(1, (cursorX - self:GetLeft()) / squareSize))
            currentVal = math.max(0, math.min(1, (cursorY - self:GetBottom()) / squareSize))
            UpdateAllColors()
        end
    end)

    hueBar:EnableMouse(true)
    hueBar:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDraggingHue = true
            local scale = self:GetEffectiveScale()
            local _, cursorY = GetCursorPosition()
            cursorY = cursorY / scale
            currentHue = math.max(0, math.min(360, ((self:GetTop() - cursorY) / squareSize) * 360))
            UpdateAllColors()
        end
    end)
    hueBar:SetScript("OnMouseUp", function() isDraggingHue = false end)
    hueBar:SetScript("OnUpdate", function(self)
        if isDraggingHue then
            local scale = self:GetEffectiveScale()
            local _, cursorY = GetCursorPosition()
            cursorY = cursorY / scale
            currentHue = math.max(0, math.min(360, ((self:GetTop() - cursorY) / squareSize) * 360))
            UpdateAllColors()
        end
    end)

    local function SetupAlphaBarHandlers(bar)
        bar:EnableMouse(true)
        bar:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                isDraggingAlpha = true
                local scale = self:GetEffectiveScale()
                local _, cursorY = GetCursorPosition()
                cursorY = cursorY / scale
                currentAlpha = math.max(0, math.min(1, 1 - ((self:GetTop() - cursorY) / squareSize)))
                UpdateAllColors()
            end
        end)
        bar:SetScript("OnMouseUp", function() isDraggingAlpha = false end)
        bar:SetScript("OnUpdate", function(self)
            if isDraggingAlpha then
                local scale = self:GetEffectiveScale()
                local _, cursorY = GetCursorPosition()
                cursorY = cursorY / scale
                currentAlpha = math.max(0, math.min(1, 1 - ((self:GetTop() - cursorY) / squareSize)))
                UpdateAllColors()
            end
        end)
    end

    SetupAlphaBarHandlers(alphaBar)
    SetupAlphaBarHandlers(circleAlphaBar)

    circleValueBar:EnableMouse(true)
    circleValueBar:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDraggingCircleValue = true
            local scale = self:GetEffectiveScale()
            local _, cursorY = GetCursorPosition()
            cursorY = cursorY / scale
            currentVal = math.max(0, math.min(1, 1 - ((self:GetTop() - cursorY) / squareSize)))
            UpdateAllColors()
        end
    end)
    circleValueBar:SetScript("OnMouseUp", function() isDraggingCircleValue = false end)
    circleValueBar:SetScript("OnUpdate", function(self)
        if isDraggingCircleValue then
            local scale = self:GetEffectiveScale()
            local _, cursorY = GetCursorPosition()
            cursorY = cursorY / scale
            currentVal = math.max(0, math.min(1, 1 - ((self:GetTop() - cursorY) / squareSize)))
            UpdateAllColors()
        end
    end)

    local isDraggingWheel = false
    local wheelRadius = squareSize / 2

    local function UpdateWheelFromCursor(frame)
        local scale = frame:GetEffectiveScale()
        local cursorX, cursorY = GetCursorPosition()
        cursorX, cursorY = cursorX / scale, cursorY / scale

        local centerX = frame:GetLeft() + wheelRadius
        local centerY = frame:GetTop() - wheelRadius

        local dx = cursorX - centerX
        local dy = centerY - cursorY
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist > wheelRadius then
            dx = dx * wheelRadius / dist
            dy = dy * wheelRadius / dist
            dist = wheelRadius
        end

        local angle = math.atan2(dy, dx)
        currentHue = ((angle + math.pi) / (2 * math.pi)) * 360
        currentSat = dist / wheelRadius

        UpdateAllColors()
    end

    wheelFrame:EnableMouse(true)
    wheelFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDraggingWheel = true
            UpdateWheelFromCursor(self)
        end
    end)
    wheelFrame:SetScript("OnMouseUp", function() isDraggingWheel = false end)
    wheelFrame:SetScript("OnUpdate", function(self)
        if isDraggingWheel then
            UpdateWheelFromCursor(self)
        end
    end)

    local function UpdatePickerMode()
        if useSquarePicker then
            squareContainer:Show()
            circleContainer:Hide()
            squareBtn:SetBackdropColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
            squareBtnText:SetTextColor(1, 1, 1)
            circleBtn:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 0)
            circleBtnText:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)
        else
            squareContainer:Hide()
            circleContainer:Show()
            circleBtn:SetBackdropColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
            circleBtnText:SetTextColor(1, 1, 1)
            squareBtn:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 0)
            squareBtnText:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)
            UpdateWheelThumbPosition()
        end
    end

    squareBtn:SetScript("OnClick", function()
        if not useSquarePicker then
            useSquarePicker = true
            preferSquarePicker = true
            SaveColorsToDb()
            UpdatePickerMode()
            UpdateAllColors()
        end
    end)

    circleBtn:SetScript("OnClick", function()
        if useSquarePicker then
            useSquarePicker = false
            preferSquarePicker = false
            SaveColorsToDb()
            UpdatePickerMode()
            UpdateAllColors()
        end
    end)

    squareBtn:SetScript("OnEnter", function(self)
        if not useSquarePicker then
            self:SetBackdropColor(C_ELEMENT.r + 0.1, C_ELEMENT.g + 0.1, C_ELEMENT.b + 0.1, 1)
        end
    end)
    squareBtn:SetScript("OnLeave", function(self)
        if not useSquarePicker then
            self:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 0)
        end
    end)
    circleBtn:SetScript("OnEnter", function(self)
        if useSquarePicker then
            self:SetBackdropColor(C_ELEMENT.r + 0.1, C_ELEMENT.g + 0.1, C_ELEMENT.b + 0.1, 1)
        end
    end)
    circleBtn:SetScript("OnLeave", function(self)
        if useSquarePicker then
            self:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 0)
        end
    end)

    function testFrame:UpdateAlphaVisibility()
        local showAlpha = self.hasAlpha
        alphaBar:SetShown(showAlpha)
        circleAlphaBar:SetShown(showAlpha)
        aInput:GetParent():SetShown(showAlpha)

        if showAlpha then
            previewFrame:SetPoint("TOPLEFT", squareContainer, "TOPRIGHT", -50, 0)
        else
            previewFrame:SetPoint("TOPLEFT", squareContainer, "TOPRIGHT", -78, 0)
        end
    end

    local tabFrame = CreateFrame("Frame", nil, content)
    tabFrame:SetSize(300, 22)
    tabFrame:SetPoint("TOPLEFT", hexFrame, "BOTTOMLEFT", 0, -8)

    local tabButtons = {}
    local tabContent = CreateFrame("Frame", nil, content)
    tabContent:SetSize(300, 96)
    tabContent:SetPoint("TOPLEFT", tabFrame, "BOTTOMLEFT", 0, -4)

    local function CreateTab(name, label, xOffset)
        local btn = CreateFrame("Button", nil, tabFrame)
        btn:SetSize(55, 20)
        btn:SetPoint("LEFT", xOffset, 0)

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER")
        text:SetText(label)
        btn.text = text

        local underline = btn:CreateTexture(nil, "OVERLAY")
        underline:SetHeight(2)
        underline:SetPoint("BOTTOMLEFT", 0, 0)
        underline:SetPoint("BOTTOMRIGHT", 0, 0)
        underline:SetColorTexture(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
        underline:Hide()
        btn.underline = underline

        btn.name = name
        tabButtons[name] = btn
        return btn
    end

    CreateTab("saved", "Saved", 0)
    CreateTab("recent", "Recent", 60)
    CreateTab("class", "Class", 120)

    local saveBtn = CreateFrame("Button", nil, tabFrame, "BackdropTemplate")
    saveBtn:SetSize(50, 18)
    saveBtn:SetPoint("RIGHT", 0, 0)
    saveBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    saveBtn:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)
    saveBtn:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)

    local saveBtnText = saveBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    saveBtnText:SetPoint("CENTER")
    saveBtnText:SetText("Save")
    saveBtnText:SetTextColor(C_TEXT.r, C_TEXT.g, C_TEXT.b)

    saveBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
    end)
    saveBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)
    end)

    local classContent = CreateFrame("Frame", nil, tabContent)
    classContent:SetAllPoints()
    classContent:Hide()

    local savedContent = CreateFrame("Frame", nil, tabContent)
    savedContent:SetAllPoints()

    local recentContent = CreateFrame("Frame", nil, tabContent)
    recentContent:SetAllPoints()
    recentContent:Hide()

    local function SelectColor(r, g, b)
        currentHue, currentSat, currentVal = RGBtoHSV(r, g, b)
        UpdateAllColors()
    end

    local function CreateColorSwatch(parent, index, r, g, b, tooltip)
        local row = math.floor((index - 1) / SWATCHES_PER_ROW)
        local col = (index - 1) % SWATCHES_PER_ROW

        local swatch = CreateFrame("Button", nil, parent, "BackdropTemplate")
        swatch:SetSize(SWATCH_SIZE, SWATCH_SIZE)
        swatch:SetPoint("TOPLEFT", col * (SWATCH_SIZE + SWATCH_GAP), -row * (SWATCH_SIZE + SWATCH_GAP))
        swatch:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        swatch:SetBackdropColor(r, g, b, 1)
        swatch:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)

        swatch:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(1, 1, 1, 1)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if tooltip then
                GameTooltip:SetText(tooltip)
            end
            GameTooltip:Show()
        end)
        swatch:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)
            GameTooltip:Hide()
        end)
        swatch:SetScript("OnClick", function()
            SelectColor(r, g, b)
        end)

        return swatch
    end

    local i = 1
    for class, val in pairs(UIOptions.classColoursList) do
        CreateColorSwatch(classContent, i, val.RGBA.r, val.RGBA.g, val.RGBA.b, class)
        i = i + 1
    end

    local savedSwatches = {}
    local savedEmptyText = savedContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    savedEmptyText:SetPoint("CENTER", 0, 0)
    savedEmptyText:SetText("No saved colors yet\nClick 'Save' to add current color")
    savedEmptyText:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)
    savedEmptyText:SetJustifyH("CENTER")

    local function RefreshSavedSwatches()
        for _, swatch in ipairs(savedSwatches) do
            swatch:Hide()
            swatch:SetParent(nil)
        end
        wipe(savedSwatches)

        savedEmptyText:SetShown(#savedColors == 0)

        for i, color in ipairs(savedColors) do
            local row = math.floor((i - 1) / SWATCHES_PER_ROW)
            local col = (i - 1) % SWATCHES_PER_ROW

            local swatch = CreateFrame("Button", nil, savedContent, "BackdropTemplate")
            swatch:SetSize(SWATCH_SIZE, SWATCH_SIZE)
            swatch:SetPoint("TOPLEFT", col * (SWATCH_SIZE + SWATCH_GAP), -row * (SWATCH_SIZE + SWATCH_GAP))
            swatch:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            swatch:SetBackdropColor(color.r, color.g, color.b, 1)
            swatch:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)
            swatch.colorIndex = i

            swatch:SetScript("OnEnter", function(self)
                self:SetBackdropBorderColor(1, 1, 1, 1)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Left-click to select")
                GameTooltip:AddLine("Right-click to delete", 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end)
            swatch:SetScript("OnLeave", function(self)
                self:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)
                GameTooltip:Hide()
            end)
            swatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            swatch:SetScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    SelectColor(color.r, color.g, color.b)
                    if testFrame.hasAlpha and color.a then
                        currentAlpha = color.a
                    else
                        currentAlpha = 1
                    end
                    UpdateAllColors()
                elseif button == "RightButton" then
                    table.remove(savedColors, self.colorIndex)
                    SaveColorsToDb()
                    RefreshSavedSwatches()
                end
            end)

            table.insert(savedSwatches, swatch)
        end
    end

    testFrame.RefreshSavedSwatches = RefreshSavedSwatches

    saveBtn:SetScript("OnClick", function()
        if #savedColors >= MAX_SAVED then
            return
        end

        local r, g, b = HSVtoRGB(currentHue, currentSat, currentVal)
        local a = testFrame.hasAlpha and currentAlpha or nil
        local key = ColorKey(r, g, b, a or 1)

        for _, color in ipairs(savedColors) do
            if ColorKey(color.r, color.g, color.b, color.a or 1) == key then
                return
            end
        end

        table.insert(savedColors, 1, {r = r, g = g, b = b, a = a})
        SaveColorsToDb()
        RefreshSavedSwatches()
        testFrame.SetActiveTab("saved")
    end)

    local recentSwatches = {}
    local recentEmptyText = recentContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    recentEmptyText:SetPoint("CENTER", 0, 0)
    recentEmptyText:SetText("No recent colors yet\nColors appear here when you apply them")
    recentEmptyText:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)
    recentEmptyText:SetJustifyH("CENTER")

    local function RefreshRecentSwatches()
        for _, swatch in ipairs(recentSwatches) do
            swatch:Hide()
            swatch:SetParent(nil)
        end
        wipe(recentSwatches)

        recentEmptyText:SetShown(#recentColors == 0)

        for i, color in ipairs(recentColors) do
            local row = math.floor((i - 1) / SWATCHES_PER_ROW)
            local col = (i - 1) % SWATCHES_PER_ROW

            local swatch = CreateFrame("Button", nil, recentContent, "BackdropTemplate")
            swatch:SetSize(SWATCH_SIZE, SWATCH_SIZE)
            swatch:SetPoint("TOPLEFT", col * (SWATCH_SIZE + SWATCH_GAP), -row * (SWATCH_SIZE + SWATCH_GAP))
            swatch:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            swatch:SetBackdropColor(color.r, color.g, color.b, 1)
            swatch:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)

            swatch:SetScript("OnEnter", function(self)
                self:SetBackdropBorderColor(1, 1, 1, 1)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Left-click to select")
                GameTooltip:AddLine("Right-click to save", 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end)
            swatch:SetScript("OnLeave", function(self)
                self:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)
                GameTooltip:Hide()
            end)
            swatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            swatch:SetScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    SelectColor(color.r, color.g, color.b)
                    if testFrame.hasAlpha and color.a then
                        currentAlpha = color.a
                    else
                        currentAlpha = 1
                    end
                    UpdateAllColors()
                elseif button == "RightButton" then
                    if #savedColors >= MAX_SAVED then
                        return
                    end

                    local a = testFrame.hasAlpha and color.a or nil
                    local key = ColorKey(color.r, color.g, color.b, a or 1)
                    for _, saved in ipairs(savedColors) do
                        if ColorKey(saved.r, saved.g, saved.b, saved.a or 1) == key then
                            return
                        end
                    end

                    table.insert(savedColors, 1, {r = color.r, g = color.g, b = color.b, a = a})
                    SaveColorsToDb()
                    RefreshSavedSwatches()
                    testFrame.SetActiveTab("saved")
                end
            end)

            table.insert(recentSwatches, swatch)
        end
    end

    local function AddToRecent(r, g, b, a)
        local key = ColorKey(r, g, b, a)

        for i, color in ipairs(recentColors) do
            if ColorKey(color.r, color.g, color.b, color.a) == key then
                table.remove(recentColors, i)
                break
            end
        end

        table.insert(recentColors, 1, {r = r, g = g, b = b, a = a})

        while #recentColors > MAX_RECENT do
            table.remove(recentColors)
        end

        SaveColorsToDb()
        RefreshRecentSwatches()
    end

    testFrame.AddToRecent = AddToRecent
    testFrame.RefreshRecentSwatches = RefreshRecentSwatches

    local function UpdateTabs()
        for name, btn in pairs(tabButtons) do
            if name == activeTab then
                btn.text:SetTextColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b)
                btn.underline:Show()
            else
                btn.text:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)
                btn.underline:Hide()
            end
        end
        classContent:SetShown(activeTab == "class")
        savedContent:SetShown(activeTab == "saved")
        recentContent:SetShown(activeTab == "recent")
    end

    testFrame.UpdateTabs = UpdateTabs
    testFrame.SetActiveTab = function(tab)
        activeTab = tab
        UpdateTabs()
    end

    for name, btn in pairs(tabButtons) do
        btn:SetScript("OnClick", function()
            activeTab = name
            UpdateTabs()
        end)
    end

    local footer = CreateFrame("Frame", nil, testFrame, "BackdropTemplate")
    footer:SetHeight(40)
    footer:SetPoint("BOTTOMLEFT", 0, 0)
    footer:SetPoint("BOTTOMRIGHT", 0, 0)
    footer:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    footer:SetBackdropColor(C_ELEMENT.r, C_ELEMENT.g, C_ELEMENT.b, 1)

    local applyBtn = CreateFrame("Button", nil, footer, "BackdropTemplate")
    applyBtn:SetSize(80, 26)
    applyBtn:SetPoint("RIGHT", footer, "CENTER", -5, 0)
    applyBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    applyBtn:SetBackdropColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
    applyBtn:SetBackdropBorderColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)

    local applyText = applyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    applyText:SetPoint("CENTER")
    applyText:SetText("Okay")
    applyText:SetTextColor(1, 1, 1)

    local cancelBtn = CreateFrame("Button", nil, footer, "BackdropTemplate")
    cancelBtn:SetSize(80, 26)
    cancelBtn:SetPoint("LEFT", footer, "CENTER", 5, 0)
    cancelBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    cancelBtn:SetBackdropColor(C_BG.r, C_BG.g, C_BG.b, 1)
    cancelBtn:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)

    local cancelText = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cancelText:SetPoint("CENTER")
    cancelText:SetText("Cancel")
    cancelText:SetTextColor(C_TEXT_DIM.r, C_TEXT_DIM.g, C_TEXT_DIM.b)

    applyBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C_ACCENT.r * 1.2, C_ACCENT.g * 1.2, C_ACCENT.b * 1.2, 1)
    end)
    applyBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 1)
    end)
    cancelBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.8, 0.4, 0.4, 1)
    end)
    cancelBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C_BORDER.r, C_BORDER.g, C_BORDER.b, 1)
    end)

    function testFrame:SetColor(r, g, b, a)
        local h, s, v = RGBtoHSV(r, g, b)
        currentHue = h
        currentSat = s
        currentVal = v
        currentAlpha = a or 1
        UpdateAllColors()
    end

    function testFrame:GetColor()
        local r, g, b = HSVtoRGB(currentHue, currentSat, currentVal)
        return r, g, b, currentAlpha
    end

    function testFrame:SetCallbacks(onAccept, onCancel, onChange)
        self.onAcceptCallback = onAccept
        self.onCancelCallback = onCancel
        self.onChangeCallback = onChange
    end

    function testFrame:ClearCallbacks()
        self.onAcceptCallback = nil
        self.onCancelCallback = nil
        self.onChangeCallback = nil
    end

    applyBtn:SetScript("OnClick", function()
        local r, g, b = HSVtoRGB(currentHue, currentSat, currentVal)
        AddToRecent(r, g, b, testFrame.hasAlpha and currentAlpha or nil)
        testFrame.appliedColor = true

        if testFrame.onAcceptCallback then
            testFrame.onAcceptCallback({
                r = r,
                g = g,
                b = b,
                a = testFrame.hasAlpha and currentAlpha or 1,
            })
        end

        testFrame:ClearCallbacks()
        testFrame:Hide()
    end)

    cancelBtn:SetScript("OnClick", function()
        testFrame:Hide()
    end)

    currentHue = 25
    currentSat = 0.8
    currentVal = 0.9
    currentAlpha = 1

    UpdatePickerMode()
    UpdateTabs()
    RefreshSavedSwatches()
    RefreshRecentSwatches()
    testFrame:UpdateAlphaVisibility()
    UpdateAllColors()

    return testFrame
end

function GUI:OpenColorPicker(initialColor, hasAlpha, onAccept, onCancel, onChange)
    local frame = CreateColorPicker(hasAlpha)

    if frame:IsShown() then
        frame.appliedColor = true
        frame:Hide()
    end

    frame:ClearCallbacks()
    frame.appliedColor = false
    frame.skipOnChange = false

    frame:SetCallbacks(onAccept, onCancel, onChange)

    if initialColor then
        frame.skipOnChange = true
        frame:SetColor(
            initialColor.r or 1,
            initialColor.g or 1,
            initialColor.b or 1,
            initialColor.a or 1
        )
        frame.skipOnChange = false

        if frame.AddToRecent then
            frame.AddToRecent(
                initialColor.r or 1,
                initialColor.g or 1,
                initialColor.b or 1,
                hasAlpha and (initialColor.a or 1) or nil
            )
        end
    end

    frame.hasAlpha = hasAlpha
    frame:UpdateAlphaVisibility()

    if frame.UpdatePosition then
        frame.UpdatePosition()
    end

    frame:Show()
end