local _, UCB = ...

UCB.Normiliser = UCB.Normiliser or {}

local Normiliser = UCB.Normiliser

local function GetLSM()
  return LibStub and LibStub("LibSharedMedia-3.0", true)
end

-- -------- dot-path helpers --------
local function GetByPath(root, path)
  local t = root
  for key in string.gmatch(path, "[^%.]+") do
    if type(t) ~= "table" then return nil end
    t = t[key]
  end
  return t
end

local function GetTableAndLeaf(root, path)
  local t = root
  local parts = {}
  for key in string.gmatch(path, "[^%.]+") do parts[#parts+1] = key end
  for i = 1, #parts-1 do
    if type(t) ~= "table" then return nil end
    t = t[parts[i]]
  end
  if type(t) ~= "table" then return nil end
  return t, parts[#parts]
end

local function SetByPath(root, path, value)
  local t, leaf = GetTableAndLeaf(root, path)
  if not t then return false end
  t[leaf] = value
  return true
end

-- -------- LSM helpers --------
local function LSMFetch(mediaType, name)
  local LSM = GetLSM()
  if not LSM or type(name) ~= "string" or name == "" then return nil end
  return LSM:Fetch(mediaType, name, true) -- nil if missing
end

local function LSMNameFromPath(mediaType, path)
  local LSM = GetLSM()
  if not LSM or type(path) ~= "string" or path == "" then return nil end
  local ht = LSM:HashTable(mediaType) -- name -> path
  if type(ht) ~= "table" then return nil end
  for n, p in pairs(ht) do
    if p == path then return n end
  end
  return nil
end

local function GetFallbackName(mediaType, fallbackByType)
  if type(fallbackByType) == "table" and type(fallbackByType[mediaType]) == "string" and fallbackByType[mediaType] ~= "" then
    return fallbackByType[mediaType]
  end
  local LSM = GetLSM()
  if LSM and LSM.GetDefault then
    local def = LSM:GetDefault(mediaType)
    if type(def) == "string" and def ~= "" then return def end
  end
  -- last-resort guesses (adjust to taste)
  if mediaType == "font" then return "Friz Quadrata TT" end
  if mediaType == "statusbar" then return "Blizzard" end
  if mediaType == "background" then return "Blizzard" end
  return "Blizzard"
end

-- Fix one scalar pair at (namePath -> pathPath), for the given mediaType
local function EnsureScalarPair(unit, namePath, pathPath, mediaType, fallbackByType)
  local curName = GetByPath(unit, namePath)
  local curPath = GetByPath(unit, pathPath)

  -- 1) valid name -> enforce correct path
  local fetched = LSMFetch(mediaType, curName)
  if fetched then
    SetByPath(unit, pathPath, fetched)
    return
  end

  -- 2) invalid name -> try reverse from path
  local guessed = LSMNameFromPath(mediaType, curPath)
  local LSM = GetLSM()
  if guessed then
    SetByPath(unit, namePath, guessed)
    SetByPath(unit, pathPath, LSM:Fetch(mediaType, guessed, false))
    return
  end

  -- 3) fallback
  local LSM = GetLSM()
  local fb = GetFallbackName(mediaType, fallbackByType)
  SetByPath(unit, namePath, fb)
  if LSM then
    SetByPath(unit, pathPath, LSM:Fetch(mediaType, fb, false))
  end
end

-- Fix one list pair (arrays of names/paths)
local function EnsureListPair(unit, namePath, pathPath, mediaType, fallbackByType)
  local names = GetByPath(unit, namePath)
  local paths = GetByPath(unit, pathPath)

  if type(names) ~= "table" and type(paths) ~= "table" then return end
  if type(names) ~= "table" then names = {} ; SetByPath(unit, namePath, names) end
  if type(paths) ~= "table" then paths = {} ; SetByPath(unit, pathPath, paths) end

  local fb = GetFallbackName(mediaType, fallbackByType)
  local maxN = math.max(#names, #paths)
  local LSM = GetLSM()

  for i = 1, maxN do
    local fetched = LSMFetch(mediaType, names[i])
    if fetched then
      paths[i] = fetched
    else
      local guessed = LSMNameFromPath(mediaType, paths[i])
      if guessed then
        names[i] = guessed
        paths[i] = LSM:Fetch(mediaType, guessed, false)
      else
        names[i] = fb
        paths[i] = LSM and LSM:Fetch(mediaType, fb, false) or paths[i]
      end
    end
  end
end


function Normiliser:NormalizeUnitTextures_Legacy(unitTable, texture_map, fallbackByType)
  if type(unitTable) ~= "table" or type(texture_map) ~= "table" then return end

  -- If LSM is missing, we can still set fallback names; paths we can't reliably resolve.
  for namePath, entry in pairs(texture_map) do
    if type(namePath) == "string" and type(entry) == "table" then
      local pathPath  = entry.path
      local mediaType = entry.type or "statusbar"
      if type(pathPath) == "string" then
        local vName = GetByPath(unitTable, namePath)
        local vPath = GetByPath(unitTable, pathPath)

        -- Detect list vs scalar by the current stored values
        if type(vName) == "table" or type(vPath) == "table" then
          EnsureListPair(unitTable, namePath, pathPath, mediaType, fallbackByType)
        else
          EnsureScalarPair(unitTable, namePath, pathPath, mediaType, fallbackByType)
        end
      end
    end
  end
end

-- NEW: Generic normalizer that works for textures + fonts (supports wildcard groups: "...*")
function Normiliser:NormalizeUnitLSM(unitTable, map, fallbackByType)
  if type(unitTable) ~= "table" or type(map) ~= "table" then return end

  local function NormalizeWildcardGroup(wildcardPath, entry)
    -- "text.tagList.dynamic.*" -> base "text.tagList.dynamic"
    local base = wildcardPath:gsub("%.%*$", "")
    local tagMap = GetByPath(unitTable, base)
    if type(tagMap) ~= "table" then return end

    local mediaType = entry.type or "font"
    local nameKey   = entry.nameKey or entry.fontNameKey or "fontName"
    local pathKey   = entry.pathKey or entry.fontPathKey or "font"

    local fb = GetFallbackName(mediaType, fallbackByType)
    local LSM = GetLSM()
    
    for _, tagTbl in pairs(tagMap) do
      if type(tagTbl) == "table" then
        local fetched = LSMFetch(mediaType, tagTbl[nameKey])
        if fetched then
          tagTbl[pathKey] = fetched
        else
          local guessed = LSMNameFromPath(mediaType, tagTbl[pathKey])
          if guessed then
            tagTbl[nameKey] = guessed
            tagTbl[pathKey] = LSM and LSM:Fetch(mediaType, guessed, false) or tagTbl[pathKey]
          else
            tagTbl[nameKey] = fb
            tagTbl[pathKey] = LSM and LSM:Fetch(mediaType, fb, false) or tagTbl[pathKey]
          end
        end
      end
    end
  end

  for namePath, entry in pairs(map) do
    if type(namePath) == "string" and type(entry) == "table" then
      -- wildcard group (fonts tag lists)
      if namePath:sub(-2) == ".*" then
        NormalizeWildcardGroup(namePath, entry)
      else
        -- normal scalar/list pair (namePath -> entry.path)
        local pathPath  = entry.path
        local mediaType = entry.type or "statusbar"
        if type(pathPath) == "string" then
          local vName = GetByPath(unitTable, namePath)
          local vPath = GetByPath(unitTable, pathPath)

          if type(vName) == "table" or type(vPath) == "table" then
            EnsureListPair(unitTable, namePath, pathPath, mediaType, fallbackByType)
          else
            EnsureScalarPair(unitTable, namePath, pathPath, mediaType, fallbackByType)
          end
        end
      end
    end
  end
end


function Normiliser:NormalizeUnitTextures(unitTable, fallbackByType)
  return self:NormalizeUnitLSM(unitTable, UCB.profiles.texture_map, fallbackByType)
end


function Normiliser:NormalizeAllUnitTextures(profile, fallbacks)
  if type(profile) ~= "table" then return end
  fallbacks = fallbacks or UCB.profiles.textureFallbacks

  self:NormalizeUnitTextures(profile.player, fallbacks)
  self:NormalizeUnitTextures(profile.target, fallbacks)
  self:NormalizeUnitTextures(profile.focus,  fallbacks)
end


function Normiliser:NormalizeUnitFonts(unitTable, fallbacks)
  return self:NormalizeUnitLSM(unitTable, UCB.profiles.font_map, fallbacks)
end

function Normiliser:NormalizeAllUnitFonts(profile, fallbacks)
  if type(profile) ~= "table" then return end
  fallbacks = fallbacks or UCB.profiles.fontFallbacks

  self:NormalizeUnitFonts(profile.player, fallbacks)
  self:NormalizeUnitFonts(profile.target, fallbacks)
  self:NormalizeUnitFonts(profile.focus,  fallbacks)
end

local function DeepCopySerializable(src, seen)
    local t = type(src)
    if t == "nil" or t == "boolean" or t == "number" or t == "string" then
        return src
    end
    if t ~= "table" then
        return nil -- drop function/userdata/thread
    end

    seen = seen or {}
    if seen[src] then return nil end -- avoid cycles
    seen[src] = true

    local out = {}
    for k, v in pairs(src) do
        local kt = type(k)
        if kt == "string" or kt == "number" then
            local vv = DeepCopySerializable(v, seen)
            if vv ~= nil then
                out[k] = vv
            end
        end
    end
    return out
end

-- Deep copy but only serializable primitives/tables
local function CopyPrimitive(v)
    local t = type(v)
    if t == "nil" or t == "boolean" or t == "number" or t == "string" then
        return v
    end
    return nil
end

-- Filters `src` by the "shape" of `schema` (defaults).
-- Only keys existing in schema are copied.
-- Special handling:
--  - arrays are copied index-wise up to schema length (if schema is an array)
--  - maps with "template entries" can be whitelisted using `mapTemplates`
function Normiliser:FilterBySchema(src, schema, mapTemplates)
    local st = type(schema)
    if st ~= "table" then
        -- leaf: copy primitive only, otherwise fall back to schema
        local pv = CopyPrimitive(src)
        if pv ~= nil then return pv end
        return schema
    end

    if type(src) ~= "table" then
        -- schema expects table but src isn't: return schema defaults
        return schema
    end

    -- If schema table is empty, treat as "freeform container": copy everything serializable
    if next(schema) == nil then
        local t = DeepCopySerializable(src)
        return t or {}
    end


    local out = {}

    -- detect array-like schema (1..n)
    local schemaIsArray = (schema[1] ~= nil)
    if schemaIsArray then
        for i = 1, #schema do
            out[i] = Normiliser:FilterBySchema(src[i], schema[i], mapTemplates)
        end
        return out
    end

    -- normal keyed schema
    for k, vSchema in pairs(schema) do
        local vSrc = src[k]
        out[k] = Normiliser:FilterBySchema(vSrc, vSchema, mapTemplates)
    end

    -- Optional: handle "map tables" where keys aren't fixed, but each entry has a template
    -- mapTemplates is a table of paths -> template schema
    -- e.g. mapTemplates["text.tagList.dynamic"] = schema.text.tagList.dynamic.tag2 (template)
    if mapTemplates then
        for path, template in pairs(mapTemplates) do
            -- path walker that returns outTable and srcTable at that path
            local function GetAtPath(root, p)
                local t = root
                for seg in string.gmatch(p, "[^%.]+") do
                    if type(t) ~= "table" then return nil end
                    t = t[seg]
                end
                return t
            end

            local outMap = GetAtPath(out, path)
            local srcMap = GetAtPath(src, path)

            if type(outMap) == "table" and type(srcMap) == "table" then
                -- copy ALL entries from srcMap, but filter each entry by template
                -- IMPORTANT: we still keep existing schema keys too.
                for entryKey, entryVal in pairs(srcMap) do
                    if type(entryKey) == "string" then
                        outMap[entryKey] = Normiliser:FilterBySchema(entryVal, template, mapTemplates)
                    end
                end
            end
        end
    end

    return out
end

function Normiliser:DeepCopyTable(src, seen)
    if type(src) ~= "table" then return src end
    seen = seen or {}
    if seen[src] then return seen[src] end
    local out = {}
    seen[src] = out
    for k, v in pairs(src) do
        if type(v) ~= "function" and type(v) ~= "userdata" and type(v) ~= "thread" then
            out[k] = Normiliser:DeepCopyTable(v, seen)
        end
    end
    return out
end

function Normiliser:Overlay(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then return end
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
            Normiliser:Overlay(dst[k], v)
        else
            dst[k] = v
        end
    end
end


function UCB:NormalizeCurrentProfileToSchema()
    UCB:RegisterMigrations()
    local ok, err = UCB.Migration.Apply(UCB.db.profile, { schemaKey = "__schemaVersion" })
    if not ok then
        return false, err
    end

    local defaults = UCB:GetDefaultDB()
    local schemaProfile = defaults and defaults.profile
    if not schemaProfile then return false, "No default schema found." end

    -- Take what you currently have, but only keys in schema
    local filtered = Normiliser:FilterBySchema(UCB.db.profile, schemaProfile)

    -- IMPORTANT: also preserve extra tags, clamped, like you do on import/export
    local function ExpandTagListsFromCurrent(unitKey)
        local srcUnit = UCB.db.profile[unitKey]
        local dstUnit = filtered[unitKey]
        if type(srcUnit) ~= "table" or type(dstUnit) ~= "table" then return end

        local schemaUnit = schemaProfile[unitKey]
        local template   = schemaUnit and schemaUnit.text and schemaUnit.text.defaultValues
        if type(template) ~= "table" then return end

        local srcText = srcUnit.text
        local dstText = dstUnit.text
        if type(srcText) ~= "table" or type(dstText) ~= "table" then return end

        local srcTagList = srcText.textList
        if type(srcTagList) ~= "table" then return end

        dstText.textList = dstText.textList or {}

        local outMap = {}
        for tagKey, tagTable in pairs(srcTagList) do
            if type(tagKey) == "string" and type(tagTable) == "table" then
                outMap[tagKey] = Normiliser:FilterBySchema(tagTable, template)
            end
        end
        dstText.textList = outMap
    end

    ExpandTagListsFromCurrent("player")
    ExpandTagListsFromCurrent("target")
    ExpandTagListsFromCurrent("focus")

    -- Rebuild full schema with defaults, then overlay what you have
    local rebuilt = Normiliser:DeepCopyTable(schemaProfile)
    Normiliser:Overlay(rebuilt, filtered)

     Normiliser:NormalizeAllUnitTextures(rebuilt)
     Normiliser:NormalizeAllUnitFonts(rebuilt)

    wipe(UCB.db.profile)
    for k, v in pairs(rebuilt) do
        UCB.db.profile[k] = v
    end

    return true
end