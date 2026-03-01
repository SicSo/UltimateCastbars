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

UCB.castTypesStyle = {
    "general",
    "normal",
    "channel",
    "empowered"
}

UCB.events = {
  UNIT_SPELLCAST_START          = "OnUnitSpellcastStart",
  UNIT_SPELLCAST_STOP           = "OnUnitSpellcastStop",
  UNIT_SPELLCAST_CHANNEL_START  = "OnUnitSpellcastChannelStart",
  UNIT_SPELLCAST_CHANNEL_UPDATE = "OnUnitSpellcastChannelUpdate",
  UNIT_SPELLCAST_EMPOWER_START  = "OnUnitSpellcastEmpowerStart",
  UNIT_SPELLCAST_EMPOWER_UPDATE = "OnUnitSpellcastEmpowerUpdate",
}

UCB.swapEvents = {
    PLAYER_TARGET_CHANGED = {"OnUnitChange", "target"},
    PLAYER_FOCUS_CHANGED = {"OnUnitChange", "focus"},
}

UCB.interruptEvents = {
    UNIT_SPELLCAST_INTERRUPTED = "OnCastInterrupt",
    UNIT_SPELLCAST_CHANNEL_STOP = "OnChannelInterrupt",
    UNIT_SPELLCAST_EMPOWER_STOP = "OnEmpowerInterrupt",
}

UCB.latencyEvents = {
    CURRENT_SPELL_CAST_CHANGED = "OnSpellCastChanged",
    UNIT_SPELLCAST_SENT = "OnSpellCastSent",
    UNIT_SPELLCAST_SUCCEEDED = "OnSpellCastSuccess",
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
        empStages = {},
        kName = "",
        kColour = {},
        lat = 0,
    },
    target = {
        sName = "",
        sTime = 0,
        eTime = 0,
        dTime = 0,
        nIntr = false,
        empStages = {},
        kName = "",
        kColour = {},
        lat = 0,
    },
    focus = {
        sName = "",
        sTime = 0,
        eTime = 0,
        dTime = 0,
        nIntr = false,
        empStages = {},
        kName = "",
        kColour = {},
        lat = 0,
    },
}

UCB.tags.tagGroups = {
    player = {
        static = {},
        semiDynamic = {},
        dynamic = {},
        unk = {},
        cancelled = {},
        interrupted = {}
    },
    target = {
        static = {},
        semiDynamic = {},
        dynamic = {},
        unk = {},
        cancelled = {},
        interrupted = {}
    },
    focus = {
        static = {},
        semiDynamic = {},
        dynamic = {},
        unk = {},
        cancelled = {},
        interrupted = {}
    }
}
