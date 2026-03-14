local ADDON_NAME, UCB = ...
local UltimateCastBars = LibStub("AceAddon-3.0"):NewAddon("Ultimate Castbars", "AceConsole-3.0")

UCB.Copy = UCB.Copy or {}

function UltimateCastBars:OnInitialize()
    UCB.db = LibStub("AceDB-3.0"):New("UCB_DB", UCB:GetDefaultDB(), true)

    -- EnhanceDatabase before SetProfile is fine
    UCB.LDS:EnhanceDatabase(UCB.db, "Ultimate_Castbars")

    -- If you use a global profile, switch to it BEFORE normalizing
    if UCB.db.global.UseGlobalProfile then
        local name = UCB.db.global.GlobalProfileName or "Default"
        UCB.db:SetProfile(name)
    end

    UCB:LoadAssets(UCB.db.profile.misc.loadAssets)

    -- Normalize/upgrade the CURRENT active profile (and keep extra tags)
    local ok, err = UCB:NormalizeCurrentProfileToSchema()
    if not ok and err then
        -- optional debug
        print("UCB: Normalize failed:", err)
    end

    -- Callbacks (after profile selection)
    UCB.db.RegisterCallback(UCB, "OnProfileChanged", function() 
        UCB:NormalizeCurrentProfileToSchema()
        UCB:UpdateAllCastBars()
    end)
    UCB.db.RegisterCallback(UCB, "OnProfileReset", function()
        UCB:NormalizeCurrentProfileToSchema()
        UCB:UpdateAllCastBars()
    end)
end

function UltimateCastBars:OnEnable()
    UCB:Init()
end
