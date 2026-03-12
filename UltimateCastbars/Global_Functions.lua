
local _, UCB = ...

UCB.CFG_API = UCB.CFG_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.Theme = UCB.Theme or {}

local Theme = UCB.Theme

function UCB.UIOptions.ColorText(hex, text)
    if not text then return "" end
    return ("|c%s%s|r"):format(hex, text)
end

function UCB.UIOptions.MakeTitle(text)
    text = tostring(text or "")
    return (text:gsub("^%l", string.upper))
end

function UCB:PrintAddonMsg(msg)  print(self.ADDON_NAME .. ":|r " .. msg) end

function UCB:UnitDisplayName(unit)
  local name = (unit:gsub("^%l", string.upper))
  return name
end


function UCB:NotifyChange()
  if UCB.ACR then
      UCB.ACR:NotifyChange(UCB.GUI.appName)
  end
end

function UCB:SelectGroup(path, unit)
    Theme:AceGUIOverride(function()
        if UCB.ACD then
            if unit == nil then
                UCB.ACD:SelectGroup(UCB.GUI.appName, unpack(path))
            else
                UCB.ACD:SelectGroup(UCB.GUI.appName, unit, unpack(path))
            end
        end
    end)
end

local function startsWith(s, prefix)
    return type(s) == "string" and s:sub(1, #prefix) == prefix
end

function UCB:IsPlayer(unit, exclusive)
    if exclusive then
        return unit == "player"
    else
        return startsWith(unit, "player")
    end
end

function UCB:IsTarget(unit, exclusive)
    if exclusive then
        return unit == "target"
    else
        return startsWith(unit, "target")
    end
end

function UCB:IsFocus(unit, exclusive)
    if exclusive then
        return unit == "focus"
    else
        return startsWith(unit, "focus")
    end
end

function UCB:UnitClassColour(unit)
    local class = UnitClass(unit)
    local colour = {r = 1, g = 1, b = 1, a=0}
    if class ~= nil then
        colour = C_ClassColor.GetClassColor(class)
    end
    return colour
end

--------------------------------------------------------------------------- CFG_API ---------------------------------------------------------------------------
function UCB.CFG_API:GetPathValue(root, key)
    if root == nil then return nil end

    -- single key
    if type(key) ~= "table" then
        return root[key]
    end

    -- path table
    local t = root
    for i = 1, #key do
        if type(t) ~= "table" then return nil end
            t = t[key[i]]
        if t == nil then return nil end
    end
    return t
end


function UCB.CFG_API:SetPath(root, path, value)
  if type(root) ~= "table" or type(path) ~= "table" or #path == 0 then
    return false
  end

  local t = root
  for i = 1, #path - 1 do
    local k = path[i]
    if type(t[k]) ~= "table" then
      return false -- or: t[k] = {} to auto-create
    end
    t = t[k]
  end

  t[path[#path]] = value
  return true
end


-- Get a single variable from the config
function UCB.GetValueConfig(unit, key)
    local profile = UCB.db and UCB.db.profile
    if not profile then return nil end -- DB not ready yet
    if not unit then return profile end
    local root = profile[unit]
    if key == nil then return root end
    if not root then return nil end
    return UCB.CFG_API:GetPathValue(root, key)
end



-- Update a single variable in the PASSIVE config
function UCB.SetValueConfig(unit, key, value)
    local profile = UCB.db and UCB.db.profile
    if not profile then return end -- DB not ready yet

    local root = profile[unit] 
    if not root then return end
    if type(key) == "table" then
        UCB.CFG_API:SetPath(root, key, value)
    else
        root[key] = value
    end
end


