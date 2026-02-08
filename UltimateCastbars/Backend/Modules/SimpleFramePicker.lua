-- ============================================================================
-- SimpleFramePicker.lua
-- Self-contained frame picker:
--   Hover frames -> highlight + show name
--   UP/DOWN -> cycle layers under cursor
--   CTRL -> select current frame (stores name)
--   ESC -> cancel
-- ============================================================================
local _, UCB = ...

UCB.SimpleFramePicker = UCB.SimpleFramePicker or {}
local SimpleFramePicker = UCB.SimpleFramePicker

SimpleFramePicker.__index = SimpleFramePicker

-- Tweakable
SimpleFramePicker.UPDATE_INTERVAL = 0.05 -- seconds

local EnumerateFrames = EnumerateFrames

function SimpleFramePicker:New()
    local o = setmetatable({}, self)
    o.active = false
    o.visualLayerIndex = 1
    o.manualSelection = nil
    o.selectedFrame = nil
    o.validFrames = {}
    o.seenFrames = {}
    o.ctrlLock = false

    o.onSelect = nil
    o.onCancel = nil

    o.hud = nil
    o.highlighter = nil
    o.updateFrame = nil
    o.navButtons = {}

    return o
end

-- -------------------- UI --------------------

function SimpleFramePicker:CreateHUD()
    if self.hud then return self.hud end

    local f = CreateFrame("Frame", "SFP_HUD", UIParent, "BackdropTemplate")
    f:SetSize(320, 95)
    f:SetPoint("BOTTOM", 0, 150)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:EnableMouse(false)
    f:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.85)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -8)
    title:SetText("|cff00ff00PICKER MODE ACTIVE|r")

    local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOP", title, "BOTTOM", 0, -6)
    text:SetText("|cff00ccffCTRL|r Select   |cff00ccffUP/DOWN|r Layer   |cff00ccffESC|r Cancel")

    self.hud = f
    return f
end

function SimpleFramePicker:CreateHighlighter()
    if self.highlighter then return self.highlighter end

    local h = CreateFrame("Frame", "SFP_Highlighter", UIParent)
    h:SetFrameStrata("FULLSCREEN_DIALOG")
    h:EnableMouse(false)

    local tex = h:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetColorTexture(0, 1, 0, 0.35)
    h.tex = tex

    local txt = h:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    txt:SetPoint("CENTER")
    h.text = txt

    self.highlighter = h
    return h
end

function SimpleFramePicker:GetNavButton(name)
    if self.navButtons[name] then return self.navButtons[name] end

    local btn = CreateFrame("Button", "SFP_Nav_" .. name, UIParent)
    self.navButtons[name] = btn

    if name == "Up" then
        btn:SetScript("OnClick", function()
            if self.selectedFrame and self.selectedFrame:GetParent() then
                self.selectedFrame = self.selectedFrame:GetParent()
                self.manualSelection = self.selectedFrame
                self.visualLayerIndex = 1
            end
        end)
    elseif name == "Down" then
        btn:SetScript("OnClick", function()
            self.visualLayerIndex = (self.visualLayerIndex or 1) + 1
            self.manualSelection = nil
        end)
    elseif name == "Cancel" then
        btn:SetScript("OnClick", function()
            self:Stop(true)
        end)
    elseif name == "Block" then
        btn:SetScript("OnClick", function() end)
    end

    return btn
end

-- -------------------- Selection --------------------
local function IsFrameObject(obj)
    local t = type(obj)
    if t ~= "table" and t ~= "userdata" then
        return false
    end

    local ok, ot = pcall(obj.GetObjectType, obj)
    if not ok or type(ot) ~= "string" then
        return false
    end

    -- Many frames support GetRect; this is a good “real frame” signal
    local okRect = pcall(obj.GetRect, obj)
    return okRect
end

local function IsSelectable(self, frm)
    if not IsFrameObject(frm) then return false end
    if frm == WorldFrame then return false end
    if self.hud and frm == self.hud then return false end
    if self.highlighter and frm == self.highlighter then return false end

    local okVis, vis = pcall(frm.IsVisible, frm)
    if okVis and not vis then return false end

    return true
end


function SimpleFramePicker:BuildFromMouseFoci()
    wipe(self.validFrames)
    wipe(self.seenFrames)

    local frames = (GetMouseFoci and GetMouseFoci()) or { GetMouseFocus() }
    for _, frm in ipairs(frames or {}) do
        if IsSelectable(self, frm) and not self.seenFrames[frm] then
            self.seenFrames[frm] = true
            table.insert(self.validFrames, frm)
        end
    end
end

function SimpleFramePicker:GeometryFallback()
    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    cursorX, cursorY = cursorX / scale, cursorY / scale

    local frame = EnumerateFrames()
    while frame do
        -- Exclusions + visibility checks must be protected
        local ok = pcall(function()
            if frame ~= WorldFrame
                and frame ~= self.highlighter
                and frame ~= self.hud
                and not self.seenFrames[frame]
                and frame.IsVisible and frame:IsVisible()
                and frame.GetRect
            then
                local l, b, w, h = frame:GetRect()
                if l and b and w and h and w > 0 and h > 0 then
                    if cursorX >= l and cursorX <= (l + w) and cursorY >= b and cursorY <= (b + h) then
                        self.seenFrames[frame] = true
                        table.insert(self.validFrames, frame)
                    end
                end
            end
        end)

        -- If something weird happens with a specific frame, ignore it
        frame = EnumerateFrames(frame)
    end
end

function SimpleFramePicker:UpdateSelection()
    if not self.manualSelection then
        self:BuildFromMouseFoci()
        if #self.validFrames <= 1 then
            self:GeometryFallback()
        end

        if #self.validFrames > 0 then
            if self.visualLayerIndex > #self.validFrames then
                self.visualLayerIndex = 1
            end
            self.selectedFrame = self.validFrames[self.visualLayerIndex]
        else
            self.selectedFrame = nil
        end
    else
        self.selectedFrame = self.manualSelection
    end
end

function SimpleFramePicker:Render(lastSelected)
    if self.selectedFrame and self.selectedFrame ~= lastSelected then
        local ok = pcall(function()
            self.highlighter:ClearAllPoints()
            self.highlighter:SetAllPoints(self.selectedFrame)
            self.highlighter.text:SetText(self.selectedFrame:GetName() or "Unnamed")
            self.highlighter:Show()
        end)
        if ok then return self.selectedFrame end
    elseif not self.selectedFrame then
        self.highlighter:Hide()
        return nil
    end
    return lastSelected
end

function SimpleFramePicker:TryCtrlSelect()
    if not self.selectedFrame or not IsControlKeyDown() then return end
    if self.ctrlLock then return end
    self.ctrlLock = true
    C_Timer.After(0.5, function()
        if self then self.ctrlLock = false end
    end)

    local name = self.selectedFrame:GetName()
    if name and self.onSelect then
        local cb = self.onSelect
        self:Stop(false) -- stop without firing cancel
        cb(name, self.selectedFrame)
    end
end

-- -------------------- Public API --------------------

-- onSelect(name, frame) required
-- onCancel() optional
function SimpleFramePicker:Start(onSelect, onCancel)
    if InCombatLockdown and InCombatLockdown() then
        -- You can replace with your addon print function
        print("|cffff0000Cannot use picker during combat.|r")
        return
    end

    self.onSelect = onSelect
    self.onCancel = onCancel

    self.active = true
    self.visualLayerIndex = 1
    self.manualSelection = nil
    self.selectedFrame = nil
    self.ctrlLock = false

    self:CreateHUD():Show()
    local hl = self:CreateHighlighter()
    hl:Show()

    self:GetNavButton("Up")
    self:GetNavButton("Down")
    self:GetNavButton("Block")
    self:GetNavButton("Cancel")

    SetOverrideBindingClick(hl, true, "UP", "SFP_Nav_Up")
    SetOverrideBindingClick(hl, true, "DOWN", "SFP_Nav_Down")
    SetOverrideBindingClick(hl, true, "LEFT", "SFP_Nav_Block")
    SetOverrideBindingClick(hl, true, "RIGHT", "SFP_Nav_Block")
    SetOverrideBindingClick(hl, true, "ESCAPE", "SFP_Nav_Cancel")

    if not self.updateFrame then
        self.updateFrame = CreateFrame("Frame")
    end

    local lastUpdate = 0
    local lastSelected = nil

    self.updateFrame:SetScript("OnUpdate", function(_, elapsed)
        if not self.active then return end

        lastUpdate = lastUpdate + elapsed
        if lastUpdate < self.UPDATE_INTERVAL then return end
        lastUpdate = 0

        self:UpdateSelection()
        lastSelected = self:Render(lastSelected)
        self:TryCtrlSelect()
    end)
end

function SimpleFramePicker:Stop(fireCancel)
    self.active = false

    if self.updateFrame then
        self.updateFrame:SetScript("OnUpdate", nil)
    end

    if self.hud then self.hud:Hide() end

    if self.highlighter then
        self.highlighter:Hide()
        ClearOverrideBindings(self.highlighter)
    end

    if fireCancel and self.onCancel then
        self.onCancel()
    end
end

_G.SimpleFramePicker = _G.SimpleFramePicker or SimpleFramePicker
