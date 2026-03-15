local _, UCB = ...

UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.UIStructures = UCB.UIStructures or {}

local CASTBAR_API = UCB.CASTBAR_API
local UIOptions = UCB.UIOptions
local UIStructures = UCB.UIStructures
local GetCFG = UCB.GetValueConfig


---------------------------------------- CLASS SPELLS --------------------------------------------
function UIStructures:_SafeSpellInfo(spellID)
    local id = tonumber(spellID)
    if not id then return nil end

    local info = C_Spell.GetSpellInfo(id)
    if not info then
        return { id = id, name = "Unknown", icon = 134400 }
    end

    return {
        id   = id,
        name = info.name or "Unknown",
        icon = info.originalIconID or 134400,
    }
end

function UIStructures:_BuildAllSpellsDropdownValues()
    local merged, seen = {}, {}

    local function addList(list)
        for _, sid in ipairs(list or {}) do
            sid = tonumber(sid)
            if sid and not seen[sid] then
                local info = C_Spell.GetSpellInfo(sid)
                if info and info.name then
                    seen[sid] = true
                    table.insert(merged, { id = sid, name = info.name })
                end
            end
        end
    end

    addList(UCB.allSpellTypes and UCB.allSpellTypes.channel)
    addList(UCB.allSpellTypes and UCB.allSpellTypes.normal)
    addList(UCB.allSpellTypes and UCB.allSpellTypes.empowered)

    table.sort(merged, function(a, b)
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)

    local values = {}
    for _, s in ipairs(merged) do
        values[s.id] = s.name .. " - " .. s.id
    end
    return values
end



function UIStructures:createSelectBlock(cfg, order)
    local cfgMisc = GetCFG().misc

    local displaySpellID = {
        type = "group",
        name = "Print Spell ID for casted spells",
        inline = true,
        order = 1,
        args = {
            desc = {
                type = "description",
                name = "Toggle whether to print the spell ID of casts in the chat window. This is useful for finding the spell ID for casted spells.",
                order = 0,
                width = "full",
            },
            header = {
                type = "header", dialogControl = "UCB_Heading",
                name = function ()
                    return "Print Spell ID on cast: " .. (cfgMisc.printSpellIDMode and UIOptions.ColorText(UIOptions.green, "Enabled") or UIOptions.ColorText(UIOptions.red, "Disabled"))
                end,
                order = 1,
                width = "full",
            },
            displaySpellIDToggle = {
                type = "execute", dialogControl = "UCB_Button",
                name = "Print Spell ID on cast",
                order = 2,
                width = 1.5,
                func = function()
                    cfgMisc.printSpellIDMode = not cfgMisc.printSpellIDMode
                end
            },
        },
    }

    local selectGroup = {
        type = "group",
        name = "Select Class Spell",
        inline = true,
        order = 2,
        args = {
            selectedSpell = {
                type = "header",  dialogControl = "UCB_Heading",
                name = function()
                    local info = UIStructures:_SafeSpellInfo(cfg._abilitySelect)
                    if info then
                        return "Selected: " .. UIOptions.ColorText(UIOptions.turquoise, info.name .. " (" .. tostring(info.id) .. ")")
                    end
                    return "Selected: " .. UIOptions.ColorText(UIOptions.red, "None")
                end,
                order = 1,
                width = "full",
            },

            spellDescription = {
                type = "description",
                name = function()
                    local id = tonumber(cfg._abilitySelect)
                    local tooltip = (id and id >= -2147483648 and id <= 2147483647) and C_TooltipInfo.GetSpellByID(id) or nil
                    local spellDesc = tooltip and tooltip.lines and tooltip.lines[4] and tooltip.lines[4].leftText or "No description available."
                    return spellDesc
                end,
                order = 2,
                width = "full",
            },

            selectedSpellId = {
                type = "input", dialogControl = "UCB_EditBox",
                name = "Selected Spell ID",
                order = 3,
                width = 1.5,
                get = function() return tostring(cfg._abilitySelect or "") end,
                set = function(_, v) end,
            },

            v1 = { type = "description", name = "", order = 3.5, width = 0.2 },

            spellSelect = {
                type = "select",
                name = "All Spells For Current Class",
                desc = "Channel + normal + empowered (merged)",
                order = 4,
                width = 1.5,
                values = function()
                    return UIStructures:_BuildAllSpellsDropdownValues()
                end,
                get = function() return cfg._abilitySelect end,
                set = function(_, v) cfg._abilitySelect = v end,
            },
        },
    }
    
    local mainGrp = {
        type = "group",
        name = "Spell Selection",
        inline = true,
        order = order,
        args = {
            displaySpellID = displaySpellID,
            selectSpell = selectGroup,
        },
    }
    return mainGrp
end
