local ADDON_NAME, UCB = ...

UCB.CFG_API  = UCB.CFG_API  or {}
UCB.Debug = UCB.Debug or {}

local CFG_API = UCB.CFG_API
local Debug = UCB.Debug


-- Returns an array (list) of addon folder names that are currently enabled.
function Debug:GetEnabledAddons(includeItself, playerName)
    local enabled = {}

    for i = 1, C_AddOns.GetNumAddOns() do
        local addonName = C_AddOns.GetAddOnInfo(i)
        if addonName then
            if not (not includeItself and addonName == ADDON_NAME) then -- exclude itself if specified
            local state = C_AddOns.GetAddOnEnableState(addonName, playerName) -- 0 disabled, >0 enabled
                if state ~= 0 then
                    enabled[#enabled + 1] = addonName
                end
            end
        end
    end

    return enabled
end

-- Enables all addons in a list
local function EnableAddonList(addonList, playerName)
  if InCombatLockdown and InCombatLockdown() then
    print("|cffff0000[AddonToggle]|r Can't do this in combat.")
    return
  end

  for i = 1, #addonList do
    C_AddOns.EnableAddOn(addonList[i], playerName)
  end

  print("|cff00ff00[AddonToggle]|r Enabled " .. tostring(#addonList) .. " addons. Reloading...")
  C_UI.Reload()
end

-- Disables all addons in a list
local function DisableAddonList(addonList, playerName)
  if InCombatLockdown and InCombatLockdown() then
    print("|cffff0000[AddonToggle]|r Can't do this in combat.")
    return
  end

  for i = 1, #addonList do
    C_AddOns.DisableAddOn(addonList[i], playerName)
  end

  print("|cff00ff00[AddonToggle]|r Disabled " .. tostring(#addonList) .. " addons. Reloading...")
  C_UI.Reload()
end


function Debug:StartDebug()
  local playerName = UCB.charName
  local addonList = self:GetEnabledAddons(false, playerName) -- get all enabled addons except itself
  local cfg = CFG_API.GetValueConfig("debug")
  cfg.enabled = true
  cfg._addonList = addonList
  DisableAddonList(addonList, UCB.charName)
end

function Debug:StopDebug()
    local cfg = CFG_API.GetValueConfig("debug")
    local addonList = cfg._addonList or {}
    if #addonList > 0 and cfg.enabled then
        EnableAddonList(addonList, UCB.charName)
        cfg.enabled = false
        cfg._addonList = {}
    else
        print("|cffff0000[AddonToggle]|r No addons to re-enable.")
    end
end