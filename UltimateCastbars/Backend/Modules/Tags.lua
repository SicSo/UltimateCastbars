
local _, UCB = ...

UCB.tags = UCB.tags or {}

local tags = UCB.tags



local function FormatDecimals(n, x)
    if x ==-1 then x=1 end
    if type(n) ~= "number" then return "" end
    x = tonumber(x) or 0
    if x < 0 then x = 0 end
    return string.format("%." .. x .. "f", n)
end

local function FirstNChars(s, x)
    if x == -1 then return s end
    if type(s) ~= "string" then return "" end
    x = tonumber(x) or 0
    if x <= 0 then return "" end
    local res = s:sub(1, x)

    if #s <= x then return res end
    return res.."..."
end

local TAG_FN = {}

TAG_FN["[sName]"] = function(v, limNum)
    return FirstNChars(v.sName, limNum)
end

TAG_FN["[dTime]"] = function(v, limNum)
    return FormatDecimals(v.dTime, limNum)
end

TAG_FN["[dPerTime]"] = function()
    return "100"
end

TAG_FN["[rTime]"] = function(v, limNum, remaining)
    local t = remaining ~= nil and remaining or v.durationObject:GetRemainingDuration()
    return FormatDecimals(t, limNum)
end

TAG_FN["[rPerTime]"] = function(v, limNum)
    local durOb = v.durationObject
    local perTime = durOb:GetRemainingPercent()
    return FormatDecimals(perTime, limNum)
end

TAG_FN["[rTimeInv]"] = function(v, limNum, remaining, elpased)
    local t = elpased ~= nil and elpased or v.durationObject:GetElapsedDuration()
    return FormatDecimals(t, limNum)
end

TAG_FN["[rPerTimeInv]"] = function(v, limNum)
    local durOb = v.durationObject
    local perTimeInv = durOb:GetElapsedPercent()
    return FormatDecimals(perTimeInv, limNum)
end

-- NOTE: these use limRaw as a payload when not -1
TAG_FN["[nIntr]"] = function(v, limNum, remaining, elpased, limRaw)
    return (limNum == -1) and "Unintr." or limRaw
end

TAG_FN["[nIntrInv]"] = function(v, limNum, remaining, elpased, limRaw)
    return (limNum == -1) and "Intr." or limRaw
end

function tags:compileFormula(formula, limits)
    local ops = {}
    local n = 0
    local needsNow = false

    for i = 1, #formula do
        local part = formula[i]
        local fn = TAG_FN[part]

        if fn then
            local limRaw = limits and limits[i]
            local limNum
            if limRaw == nil then
                limNum = -1
            elseif type(limRaw) == "string" then
                -- treat string as "unset" for numeric formatting, but keep raw
                limNum = -1
            else
                limNum = limRaw
            end

            -- only time-dependent tags need GetTime()
            if part == "[rTime]" or part == "[rPerTime]" or part == "[rTimeInv]" or part == "[rPerTimeInv]" then
                needsNow = true
            end

            local show = ""
            if part == "[nIntr]" or part == "[nIntrInv]" then
                show = part
            end

            n = n + 1
            ops[n] = { fn = fn, limNum = limNum, limRaw = limRaw , show = show }
        else
            n = n + 1
            ops[n] = part
        end
    end

    ops._needsNow = needsNow
    return ops
end




-- !!!!!!!!!!!!!!!!!!!!!!! DYNAMIC UPDATE FUNCTION !!!!!!!!!!!!!!!!!!!!!!!!
local function join(t, sep, n)
  sep = sep or ""
  n = n or #t
  if n <= 0 then return "" end

  -- start with first element to avoid leading sep checks
  local s = tostring(t[1])
  for i = 2, n do
    s = s .. sep .. tostring(t[i])
  end
  return s
end

function tags:processCompiled(ops, unit, remainingTime, elpasedTime)
    local v = self.var[unit]

    local out = self._out
    if not out then out = {}; self._out = out end
    local show = nil

    local outN = 0
    for i = 1, #ops do
        local op = ops[i]
        outN = outN + 1
        if type(op) == "table" then
            out[outN] = op.fn(v, op.limNum, remainingTime, elpasedTime, op.limRaw)
        else
            out[outN] = op
        end

        if op.show == "[nIntr]" then
            show = v.nIntr
        end
        if op.show == "[nIntrInv]" then
            if unit == "player" then
                show = not v.nIntr
            else
                show = true
                out[outN] = "[nIntrInv_INVALID_"..unit.."]"
            end
        end
    end

    for i = outN + 1, #out do out[i] = nil end

    --return table.concat(out, "", 1, outN)
    return join(out, ""), show
end



local function ParseTagLimit(token, openDelim, closeDelim)
  -- token includes delimiters, e.g. "[rTime:2]"
  -- returns: normalizedToken, suffixValue (number | string | -1)

  if #token <= (#openDelim + #closeDelim) then
    return token, -1
  end

  local inner = token:sub(#openDelim + 1, #token - #closeDelim)

  -- split on FIRST colon; suffix can be empty
  local name, suffix = inner:match("^([^:]+):(.*)$")
  if name then
    local normalized = openDelim .. name .. closeDelim

    -- empty suffix -> -1
    if suffix == "" then
      return normalized, -1
    end

    -- numeric suffix -> number, else keep string
    local n = tonumber(suffix)
    if n ~= nil then
      return normalized, n
    end

    return normalized, suffix
  end

  -- no colon found (or doesn't match): unchanged token, -1
  return token, -1
end


function tags:splitTags(s, openDelim, closeDelim)
    assert(type(s) == "string", "s must be a string")
    assert(type(openDelim) == "string" and #openDelim > 0, "openDelim must be non-empty")
    assert(type(closeDelim) == "string" and #closeDelim > 0, "closeDelim must be non-empty")

    local state  = "static"
    local out    = {}
    local limits = {}
    local i = 1

    while true do
        local a, b = s:find(openDelim, i, true) -- plain find (no patterns)
        if not a then
            local tail = s:sub(i)
            if tail ~= "" then
                table.insert(out, tail)
                table.insert(limits, -1)
            end
            break
        end

        local before = s:sub(i, a - 1)
        if before ~= "" then
            table.insert(out, before)
            table.insert(limits, -1)
        end

        local c, d = s:find(closeDelim, b + 1, true)
        if not c then
            -- no closing delimiter: treat the rest as plain text (including the openDelim)
            local rest = s:sub(a)
            if rest ~= "" then
                table.insert(out, rest)
                table.insert(limits, -1)
            end
            break
        end

        -- Extract token INCLUDING delimiters, then parse optional :X
        local rawToken = s:sub(a, d)
        local token, lim = ParseTagLimit(rawToken, openDelim, closeDelim)

        table.insert(out, token)
        table.insert(limits, lim)

        -- Your state logic (now compares against normalized tags like "[rTime]")
        if state ~= "dynamic" then
            if token == "[rTime]" or token == "[rPerTime]" or token == "[rTimeInv]" or token == "[rPerTimeInv]" then
                state = "dynamic"
            elseif state ~= "semiDynamic" then
                if token == "[dTime]" or token == "[dPerTime]" or token == "[sName]" or token == "[nIntr]" or token == "[nIntrInv]" then
                    state = "semiDynamic"
                end
            end
        end

        i = d + 1
    end

    return out, limits, state
end


function tags:updateVars(unit, type, spellID)
    local name, texture, notInterruptible, durationObject
    local vars = tags.var[unit]
    if vars.empStages then
        table.wipe(vars.empStages)
    end
    if type == "normal" or type == "channel" then 
        if type == "normal" then
            durationObject = UnitCastingDuration(unit)
            name, _, texture, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
        else
            durationObject = UnitChannelDuration(unit)
            name, _, texture, _, _, _, notInterruptible = UnitChannelInfo(unit)
        end
    else
        name, _, texture, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
        durationObject = UnitEmpoweredChannelDuration(unit)
        local stages = UnitEmpoweredStagePercentages(unit, true)
        if unit == "player" then
            local temp_sum = 0
            for i = 1, #stages do
                vars.empStages[i] = stages[i] + temp_sum
                temp_sum = temp_sum + stages[i]
            end
        else
            -- Generic ticks for non-player units
            local numStages = #stages
            if numStages == 5 then
                vars.empStages =  {0.19, 0.33, 0.47, 0.60, 0.999}
            elseif numStages == 4 then
                vars.empStages = {0.24, 0.42, 0.60, 0.999}
            else
                for i = 1, numStages do
                    vars.empStages[i] = i / (numStages + 1)
                end
            end
        end
    end
    if durationObject then
        vars.sName = name
        vars.sTime = durationObject:GetStartTime()
        vars.eTime = durationObject:GetEndTime()
        vars.dTime = durationObject:GetTotalDuration()
        vars.nIntr = notInterruptible
    else
        -- Fallback for missing duration object (shouldn't happen, but just in case)
        vars.sName = name or "Unknown Spell"
        vars.sTime = 0
        vars.eTime = 0
        vars.dTime = 0
        vars.nIntr = notInterruptible or false
    end
    vars.durationObject = durationObject
    return texture
end


function tags:updateVarsPreview(unit, type, spellID, duration, notInterruptible, stageCount)
    local now = GetTime()
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local texture = spellInfo and spellInfo.originalIconID or 136243 -- default icon (question mark)
    local vars = tags.var[unit]
    vars.sName = spellInfo and spellInfo.name or "Test Spell"
    vars.sTime = now
    vars.eTime = now + duration
    vars.dTime = duration
    vars.nIntr  = notInterruptible
    local durationObject = C_DurationUtil.CreateDuration()
    durationObject:SetTimeFromStart(now, duration)
    vars.durationObject = durationObject
    if type == "empowered" then
        local totalDuration = duration
        for i = 1, stageCount do
            vars.empStages[i] = (((totalDuration / stageCount) * 100) / totalDuration) / 100  * i
        end
    end
    return texture
end


function tags:PrepareTextState(cfgText, bar, state, castType)
    local tagList = cfgText.tagList[state]
    if not tagList then return end

    -- per-state cache on the bar
    local activeByState = bar._activeTags
    if not activeByState then
        activeByState = {}
        bar._activeTags = activeByState
    end

    local active = activeByState[state]
    if not active then
        active = {}
        activeByState[state] = active
    else
        for i = #active, 1, -1 do active[i] = nil end
    end

    -- decide show/hide ONCE, store only active entries for fast loops later
    for key, tagOptions in next, tagList do
        local fs = bar.texts[key]
        if fs then
            local show = tagOptions.show
            if show and castType ~= nil  then
                local st = tagOptions.showType
                show = st and st[castType]
            end

            if show then
                --print(key)
                fs:Show()
                active[#active + 1] = {
                    fs = fs,
                    formula = tagOptions._formula,
                    limits  = tagOptions._limits,
                    compiled = tagOptions._compiled,
                }
            else
                fs:Hide()
            end
        end
    end
end

function tags:updateTagText(key, cfg, bigCFG)
    local out, limits, state = tags:splitTags(cfg.tagText, UCB.tags.openDelim, UCB.tags.closeDelim)


    local textIsDynamic
    if state == "dynamic" or state == "semiDynamic" then
        textIsDynamic = true
    else
        textIsDynamic = false
    end

    if state == "static" and (not cfg.showType.normal or not cfg.showType.channel or not cfg.showType.empowered) then
        state = "semiDynamic"
    end

    local oldTag = tags.typeTags[cfg._type]
    cfg._formula = out
    cfg._limits = limits
    cfg._type = tags.typeNames[state]
    cfg._typeColour = tags.colours[state]

    if oldTag ~= state then
        bigCFG.tagList[state][key] = cfg
        if oldTag then
            bigCFG.tagList[oldTag][key] = nil
        end
    end
    bigCFG.tagList[state][key]._dynamicTag = textIsDynamic


end

-- !!!!!!!!!!!!!!!!!!!!!!! DYNAMIC UPDATE FUNCTION !!!!!!!!!!!!!!!!!!!!!!!!
function tags:ApplyTextState(bar, state, unit, remaining, elapsed)
    local active = bar._activeTags and bar._activeTags[state]
    if not active then return end

    for i = 1, #active do
        local t = active[i]
        local text, showText = tags:processCompiled(t.compiled, unit, remaining, elapsed)
        t.fs:SetText(text)
        local secret = issecretvalue(showText)
        if secret or (not secret and showText ~= nil) then
            --t.fs:SetShown(showText)
            t.fs:SetAlphaFromBoolean(showText)
        end

    end
end


function tags:setTextSameState(cfgText, bar, state, unit, castType, prepareOnly, remaining)
    -- If prepareOnly=true, only do show/hide + build active list
    -- Otherwise do both (prepare then apply)
    self:PrepareTextState(cfgText, bar, state, castType)

    if not prepareOnly then
        self:ApplyTextState(bar, state, unit, remaining)
    end
end
