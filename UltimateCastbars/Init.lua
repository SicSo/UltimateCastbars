local ADDON_NAME, UCB = ...


UCB.ADDON_NAME = C_AddOns.GetAddOnMetadata("UltimateCastBars", "Title")
-- Libraries
UCB.LSM = LibStub("LibSharedMedia-3.0")
UCB.LDS = LibStub("LibDualSpec-1.0")
UCB.AG = LibStub("AceGUI-3.0")
UCB.AC = LibStub("AceConfig-3.0")
UCB.ACR = LibStub("AceConfigRegistry-3.0")
UCB.ACD = LibStub("AceConfigDialog-3.0")
UCB.ADBO = LibStub("AceDBOptions-3.0")
UCB.LDB = LibStub("LibDataBroker-1.1")


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

-- Sub APIs
UCB.CLASS_API.Evoker = UCB.CLASS_API.Evoker or {}
UCB.Options.ClassExtraBuilders = UCB.Options.ClassExtraBuilders or {}


UCB.CASTBAR_API.CreateCastbar = UCB.CASTBAR_API.UpdateCastbar -- for backward compatibility

-- Used to hide the default castbar
UCB.defaultCastbarFrame = CreateFrame("Frame")
UCB.defaultCastbarFrame:Hide()

UCB.castBar = {} -- The cast bars
UCB.castBarGroup = {} -- The cast bar groups (for anchoring)
UCB.defaultBar = {} -- The default blizz cast bars
UCB.previewActive = {} -- Preview active flags
UCB.eventFrame = {} -- Event frames per unit



UCB.optionsPanel, UCB.optionsCategoryID = UCB.ACD:AddToBlizOptions("UCB", "UCB")


UCB.units = {
    "player",
    "target",
    "focus"
}

UCB.tags.keys = {
    "[sName:X]",
    "[rTime:X]",
    "[rTimeInv:X]",
    "[dTime:X]",
    "[rPerTime:X]",
    "[rPerTimeInv:X]",
    "[dPerTime:X]",
    "[cIntr:X]",
    "[cIntrInv:X]"
}

UCB.tags.openDelim = "["
UCB.tags.closeDelim  = "]"
UCB.tags.colours = {
    dynamic = "red",
    semiDynamic = "yellow",
    static = "green",
    unk = "grey"
}
UCB.tags.typeNames = {
    dynamic = "Dynamic",
    semiDynamic = "Semi-Dynamic",
    static = "Static",
    unk = "Unknown"
}

UCB.tags.typeTags = {
    Dynamic = "dynamic",
    ["Semi-Dynamic"] = "semiDynamic",
    Static = "static",
    Unknown = "unk"
}

UCB.tags.var = {
    player = {
        sName = "",
        sTime = 0,
        eTime = 0,
        dTime = 0,
        Intr = false,
        empStages = {}
    },
    target = {
        sName = "",
        sTime = 0,
        eTime = 0,
        dTime = 0,
        Intr = false,
        empStages = {}
    },
    focus = {
        sName = "",
        sTime = 0,
        eTime = 0,
        dTime = 0,
        Intr = false,
        empStages = {}
    },
}

UCB.UIOptions = UCB.UIOptions or {}

UCB.UIOptions.anchors = {
    TOP="Top",
    BOTTOM="Bottom",
    LEFT="Left",
    RIGHT="Right",
    CENTER="Center",
    TOPLEFT="Top Left",
    TOPRIGHT="Top Right",
    BOTTOMLEFT="Bottom Left",
    BOTTOMRIGHT="Bottom Right"
}

UCB.UIOptions.justify = {
    LEFT="Left",
    CENTER="Center",
    RIGHT="Right",
}

UCB.UIOptions.strata = {
    BACKGROUND="Background",
    LOW="Low",
    MEDIUM="Medium",
    HIGH="High",
    DIALOG="Dialog",
    FULLSCREEN="Fullscreen",
    FULLSCREEN_DIALOG="Fullscreen Dialog",
    TOOLTIP="Tooltip"
}

UCB.UIOptions.stratSubComponents = {
    BACKGROUND="BACKGROUND",
    BORDER ="BORDER",
    ARTWORK="ARTWORK",
    OVERLAY="OVERLAY",
}



UCB.UIOptions.offsetMin_icon = -500
UCB.UIOptions.offsetMax_icon = 500
UCB.UIOptions.widthMax_icon = 200
UCB.UIOptions.widthMin_icon = 5
UCB.UIOptions.heightMax_icon = 200
UCB.UIOptions.heightMin_icon = 5


UCB.UIOptions.offsetMin_bar = -500
UCB.UIOptions.offsetMax_bar = 500
UCB.UIOptions.widthMax_bar = 1000
UCB.UIOptions.widthMin_bar = 20
UCB.UIOptions.heightMax_bar = 500
UCB.UIOptions.heightMin_bar = 10
UCB.UIOptions.heightOffsetMin_bar= -200
UCB.UIOptions.heightOffsetMax_bar= 200
UCB.UIOptions.widthOffsetMin_bar= -500
UCB.UIOptions.widthOffsetMax_bar= 500

UCB.UIOptions.textSizeMin = 6
UCB.UIOptions.textSizeMax = 40
UCB.UIOptions.textOffsetMin = -200
UCB.UIOptions.textOffsetMax = 200

UCB.UIOptions.alphaMin = 0.0
UCB.UIOptions.alphaMax = 1.0


UCB.UIOptions.borderThicknessMin = 0.5
UCB.UIOptions.borderThicknessMax = 100

UCB.UIOptions.borderOffsetMin = 0
UCB.UIOptions.borderOffsetMax = 50

UCB.UIOptions.channelTickWidthMin = 0.5
UCB.UIOptions.channelTickWidthMax = 30

UCB.UIOptions.queueWindowMin = 1
UCB.UIOptions.queueWindowMax = 1000

UCB.UIOptions.frameLevelMin = 10
UCB.UIOptions.frameLevelMax = 500

UCB.UIOptions.minPreviewDuration = 0.5
UCB.UIOptions.maxPreviewDuration = 60
UCB.UIOptions.minPreviewEmpowerStages = 1
UCB.UIOptions.maxPreviewEmpowerStages = 5



UCB.UIOptions.blizzOffsetMin = -1000
UCB.UIOptions.blizzOffsetMax = 1000
UCB.UIOptions.blizzScaleMin = 0.01
UCB.UIOptions.blizzScaleMax = 10.0


UCB.UIOptions.white = "FFFFFFFF"
UCB.UIOptions.black = "FF000000"
UCB.UIOptions.blue = "FF0000FF"
UCB.UIOptions.purple = "FFFF00FF"
UCB.UIOptions.turquoise = "FF00FFFF"
UCB.UIOptions.red = "FFFF0000"
UCB.UIOptions.green = "FF00FF00"
UCB.UIOptions.yellow = "FFFFFF00"
UCB.UIOptions.grey = "FF808080"



function UCB.UIOptions.ColorText(hex, text)
    return ("|c%s%s|r"):format(hex, text)
end


function UCB:PrintAddonMsg(msg)  print(self.ADDON_NAME .. ":|r " .. msg) end


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
    local root = profile[unit]
    --local root = UCB.db.profile[unit]
    if key == nil then return root end
    if not root then return nil end
    return GetPathValue(root, key)
end


-- Creates a live proxy table that always points at the current profile table.
-- Example: local g = UCB.CFG_API:Proxy(unit, {"general"})
function UCB.CFG_API:Proxy(unit, path)
  local function ensureRoot()
    local db = UCB.db
    if not db or not db.profile then return nil end

    local p = db.profile
    p[unit] = p[unit] or {}
    local t = p[unit]

    if type(path) == "table" then
      for i = 1, #path do
        local k = path[i]
        if type(t[k]) ~= "table" then t[k] = {} end
        t = t[k]
      end
    elseif type(path) == "string" then
      if type(t[path]) ~= "table" then t[path] = {} end
      t = t[path]
    end

    return t
  end

  local proxy = {}
  return setmetatable(proxy, {
    __index = function(_, k)
      local t = ensureRoot()
      return t and t[k] or nil
    end,
    __newindex = function(_, k, v)
      local t = ensureRoot()
      if t then t[k] = v end
    end,
    -- optional, helps if you ever iterate pairs(g)
    __pairs = function()
      local t = ensureRoot() or {}
      return next, t, nil
    end,
  })
end



local function createPicker()
    UCB.SimpleFramePickerObj = UCB.SimpleFramePicker:New()
end


local function SetUpClassInfo()
    local _, class = UnitClass("player")
    local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] or {r=1, g=1, b=1}
    UCB.classColour = {r = classColor.r, g = classColor.g, b = classColor.b, a = 1}
    UCB.className = class
end

local function SetUpSecInfo()
    UCB.specID = PlayerUtil.GetCurrentSpecID()
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

local function GatherInfo()
    SetUpClassInfo()
    SetUpSecInfo()

    -- delay spell scanning until the world is ready
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        f:UnregisterAllEvents()
        f:SetScript("OnEvent", nil)

        -- small delay helps tooltip/spellbook settle on first load
        C_Timer.After(0.1, function()
            SetUpSpellTypes()
        end)
    end)
end



-- Teardown for spellcast events
function  UCB:DestroyPlayerSpellcastEventFrame(mainUnit)
    if not UCB.eventFrame or not UCB.eventFrame[mainUnit] then return end

    local f = UCB.eventFrame[mainUnit]
    f:UnregisterAllEvents()
    f:SetScript("OnEvent", nil)
    f:Hide()
    UCB.eventFrame[mainUnit] = nil
end

-- Your spellcast event frame (unchanged logic, just guarded for unit == "player")
function UCB:EUCBurePlayerSpellcastEventFrame(mainUnit)
  if UCB.eventFrame[mainUnit] then return end

  local f = CreateFrame("Frame")
  f:RegisterEvent("UNIT_SPELLCAST_START")
  f:RegisterEvent("UNIT_SPELLCAST_STOP")
  f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
  f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
  f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
  f:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START")
  f:RegisterEvent("UNIT_SPELLCAST_EMPOWER_UPDATE")
  f:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")

  f:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
    if unit ~= mainUnit then return end

    if event == "UNIT_SPELLCAST_START" then UCB.CASTBAR_API:OnUnitSpellcastStart(unit, castGUID, spellID)
    elseif event == "UNIT_SPELLCAST_STOP" then UCB.CASTBAR_API:OnUnitSpellcastStop(unit, castGUID, spellID)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then UCB.CASTBAR_API:OnUnitSpellcastChannelStart(unit, castGUID, spellID)
    elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then UCB.CASTBAR_API:OnUnitSpellcastChannelUpdate(unit, castGUID, spellID)
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then UCB.CASTBAR_API:OnUnitSpellcastChannelStop(unit, castGUID, spellID)
    elseif event == "UNIT_SPELLCAST_EMPOWER_START" then UCB.CASTBAR_API:OnUnitSpellcastEmpowerStart(unit, castGUID, spellID)
    elseif event == "UNIT_SPELLCAST_EMPOWER_UPDATE" then UCB.CASTBAR_API:OnUnitSpellcastEmpowerUpdate(unit, castGUID, spellID)
    elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then UCB.CASTBAR_API:OnUnitSpellcastEmpowerStop(unit, castGUID, spellID)
    end
  end)

  UCB.eventFrame[mainUnit] = f
end




local function createBar(unit)
    local frameInit = CreateFrame("Frame")
    frameInit:RegisterEvent("PLAYER_LOGIN")
    frameInit:RegisterEvent("PLAYER_ENTERING_WORLD")
    frameInit:SetScript("OnEvent", function()
    --UCB:RefreshBlizzardCastbar()
    UCB:EUCBurePlayerSpellcastEventFrame(unit)
    end)
    UCB.CASTBAR_API:UpdateCastbar(unit)

    -- Hide or Show the default bar
    UCB.DefBlizzCast:ApplyDefaultBlizzCastbar(unit, false)
end

-- Add slash commands
local function SetupSlashCommands()
    SLASH_UCB1 = "/ucb"
    --SLASH_UCB2 = "/pcb"
    --SLASH_UCB3 = "/tcb"
    --SLASH_UCB4 = "/fcb"
    SLASH_UCB5 = "/ultimatecastbars"
    SLASH_UCB6 = "/uc"
    SlashCmdList["UCB"] = function() UCB:OpenGUI() end
    UCB:PrintAddonMsg("'|cFF8080FF/ucb|r' for in-game configuration.")

    -- RL command
    SLASH_UCBRELOAD1 = "/rl"
    SlashCmdList["UCBRELOAD"] = function() C_UI.Reload() end
end


function UCB:EnsureUnit(unit)
  -- One-time event frame setup
  self:EUCBurePlayerSpellcastEventFrame(unit)

  -- One-time default blizz castbar handling
  self.DefBlizzCast:ApplyDefaultBlizzCastbar(unit, false)

  -- One-time castbar object/frame creation should happen inside UpdateCastbar
  -- OR you can have an explicit CreateCastbar(unit) if your API supports it.
end

function UCB:UpdateAllCastBars()
  self:EnsureUnit("player")
  self.CASTBAR_API:UpdateCastbar("player")
  self:SetUpConfig()
  UCB:RefreshGUI()
  UCB.ACR:NotifyChange("UCB")
end


function UCB:Init()
  SetupSlashCommands()
  GatherInfo()
  createPicker()

  -- do the once-only setup and initial paint
  self:UpdateAllCastBars()
end