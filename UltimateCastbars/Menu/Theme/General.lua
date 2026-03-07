local _, UCB = ...

UCB.Theme = UCB.Theme or {}

local Theme = UCB.Theme


function Theme:AceGUIOverride(fn)
    local AceGUI = UCB.AG or (LibStub and LibStub("AceGUI-3.0", true))
	local origCreate = AceGUI.Create

	AceGUI.Create = function(self, widgetType, ...)
		if widgetType == "TabGroup" then
			local w = origCreate(self, "UCB_TabGroup", ...)
			if w then return w end
			return origCreate(self, "TabGroup", ...)
		end
        if widgetType == "InlineGroup" then
            local w = origCreate(self, "UCB_InlineGroup", ...)
            if w then return w end
            return origCreate(self, "InlineGroup", ...)
        end
         if widgetType == "SimpleGroup" then
            local w = origCreate(self, "UCB_SimpleGroup", ...)
            if w then return w end
            return origCreate(self, "SimpleGroup", ...)
        end
         if widgetType == "ScrollFrame" then
            local w = origCreate(self, "UCB_ScrollFrame", ...)
            if w then return w end
            return origCreate(self, "ScrollFrame", ...)
        end
         if widgetType == "Window" then
            local w = origCreate(self, "UCB_Window", ...)
            if w then return w end
            return origCreate(self, "Window", ...)
        end
        if widgetType == "TreeGroup" then
            local w = origCreate(self, "UCB_TreeGroup", ...)
            if w then return w end
            return origCreate(self, "TreeGroup", ...)
        end
		return origCreate(self, widgetType, ...)
	end

	local ok, err = pcall(fn)

	AceGUI.Create = origCreate
	if not ok then error(err) end
end