local ADDON_NAME, UCB = ...

UCB.Copy = UCB.Copy or {}

local Copy = UCB.Copy

local function IsArray(t)
  if type(t) ~= "table" then return false end

  local max = 0
  local count = 0

  for k, _ in pairs(t) do
    if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
      return false -- has a non-integer key => not an array
    end
    if k > max then max = k end
    count = count + 1
  end

  -- empty table counts as an array (if you want that)
  if count == 0 then return true end

  -- must be contiguous: number of elements must equal max index
  -- (this rejects holes like {[1]=x, [3]=y} because count=2, max=3)
  return count == max
end

local function DeepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value] -- cycle-safe
    end

    local copy = {}
    seen[value] = copy

    for k, v in pairs(value) do
        copy[DeepCopy(k, seen)] = DeepCopy(v, seen)
    end

    return copy
end

-- Main: arrays replaced; non-array tables merged by common keys only.
local function ReplaceCommonKeys_ArraysReplace(dst, src, def, seen)
    if type(dst) ~= "table" or type(src) ~= "table" or type(def) ~= "table" then return end

    seen = seen or {}
    if seen[dst] then return end
    seen[dst] = true

    -- iterate defaults so only default-defined keys are considered
    for k, defVal in pairs(def) do
        local dstVal = dst[k]
        local srcVal = src[k]

        -- common between 3: key exists in def, dst, and src (src must be non-nil)
        if dstVal ~= nil and srcVal ~= nil then
            if type(dstVal) == "table" and type(srcVal) == "table" and type(defVal) == "table" then
                if IsArray(defVal) then
                    dst[k] = DeepCopy(srcVal)
                else
                    ReplaceCommonKeys_ArraysReplace(dstVal, srcVal, defVal, seen)
                end
            elseif type(srcVal) == "table" then
                dst[k] = DeepCopy(srcVal)
            else
                dst[k] = srcVal
            end
        end
    end
end


-- Keys that should be fully replaced (rebuilt) instead of merged
local TEXTLIST_REPLACE = {
    textList = true,
}

local function ReplaceCommonKeys_ArraysReplace_Text(dst, src, def, seen)
    if type(dst) ~= "table" or type(src) ~= "table" or type(def) ~= "table" then return end

    seen = seen or {}
    if seen[dst] then return end
    seen[dst] = true

    for k, defVal in pairs(def) do
        local dstVal = dst[k]
        local srcVal = src[k]

        if dstVal ~= nil and srcVal ~= nil then
            -- If this key is a full-replace text container, do it and skip recursion
            if TEXTLIST_REPLACE[k] and type(srcVal) == "table" then
                dst[k] = DeepCopy(srcVal)

            elseif type(dstVal) == "table" and type(srcVal) == "table" and type(defVal) == "table" then
                if IsArray(defVal) then
                    -- arrays get replaced wholesale
                    dst[k] = DeepCopy(srcVal)
                else
                    -- normal table merge
                    ReplaceCommonKeys_ArraysReplace_Text(dstVal, srcVal, defVal, seen)
                end

            elseif type(srcVal) == "table" then
                dst[k] = DeepCopy(srcVal)
            else
                dst[k] = srcVal
            end
        end
    end
end

function Copy:StandardCopy(unitDest, unitSrc, key)
    local aux_key = key
    local dst = UCB.GetValueConfig(unitDest, aux_key)
    local src = UCB.GetValueConfig(unitSrc, aux_key)
    if not dst or not src then return false end
    local default_db = UCB.Default_DB[unitDest][aux_key]
    ReplaceCommonKeys_ArraysReplace(dst, src, default_db)
    return true
end

function Copy:TextCopy(unitDest, unitSrc)
    local dst = UCB.GetValueConfig(unitDest, "text")
    local src = UCB.GetValueConfig(unitSrc, "text")
    if not dst or not src then return false end
    local default_db = UCB.Default_DB[unitDest].text
    ReplaceCommonKeys_ArraysReplace_Text(dst, src, default_db)
    return true
end

function Copy:CopySettings(unitDest, unitSrc, keys)
    local copyOne = false
    for k, use in pairs(keys) do
        if use then
            copyOne = true
            if k == "text" then
                self:TextCopy(unitDest, unitSrc)
            else
                self:StandardCopy(unitDest, unitSrc, k)
            end
        end
    end
    return copyOne
end