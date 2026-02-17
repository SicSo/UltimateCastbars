local ADDON_NAME, UCB = ...

local LDB  = UCB.LDB

local broker = LDB:NewDataObject(ADDON_NAME, {
    type = "data source",
    text = "Ultimate Castbars",          
    icon = "Interface\\AddOns\\UltimateCastbars\\gfx\\icon",
})

-- What happens when clicked
broker.OnClick = function(_, button)
    if button == "LeftButton" then
        UCB.GUI:OpenGUI(nil)
    elseif button == "RightButton" then
        UCB.GUI:OpenGUI({ "profiles", "management" })
    end
end

-- Tooltip on hover 
broker.OnEnter = function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Ultimate Castbars")
    GameTooltip:AddLine("Left-click: Open profiles", 1, 1, 1)
    GameTooltip:AddLine("Right-click: Open settings", 1, 1, 1)
    GameTooltip:Show()
end

broker.OnLeave = function()
    GameTooltip:Hide()
end

-- Whenever your value changes, update broker.text
local function UpdateText()
    broker.text = "Ultimate Castbars"
end

-- Example: update on login and on some event
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event)
    UpdateText()
end)
