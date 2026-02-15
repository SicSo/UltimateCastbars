local ADDON_NAME, UCB = ...

-- Created APIs
UCB.CFG_API = UCB.CFG_API or {}
UCB.tags = UCB.tags or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.DefBlizzCast = UCB.DefBlizzCast or {}
UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}
UCB.Preview_API = UCB.Preview_API or {}
UCB.Text_API = UCB.Text_API or {}
UCB.CLASS_API = UCB.CLASS_API or {}
UCB.STYLE_API = UCB.STYLE_API or {}
UCB.SimpleFramePicker = UCB.SimpleFramePicker or {}
UCB.Options = UCB.Options or {}
UCB.Default_DB = UCB.Default_DB or {}
UCB.Profiles = UCB.Profiles or {}
UCB.Debug = UCB.Debug or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.UI = UCB.UI or {}

-- Sub APIs
UCB.CLASS_API.Evoker = UCB.CLASS_API.Evoker or {}
UCB.Options.ClassExtraBuilders = UCB.Options.ClassExtraBuilders or {}

UCB.CASTBAR_API.CreateCastbar = UCB.CASTBAR_API.UpdateCastbar -- for backward compatibility

-- Used to hide the default castbar
UCB.defaultCastbarFrame = CreateFrame("Frame")
UCB.defaultCastbarFrame:Hide()

UCB.optionsTable = UCB.optionsTable or {}
UCB._optionsRegistered = UCB._optionsRegistered or {}

UCB.castBar = {} -- The cast bars
UCB.castBarGroup = {} -- The cast bar groups (for anchoring)
UCB.defaultBar = {} -- The default blizz cast bars
UCB.previewActive = {} -- Preview active flags
UCB.eventFrame = {} -- Event frames per unit


UCB.firstBuild = true

UCB.units = {
    "player",
    "target",
    "focus"
}

UCB.events = {
  UNIT_SPELLCAST_START          = "OnUnitSpellcastStart",
  UNIT_SPELLCAST_STOP           = "OnUnitSpellcastStop",
  UNIT_SPELLCAST_CHANNEL_START  = "OnUnitSpellcastChannelStart",
  UNIT_SPELLCAST_CHANNEL_UPDATE = "OnUnitSpellcastChannelUpdate",
  UNIT_SPELLCAST_CHANNEL_STOP   = "OnUnitSpellcastChannelStop",
  UNIT_SPELLCAST_EMPOWER_START  = "OnUnitSpellcastEmpowerStart",
  UNIT_SPELLCAST_EMPOWER_UPDATE = "OnUnitSpellcastEmpowerUpdate",
  UNIT_SPELLCAST_EMPOWER_STOP   = "OnUnitSpellcastEmpowerStop",

  --PLAYER_TARGET_CHANGED 
  
  --UNIT_SPELLCAST_DELAYED = CastUpdate,
	--UNIT_SPELLCAST_FAILED = CastFail,
	--UNIT_SPELLCAST_INTERRUPTED = CastFail,
	--UNIT_SPELLCAST_INTERRUPTIBLE = CastInterruptible,
	--UNIT_SPELLCAST_NOT_INTERRUPTIBLE = CastInterruptible,
}

UCB.swapEvents = {
    PLAYER_TARGET_CHANGED = {"OnUnitChange", "target"},
    PLAYER_FOCUS_CHANGED = {"OnUnitChange", "focus"},
}

UCB.menuUnits = {
    player = true,
    target = true,
    focus = true
}


UCB.trackedUnits = {}

function UCB:EnsureSpellcastEventFrame()
  if UCB.eventFrame.spellcast and UCB.eventFrame.swap then return end

  if not UCB.eventFrame.spellcast then
    local events = UCB.events
    local f1 = CreateFrame("Frame")
    for eventName in pairs(events) do
      f1:RegisterEvent(eventName)
    end

    f1:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
      if not UCB.trackedUnits[unit] then return end
      local resumeCast = false

      local method = events[event]
      local api = UCB.CASTBAR_API
      if method and api and api[method] then
        api[method](api, unit, castGUID, spellID, resumeCast)
      end
    end)

    UCB.eventFrame.spellcast = f1

  end

  if not UCB.eventFrame.swap then 
    local swapEvents = UCB.swapEvents
    local f2 = CreateFrame("Frame")
    for eventName in pairs(swapEvents) do
      f2:RegisterEvent(eventName)
    end

    f2:SetScript("OnEvent", function(_, event)
      local eventInfo = swapEvents[event]
      local method = eventInfo and eventInfo[1]
      local unit = eventInfo and eventInfo[2]
      local api = UCB.CASTBAR_API
      if method and api and api[method] then
        api[method](api, unit)
      end

    end)

    UCB.eventFrame.swap = f2
  end
end


function UCB:SaveDefaultCastbarFrames()
  for unit, tracked in pairs(self.trackedUnits) do
    if tracked then
      self.DefBlizzCast:ApplyDefaultBlizzCastbar(unit, false)
    end
  end
end

function UCB:UpdateCastbarTrackedUnits()
  for unit, tracked in pairs(self.trackedUnits) do
    if tracked then
      self.CASTBAR_API:UpdateCastbar(unit)
    end
  end
end

function UCB:TrackUnit(unit)
  self:EnsureSpellcastEventFrame()
  self.trackedUnits[unit] = true
end

function UCB:UntrackUnit(unit)
  if self.trackedUnits then
    self.trackedUnits[unit] = nil
  end
end

function UCB:SetUpTrackedUnit()
  local cfg = self.CFG_API.GetValueConfig()
  if not cfg then return end
  for unit, shown in pairs(self.menuUnits) do
    local shouldTrack = cfg[unit] and cfg[unit].enabled
    if shouldTrack and shown then
      self:TrackUnit(unit)
    else
      self:UntrackUnit(unit)
    end
  end
end

UCB.tags.var = {
    player = {
        sName = "",
        sTime = 0,
        eTime = 0,
        dTime = 0,
        nIntr = false,
        empStages = {}
    },
    target = {
        sName = "",
        sTime = 0,
        eTime = 0,
        dTime = 0,
        nIntr = false,
        empStages = {}
    },
    focus = {
        sName = "",
        sTime = 0,
        eTime = 0,
        dTime = 0,
        nIntr = false,
        empStages = {}
    },
}

function UCB.UIOptions.ColorText(hex, text)
    return ("|c%s%s|r"):format(hex, text)
end

function UCB:PrintAddonMsg(msg)  print(self.ADDON_NAME .. ":|r " .. msg) end

function UCB:NotifyChange(unit)
  local apps = {"UCB_ROOT"}
  if UCB.ACR then
    for _, app in ipairs(apps) do
      UCB.ACR:NotifyChange(app)
    end
  end
end

function UCB:SelectGroup(unit, path)
  local apps = {"UCB_ROOT"}
  if UCB.ACD then
    for _, app in ipairs(apps) do
      UCB.ACD:SelectGroup(app, unit, unpack(path))
      print(app, unit, unpack(path))
    end
  end
end


local function GetPathValue(root, key)
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

local function SetPath(root, path, value)
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


function UCB:SetUpConfig()
    UCB.cfg = UCB.db.profile
end


-- Update a single variable in the PASSIVE config
function UCB.CFG_API.SetValueConfig(unit, key, value)
    local profile = UCB.db and UCB.db.profile
    if not profile then return end -- DB not ready yet

    local root = profile[unit] 
    if not root then return end
    if type(key) == "table" then
        SetPath(root, key, value)
    else
        root[key] = value
    end
end

-- Get a single variable from the config
function UCB.CFG_API.GetValueConfig(unit, key)
    local profile = UCB.db and UCB.db.profile
    if not profile then return nil end -- DB not ready yet
    if not unit then return profile end
    local root = profile[unit]
    --local root = UCB.db.profile[unit]
    if key == nil then return root end
    if not root then return nil end
    return GetPathValue(root, key)
end


local function createPicker()
    UCB.SimpleFramePickerObj = UCB.SimpleFramePicker:New()
end


local function SetUpPlayerInfo()
    local _, class = UnitClass("player")
    UCB.classColour = UCB.UIOptions.classColoursList[class]
    UCB.className = class
    UCB.specID = PlayerUtil.GetCurrentSpecID()
    UCB.charName = UnitName("player")
end


local function GetSpellType(spellID)
    if spellID and spellID ~= 0 then
        local tooltip = C_TooltipInfo.GetSpellByID(spellID)
        local castText = tooltip and tooltip.lines and tooltip.lines[3] and tooltip.lines[3].leftText

        if castText:lower():find("cast") then
            return "normal"
        elseif castText:lower():find("channeled") then
            return "channel"
        elseif castText:lower():find("empower") then
            return "empowered"
        elseif castText:lower():find("instant") then
            return "instant"
        elseif castText:lower():find("passive") then
            return "passive"
        else
            return "unknown"
        end
    end
    return nil
end



local function SetUpSpellTypes()
  local out = { normal = {}, channel = {}, empowered = {} }
  local seen = { normal = {}, channel = {}, empowered = {} }

  local function add(bucket, spellID)
    if spellID and spellID ~= 0 and not seen[bucket][spellID] then
      seen[bucket][spellID] = true
      out[bucket][#out[bucket] + 1] = spellID
    end
  end

  if not (C_SpellBook
      and C_SpellBook.GetNumSpellBookSkillLines
      and C_SpellBook.GetSpellBookSkillLineInfo
      and C_SpellBook.GetSpellBookItemType
      and Enum and Enum.SpellBookSpellBank) then
    return out
  end

  local bank = Enum.SpellBookSpellBank.Player

  for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
    local info = C_SpellBook.GetSpellBookSkillLineInfo(i)
    if info and info.itemIndexOffset and info.numSpellBookItems then
      local first = info.itemIndexOffset + 1
      local last  = info.itemIndexOffset + info.numSpellBookItems

      for slot = first, last do
        local itemType, actionID, spellID = C_SpellBook.GetSpellBookItemType(slot, bank)
        local isPassive = C_SpellBook.IsSpellBookItemPassive(slot, bank)

        if not isPassive then
          local spellType = GetSpellType(spellID)
          if spellType == "normal" or spellType == "channel" or spellType == "empowered" then
            add(spellType, spellID)
          end
        end
      end
    end
  end

  UCB.allSpellTypes = out

  return out
end

local function ResolveFrames()
  local cfg = UCB.CFG_API.GetValueConfig("player").general
  local delayAcnhor = cfg.anchorDelay
  local delaySync = cfg.syncDelay
  if not UCB.firstBuild then
    delayAcnhor = 0
    delaySync = 0
  end

  if UCB.GeneralSettings_API and UCB.GeneralSettings_API.ResolveAllFramesOnLogin then
    UCB.GeneralSettings_API:ResolveAllFramesOnLogin({
      anchorTries = cfg.anchorFrameTries,
      anchorInterval = cfg.anchorFrameInterval,
      syncTries = cfg.syncFrameTries,
      syncInterval = cfg.syncFrameInterval,
      syncDelay = delaySync,
      anchorDelay = delayAcnhor,
    })
  end
end

local function GatherInfo()
    SetUpPlayerInfo()

    -- delay spell scanning until the world is ready
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        f:UnregisterAllEvents()
        f:SetScript("OnEvent", nil)
        ResolveFrames()

        -- small delay helps tooltip/spellbook settle on first load
        C_Timer.After(0.1, function()
            SetUpSpellTypes()
        end)
    end)
end


local function RegisterGUIPathCommands(cmds, path)
    if type(cmds) ~= "table" or #cmds == 0 then return end
    if type(path) ~= "table" or #path == 0 then return end

    -- Build a unique SlashCmdList key from the first command + path
    local key = "UCB_GUI_" .. tostring(cmds[1]):gsub("[^%w]", "") .. "_" .. table.concat(path, "_"):upper()

    -- Register the slashes
    for i, slash in ipairs(cmds) do
        _G["SLASH_" .. key .. i] = slash
    end

    -- Handler: ONLY OpenGUI with the path
    SlashCmdList[key] = function()
        UCB:OpenGUI(path)
    end
end

local function RegisterDebug(slashStart, funcStart, slashStop, funcStop)
    if slashStart and funcStart then
        SLASH_UCBDEBUGSTART1 = slashStart
        SlashCmdList["UCBDEBUGSTART"] = funcStart
    end

    if slashStop and funcStop then
        SLASH_UCBDEBUGSTOP1 = slashStop
        SlashCmdList["UCBDEBUGSTOP"] = funcStop
    end
end

local function SetupSlashCommands()
    -- Player tab
    RegisterGUIPathCommands(
        { "/ucb", "/ultimatecastbars", "/uc" },
        { "player", "general" }
    )

    -- Target tab
    RegisterGUIPathCommands(
        { "/tcb" },
        { "target", "general" }
    )

    -- Focus tab
    RegisterGUIPathCommands(
        { "/fcb" },
        { "focus", "general" }
    )

    -- Profiles tab
    RegisterGUIPathCommands(
        { "/ucbprof" },
        { "profiles", "management" }
    )

    -- Debug
    RegisterDebug("/ucbdebug", function() UCB.Debug:StartDebug() end,
                "/ucbdebugstop", function() UCB.Debug:StopDebug() end)
    -- reload command
    SLASH_UCBRELOAD1 = "/rl"
    SlashCmdList["UCBRELOAD"] = function() C_UI.Reload() end
end



function UCB:InitSequence()
  UCB.firstBuild = true
  self:SetUpConfig()
  self:SetUpTrackedUnit() -- See which units should be tracked and track them (also ensures event frame is created)
  self:EnsureSpellcastEventFrame() -- Ensure the spellcast event frame exists
  self:SaveDefaultCastbarFrames() -- Save the default blizz castbar frames for tracked units
  self:UpdateCastbarTrackedUnits() -- Create cast bars for tracked units
  self:RegisterRootOptions() -- Create UI
  self.UCB_RegisterLandingPanel() -- Attach Blizzard Landing
  UCB.firstBuild = false
end

function UCB:UpdateAllCastBars()
  self:SetUpConfig()
  self:UpdateCastbarTrackedUnits() -- Upadate cast bars for tracked units
  UCB:OnProfileSwapRefreshUI() -- Refresh UI elements for CFG
  ResolveFrames() -- Resolve frame acnhors for all units
end


function UCB:Init()
  SetupSlashCommands()
  GatherInfo()
  createPicker()
  -- do the once-only setup and initial paint
  self:InitSequence()
end