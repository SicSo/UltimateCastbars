local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.tags = UCB.tags or {}
UCB.Text_API = UCB.Text_API or {}

local Opt = UCB.Options
local CASTBAR_API = UCB.CASTBAR_API
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
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


function Text_API:addNewTag(bigCFG, name)
    local key
    if bigCFG.oldIDTags and #bigCFG.oldIDTags > 0 then
        key = "tag" .. table.remove(bigCFG.oldIDTags, 1)
    else
        bigCFG.newIDTags = bigCFG.newIDTags or 1
        key = "tag" .. tostring(bigCFG.newIDTags)
        bigCFG.newIDTags = bigCFG.newIDTags + 1
    end

    bigCFG.tagList = bigCFG.tagList or {}
    bigCFG.tagList.unk = bigCFG.tagList.unk or {}

    local newTag = DeepCopy(bigCFG.defaultValues)
    newTag.name = name
    bigCFG.tagList.unk[key] = newTag

    return key, newTag, "unk"
end

function Text_API:updateTagText(key, cfg, bigCFG)
    local out, limits, state = tags:splitTags(cfg.tagText, UCB.tags.openDelim, UCB.tags.closeDelim)


    local textIsDynamic
    if state == "dynamic" or state == "semiDynamic" then
        textIsDynamic = true
    else
        textIsDynamic = false
    end

    if state == "static" and not cfg.showType.normal or not cfg.showType.channel or not cfg.showType.empowered then
        state = "semiDynamic"
    end

    local oldTag = tags.typeTags[cfg._type]
    cfg._formula = out
    cfg._limits = limits
    cfg._type = tags.typeNames[state]
    cfg._typeColour = tags.colours[state]

    if oldTag ~= state then
        bigCFG.tagList[state][key] = cfg
        bigCFG.tagList[oldTag][key] = nil
    end
    bigCFG.tagList[state][key]._dynamicTag = textIsDynamic


end

function Text_API:deleteTag(key, cfg, bigCFG)
    local state = tags.typeTags[cfg._type]
    bigCFG.tagList[state][key] = nil
    local id = tonumber(key:match("tag(%d+)"))
    if id then
        table.insert(bigCFG.oldIDTags, id)
    end
end

-- TODO: Fix
function Text_API:updateStaticShow(key, cfg, bigCFG)
    if tags.typeTags[cfg._type] == "static" then
        if cfg.showType.normal == true and cfg.showType.channel == true and cfg.showType.empowered == true then
            return false
        end
        bigCFG.tagList.semiDynamic[key] = cfg
        cfg._type = tags.typeNames.semiDynamic
        cfg._typeColour = tags.colours.semiDynamic
        bigCFG.tagList.static[key] = nil
        return true
    end
    if tags.typeTags[cfg._type] == "semiDynamic" and cfg._dynamicTag == false then
        if cfg.showType.normal == true and cfg.showType.channel == true and cfg.showType.empowered == true then
            bigCFG.tagList.static[key] = cfg
            cfg._type = tags.typeNames.static
            cfg._typeColour = tags.colours.static
            bigCFG.tagList.semiDynamic[key] = nil
            return true
        end
    end
    return false
end