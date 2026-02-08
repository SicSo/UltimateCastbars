local ADDON_NAME, UCB = ...
local UltimateCastBars = LibStub("AceAddon-3.0"):NewAddon("Ultimate Castbars", "AceConsole-3.0")

function UltimateCastBars:OnInitialize()

    --UCB:Print("UltimateCastBars initialized.")
    UCB.db = LibStub("AceDB-3.0"):New("UCB_DB", UCB:GetDefaultDB(), true)
    UCB.LDS:EnhanceDatabase(UCB.db, "Ultimate_Castbars")
    --[[
    for k, v in pairs(UCB:GetDefaultDB()) do
        if UCB.db.profile[k] == nil then
            UCB.db.profile[k] = v
        end
    end
    --]]

    if UCB.db.global.UseGlobalProfile then UCB.db:SetProfile(UCB.db.global.GlobalProfile or "Default") end
    UCB.db.RegisterCallback(UCB, "OnProfileChanged", function() UCB:UpdateAllCastBars() end)
    UCB.db.RegisterCallback(UCB, "OnProfileCopied", function() UCB:UpdateAllCastBars() end)
    UCB.db.RegisterCallback(UCB, "OnProfileReset", function() UCB:UpdateAllCastBars() end)
end

function UltimateCastBars:OnEnable()
    UCB:Init()
end
