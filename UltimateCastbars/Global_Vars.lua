local ADDON_NAME, UCB = ...



-- Used to hide the default castbar
UCB.defaultCastbarFrame = CreateFrame("Frame")
UCB.defaultCastbarFrame:Hide()

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
