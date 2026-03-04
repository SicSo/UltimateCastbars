local _, UCB = ...

UCB_ASSETS = UCB_ASSETS or {}


function UCB:LoadAssets(loadAssets)
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if not LSM then return end

  -- If you generate a mapping file (recommended), load it BEFORE this file.
  -- It should define: UCB_ASSETS = { statusbar = {...}, sound = {...}, ... }
  -- Your Python script can output that table.
  if type(UCB_ASSETS) ~= "table" then
    -- No mapping loaded; nothing to register
    return
  end

  local BASE = "Interface\\AddOns\\UltimateCastbars\\gfx\\Assets\\"

  local TYPE_MAP = {
    statusbar  = "statusbar",
    sound      = "sound",
    background = "background",
    border     = "border",
    font       = "font",
  }

  -- Safety: ensure we always pass LSM a string path.
  local function normalizePath(p)
    if type(p) ~= "string" then return nil end
    -- If your mapping already contains full Interface\\... paths, use as-is.
    if p:find("^Interface\\") then return p end
    -- Otherwise treat it as relative to our BASE.
    return BASE .. p
  end

  for section, lsmType in pairs(TYPE_MAP) do
    local t = loadAssets[section] and UCB_ASSETS[section] or nil
    if t and type(t) == "table" then
      for name, path in pairs(t) do
        local p = normalizePath(path)
        if p then
          -- name is whatever you want shown in dropdowns.
          -- Consider prefixing to avoid collisions: "UCB: " .. name
          LSM:Register(lsmType, name, p)
        end
      end
    end
  end
end