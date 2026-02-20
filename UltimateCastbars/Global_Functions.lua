
local _, UCB = ...

UCB.CFG_API = UCB.CFG_API or {}
UCB.UIOptions = UCB.UIOptions or {}

function UCB.UIOptions.ColorText(hex, text)
    if not text then return "" end
    return ("|c%s%s|r"):format(hex, text)
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
  if UCB.ACD then
    if unit == nil then
      UCB.ACD:SelectGroup(UCB.GUI.appName, unpack(path))
    else
      UCB.ACD:SelectGroup(UCB.GUI.appName, unit, unpack(path))
    end
  end
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


