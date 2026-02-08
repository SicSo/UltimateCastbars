local ADDON_NAME, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions

local LSM  = UCB.LSM
local LDB  = UCB.LDB


-- Create a broker object.
-- type = "data source" is what you want for ElvUI DataTexts.
local broker = LDB:NewDataObject(ADDON_NAME, {
    type = "data source",
    text = "Ultimate Castbars",          -- what ElvUI shows on the bar initially
    icon = "Interface\\AddOns\\UltimateCastbars\\gfx\\icon", -- optional
})

-- What happens when clicked
broker.OnClick = function(_, button)
    if button == "LeftButton" then
        if SlashCmdList and SlashCmdList.UCB then
        SlashCmdList.UCB()
        end
    elseif button == "RightButton" then
        if SlashCmdList and SlashCmdList.UCB then
        SlashCmdList.UCB() -- if you support args; otherwise just ""
        end
    end
end
-- Tooltip on hover (ElvUI will show this when hovering the datatext)
broker.OnEnter = function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Ultimate Castbars")
    GameTooltip:AddLine("Left-click: Toggle", 1, 1, 1)
    GameTooltip:AddLine("Right-click: Options", 1, 1, 1)
    GameTooltip:Show()
end

broker.OnLeave = function()
    GameTooltip:Hide()
end

-- Whenever your value changes, update broker.text
local function UpdateText()
    local value = 123 -- replace with your data
    broker.text = "Ultimate Castbars"
end

-- Example: update on login and on some event
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event)
    UpdateText()
end)
