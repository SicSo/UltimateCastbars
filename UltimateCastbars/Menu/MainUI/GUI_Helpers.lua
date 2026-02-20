local ADDON_NAME, UCB = ...

UCB.GUI = UCB.GUI or {}
UCB.UI = UCB.UI or {}
UCB.GUI.Helpers = UCB.GUI.Helpers or {}

-- GUIWidgets should be loaded before this file (or you can require it first)
local UI = UCB.UI
local GUI = UCB.GUI
local GUI_Helpers = UCB.GUI.Helpers

--local ACD = LibStub("AceConfigDialog-3.0")
local SEP = "\001"

local function AppendPackedSelected(path, sel)
  if type(sel) ~= "string" or sel == "" then return false end

  local changed = false
  if sel:find(SEP, 1, true) then
    for part in sel:gmatch("([^\001]+)") do
      if part ~= "" and path[#path] ~= part then
        path[#path + 1] = part
        changed = true
      end
    end
  else
    if path[#path] ~= sel then
      path[#path + 1] = sel
      changed = true
    end
  end

  return changed
end

-- Reads the live UI selection path as {"player","general",...}
function GUI_Helpers:GetCurrentPath(appName)
  local path = {}
  local statusKey = nil -- this is the "container path" to ask status for

  while true do
    local st = UCB.ACD:GetStatusTable(appName, statusKey)
    if not st or type(st.groups) ~= "table" then break end

    local sel = st.groups.selected
    if not AppendPackedSelected(path, sel) then break end

    -- Advance statusKey for the *next container level*.
    -- In Ace, status tables are stored as children keyed by group keys. :contentReference[oaicite:3]{index=3}
    statusKey = path
  end

  return (#path > 0) and path or nil
end


--local ACR = LibStub("AceConfigRegistry-3.0")

-- Returns: ok, fixedPath, badIndex
-- ok=true if full path exists as groups
-- fixedPath is the longest valid prefix (at least 1 element if possible)
local function NormalizePath(input)
  if type(input) ~= "table" then return nil end
  local out = {}
  for i = 1, #input do
    local s = input[i]
    if type(s) == "string" and s ~= "" then
      if s:find(SEP, 1, true) then
        for part in s:gmatch("([^\001]+)") do
          if part ~= "" and out[#out] ~= part then
            out[#out+1] = part
          end
        end
      else
        if out[#out] ~= s then
          out[#out+1] = s
        end
      end
    end
  end
  return (#out > 0) and out or nil
end

-- ok, validPrefix, badIndex, reason
function GUI_Helpers:ValidateGroupPath(path)
  local opt = GUI.optionsTable
  if type(opt) ~= "table" or type(opt.args) ~= "table" then
    return false, nil, 1, "root options/args missing (did you RegisterRootOptions?)"
  end

  local p = NormalizePath(path)
  if not p then return false, nil, 1, "path empty/invalid" end

  local cur = opt
  local out = {}

  for i = 1, #p do
    if type(cur.args) ~= "table" then
      return false, out, i, "parent has no args table at this level"
    end

    local key = p[i]
    local node = cur.args[key]
    if type(node) ~= "table" then
      return false, out, i, ("missing key '%s'"):format(tostring(key))
    end
    if node.type ~= "group" then
      return false, out, i, ("'%s' is not a group (type=%s)"):format(tostring(key), tostring(node.type))
    end

    out[#out+1] = key
    cur = node
    -- NOTE: we do NOT require cur.args to exist here.
    -- It’s still a valid selectable group even if args=nil/empty.
  end

  return true, out, nil, nil
end