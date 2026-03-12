local _, UCB = ...

UCB.UIOptions = UCB.UIOptions or {}

local UIOptions = UCB.UIOptions

--interface/buttons/128

--[[-----------------------------------------------------------------------------
Button Widget
Graphical Button.
-------------------------------------------------------------------------------]]
local Type, Version = "UCB_Button", 24
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local _G = _G
local PlaySound, CreateFrame, UIParent = PlaySound, CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Button_OnClick(frame, ...)
	AceGUI:ClearFocus()
	PlaySound(852) -- SOUNDKIT.IG_MAINMENU_OPTION
	frame.obj:Fire("OnClick", ...)
end

local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		-- restore default values
		self:SetHeight(30)
		self:SetWidth(200)
		self:SetDisabled(false)
		self:SetAutoWidth(false)
		self:SetText()
	end,

	-- ["OnRelease"] = nil,

    ["SetText"] = function(self, text)
        self.frame:SetText(text)
        if self.autoWidth then
            self:SetWidth(self.frame:GetTextWidth() + 30)
        end
    end,

    ["SetAutoWidth"] = function(self, autoWidth)
        self.autoWidth = autoWidth
        if self.autoWidth then
            self:SetWidth(self.frame:GetTextWidth() + 30)
        end
    end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.frame:Disable()
		else
			self.frame:Enable()
		end
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
    local name = "AceGUI30Button" .. AceGUI:GetNextWidgetNum(Type)
    --local frame = CreateFrame("Button", name, UIParent, "SharedGoldRedButtonSmallTemplate")
    --local frame = CreateFrame("Button", name, UIParent, "UCB_BlackThreeSlice")
    local frame = CreateFrame("Button", name, UIParent, "UCBButtonTemplate")

    --frame:SetSideWidth(30)
    
    --local info  = C_XMLUtil.GetTemplateInfo("SharedButtonSmallTemplate")
    --print(info.sourceLocation)

    --for _, template in ipairs(C_XMLUtil.GetTemplates()) do
     --   if template.type == "Slider" then
    --        print(template.name, template.type)
    --    end
    --end

    frame:Hide()
    frame:EnableMouse(true)
    frame:SetScript("OnClick", Button_OnClick)
    frame:HookScript("OnEnter", Control_OnEnter)
    frame:HookScript("OnLeave", Control_OnLeave)

    local widget = {
        frame = frame,
        type  = Type
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
