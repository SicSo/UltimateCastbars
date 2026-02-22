local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.tags = UCB.tags or {}
UCB.Text_API = UCB.Text_API or {}

local CASTBAR_API = UCB.CASTBAR_API
local tags = UCB.tags
local Text_API = UCB.Text_API

UCB.Options._tagTreeArgs = UCB.Options._tagTreeArgs or {}

local LSM  = UCB.LSM


local function DeepCopy(src, seen)
  if type(src) ~= "table" then return src end
  if seen and seen[src] then return seen[src] end

  seen = seen or {}
  local dst = {}
  seen[src] = dst

  for k, v in pairs(src) do
    dst[DeepCopy(k, seen)] = DeepCopy(v, seen)
  end

  return dst
end

function Text_API:OutlineFlags(outline)
    local flags = {}
    local shadow = false
    if outline == "OUTLINE" or outline == "SHADOW_OUTLINE"  or outline == "MONO_OUTLINE" then
        table.insert(flags, "OUTLINE")
    end
    if outline == "THICKOUTLINE" or outline == "SHADOW_THICKOUTLINE"  or outline == "MONO_THICKOUTLINE" then
        table.insert(flags, "THICKOUTLINE")
    end
    if outline == "MONO_NONE" or outline == "MONO_OUTLINE" or outline == "MONO_THICKOUTLINE" then
        table.insert(flags, "MONOCHROME")
    end
    if outline == "SHADOW" or outline == "SHADOW_OUTLINE" or outline == "SHADOW_THICKOUTLINE" then
        shadow = true
    end
    return flags, shadow
end

function Text_API:MakeLSMFontOption(cfg, order, applyFont, disabledFn, unit)
    return {
        type          = "select",
        dialogControl = "LSM30_Font",
        name          = "Font",
        order         = order or 1,
        values        = function() return LSM:HashTable("font") end,

        get = function()
            return cfg.fontName or LSM:GetDefault("font")
        end,

        set = function(_, val)
            cfg.fontName = val
            cfg.font = LSM:Fetch("font", val)
            if type(applyFont) == "function" then
                applyFont()
            end
            CASTBAR_API:UpdateCastbar(unit)
        end,

        disabled = disabledFn,
    }
end


local function missing_and_next_max(t, prefix)
  prefix = prefix or "tag"

  local used = {}
  local maxN = 0

  -- extract keys from the table
  for k, _ in pairs(t) do
    if type(k) == "string" then
      local n = k:match("^" .. prefix .. "(%d+)$")
      if n then
        n = tonumber(n)
        if n and n >= 1 then
          used[n] = true
          if n > maxN then maxN = n end
        end
      end
    end
  end

  -- missing numbers from 1..maxN
  local missing = {}
  for i = 1, maxN do
    if not used[i] then
      missing[#missing + 1] = i
    end
  end

  -- biggest unused = max used + 1
  local nextNum = maxN + 1

  return missing, nextNum
end

function Text_API:addNewTag(bigCFG, name, unit)
    local key

    local missing, nextNum = missing_and_next_max(bigCFG.textList, "tag") -- ensure oldIDTags is populated

    if #missing > 0 then
        key = "tag" .. missing[1]
    else
        key = "tag" .. nextNum
    end

    bigCFG.textList = bigCFG.textList or {}

    local newTag = DeepCopy(bigCFG.defaultValues)
    newTag.name = name
    bigCFG.textList[key] = newTag

    tags:updateTagText(key, newTag, unit)

    return key, newTag
end

function Text_API:deleteTag(key, cfg, bigCFG, unit)
    local state = tags.typeTags[cfg._type]
    local tagList = tags.tagGroups[unit]
    tagList[state][key] = nil
    bigCFG.textList[key] = nil
    local id = tonumber(key:match("tag(%d+)"))
    if id then
        table.insert(bigCFG.oldIDTags, id)
    end
end

function Text_API:updateStaticShow(key, cfg, unit)
    if cfg.maintype ~= "cast" then return false end
    local tagList = tags.tagGroups[unit]
   
    if tags.typeTags[cfg._type] == "static" then
        if cfg.showType.normal == true and cfg.showType.channel == true and cfg.showType.empowered == true then
            return false
        end
        tagList.semiDynamic[key] = cfg
        cfg._type = tags.typeNames.semiDynamic
        cfg._typeColour = tags.colours.semiDynamic
        tagList.static[key] = nil
        return true
    end
    if tags.typeTags[cfg._type] == "semiDynamic" and cfg._dynamicTag == false then
        if cfg.showType.normal == true and cfg.showType.channel == true and cfg.showType.empowered == true then
            tagList.static[key] = cfg
            cfg._type = tags.typeNames.static
            cfg._typeColour = tags.colours.static
            tagList.semiDynamic[key] = nil
            return true
        end
    end
    return false
end

function Text_API:updateTagMainType(key, cfg, bigCFG)
    tags:updateTagText(key, cfg, bigCFG)
end