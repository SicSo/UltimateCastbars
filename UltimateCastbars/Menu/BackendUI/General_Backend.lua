local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.GeneralSettings_API = UCB.GeneralSettings_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local GeneralSettings_API = UCB.GeneralSettings_API


function GeneralSettings_API:addNewItemList(tbl, item)
    for _, v in ipairs(tbl) do
        if v == item then
            return -- Item already exists, do not add
        end
    end
    table.insert(tbl, item)
end

function GeneralSettings_API:getFrame(frameName)
    if not frameName or frameName == "" then
        return UIParent
    end

    local frame = _G[frameName]
    if not frame then
        return nil
    end

    return frame
end