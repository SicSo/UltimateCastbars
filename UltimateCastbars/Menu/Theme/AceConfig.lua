local _, UCB = ...

UCB.Theme = UCB.Theme or {}

local Theme = UCB.Theme


if not Theme._hookedFeedGroup then
	local ACD = UCB.ACD or LibStub("AceConfigDialog-3.0")

	Theme._hookedFeedGroup = true

	local origFeedGroup = ACD.FeedGroup

	function ACD:FeedGroup(appName, options, container, rootframe, path, isRoot)
		-- Only affect your addon
		if appName ~= "UCB_ROOT" then
			return origFeedGroup(self, appName, options, container, rootframe, path, isRoot)
		end

		Theme:AceGUIOverride(function()
			origFeedGroup(self, appName, options, container, rootframe, path, isRoot)
			end)
	end
end


if not Theme._hookedFeedOptions then
	local ACD = UCB.ACD or LibStub("AceConfigDialog-3.0")

	Theme._hookedFeedOptions = true

	local origFeedOptions = ACD.FeedOptions
	function ACD:FeedOptions(appName, options,container,rootframe,path,group,inline)
		-- Only affect your addon
		print(appName, "FeedOptions", path)
		if appName ~= "UCB_ROOT" then
			return origFeedOptions(self, appName, options, container, rootframe, path, group, inline)
		end

		Theme:AceGUIOverride(function()
			origFeedOptions(self, appName, options, container, rootframe, path, group, inline)
			end)

	end
end

