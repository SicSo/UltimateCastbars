local ADDON_NAME, UCB = ...

--------------------------------------------------------------- Libraries ------------------------------------------------------------
UCB.LSM = LibStub("LibSharedMedia-3.0")
UCB.LDS = LibStub("LibDualSpec-1.0")
UCB.AG = LibStub("AceGUI-3.0")
UCB.AC = LibStub("AceConfig-3.0")
UCB.ACR = LibStub("AceConfigRegistry-3.0")
UCB.ACD = LibStub("AceConfigDialog-3.0")
UCB.ADBO = LibStub("AceDBOptions-3.0")
UCB.LDB = LibStub("LibDataBroker-1.1")
UCB.LA = LibStub("LibAnimate")
UCB.ADDON_NAME = C_AddOns.GetAddOnMetadata("UltimateCastbars", "Title")

--------------------------------------------------------------- UI/GUI ------------------------------------------------------------
UCB.GUI = UCB.GUI or {}

UCB.GUI.appName = "UCB_ROOT"

UCB.UI = UCB.UI or {}

UCB.UI.icons = {
    discord = "Interface\\AddOns\\UltimateCastbars\\gfx\\Icons\\discord.png",
    github = "Interface\\AddOns\\UltimateCastbars\\gfx\\Icons\\github.png",
    donate = "Interface\\AddOns\\UltimateCastbars\\gfx\\Icons\\Ko-fi_HEART.png",
    logo = "Interface\\AddOns\\UltimateCastbars\\gfx\\icon.tga",
}


UCB.UI.links = {
    discord = "https://discord.gg/wX5hWW3N3Q",
    github = "https://github.com/SicSo/UltimateCastbars",
    donate = "https://ko-fi.com/sicso",
    patreon = "https://www.patreon.com/SicSo",
    paypal = "https://paypal.me/SicSo",
    kofi = "https://ko-fi.com/sicso",
}

UCB.UI.text = {
    madeBy = "SicSo",
    madeByM = "SicSo, Ckraig ",
    version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version"),
    name = "Ultimate Castbars",
}

--------------------------------------------------------------- Copy ------------------------------------------------------------
UCB.Copy = UCB.Copy or {}

UCB.Copy.categories = {
    general = "General",
    text = "Text",
    styleCastType = "Style",
    visibility = "Visibility",
    uninterruptible = "Uninterruptible",
    otherFeatures = "Other Features",
    CLASSES = "Class-specific settings"
}

UCB.Copy.categoriesOrder = {
    "general",
    "text",
    "styleCastType",
    "visibility",
    "uninterruptible",
    "otherFeatures",
    "CLASSES"
}

--------------------------------------------------------------- General ------------------------------------------------------------
UCB.specs =  {
  WARRIOR = {
    classId = 1,
    specs = {
      [71] = "Arms",
      [72] = "Fury",
      [73] = "Protection",
      [1446] = "Initial (below level 10)",
    },
    kick = {6552}
  },

  PALADIN = {
    classId = 2,
    specs = {
      [65] = "Holy",
      [66] = "Protection",
      [70] = "Retribution",
      [1451] = "Initial (below level 10)",
    },
    kick = {31935, 96231},
  },

  HUNTER = {
    classId = 3,
    specs = {
      [253] = "Beast Mastery",
      [254] = "Marksmanship",
      [255] = "Survival",
      [1448] = "Initial (below level 10)",
    },
    kick = {187707, 147362},
  },

  ROGUE = {
    classId = 4,
    specs = {
      [259] = "Assassination",
      [260] = "Outlaw",
      [261] = "Subtlety",
      [1453] = "Initial (below level 10)",
    },
    kick = {1766},
  },

  PRIEST = {
    classId = 5,
    specs = {
      [256] = "Discipline",
      [257] = "Holy",
      [258] = "Shadow",
      [1452] = "Initial (below level 10)",
    },
    kick = {15487},
  },

  DEATHKNIGHT = {
    classId = 6,
    specs = {
      [250] = "Blood",
      [251] = "Frost",
      [252] = "Unholy",
      [1455] = "Initial (below level 10)",
    },
    kick = {47528},
  },

  SHAMAN = {
    classId = 7,
    specs = {
      [262] = "Elemental",
      [263] = "Enhancement",
      [264] = "Restoration",
      [1444] = "Initial (below level 10)",
    },
    kick = {57994},
  },

  MAGE = {
    classId = 8,
    specs = {
      [62] = "Arcane",
      [63] = "Fire",
      [64] = "Frost",
      [1449] = "Initial (below level 10)",
    },
    kick = {2139},
  },

  WARLOCK = {
    classId = 9,
    specs = {
      [265] = "Affliction",
      [266] = "Demonology",
      [267] = "Destruction",
      [1454] = "Initial (below level 10)",
    },
    kick = {19647, 89766, 119910, 1276467, 132409},
  },

  MONK = {
    classId = 10,
    specs = {
      [268] = "Brewmaster",
      [269] = "Windwalker",
      [270] = "Mistweaver",
      [1450] = "Initial (below level 10)",
    },
    kick = {116705},
  },

  DRUID = {
    classId = 11,
    specs = {
      [102] = "Balance",
      [103] = "Feral",
      [104] = "Guardian",
      [105] = "Restoration",
      [1447] = "Initial (below level 10)",
    },
    kick = {38675, 78675, 106839},
  },

  DEMONHUNTER = {
    classId = 12,
    specs = {
      [577] = "Havoc",
      [581] = "Vengeance",
      [1480] = "Devourer",
      [1456] = "Initial (below level 10)",
    },
    kick  = {183752},
  },

  EVOKER = {
    classId = 13,
    specs = {
      [1467] = "Devastation",
      [1468] = "Preservation",
      [1473] = "Augmentation",
      [1465] = "Initial (below level 10)",
    },
    kick = {351338},
  },
}

------------------------------------------------------------ Tags ------------------------------------------------------------
UCB.tags = UCB.tags or {}

UCB.tags.keys = {
    "[sName:X]",
    "[rTime:X]",
    "[rTimeInv:X]",
    "[dTime:X]",
    "[rPerTime:X]",
    "[rPerTimeInv:X]",
    "[dPerTime:X]",
    "[nIntr:X]",
    "[nIntrInv:X]"
}

UCB.tags.openDelim = "["
UCB.tags.closeDelim  = "]"
UCB.tags.colours = {
    dynamic = "red",
    semiDynamic = "yellow",
    static = "green",
    unk = "grey",
    cancelled = "purple",
    interrupted = "orange"
}

UCB.tags.typeNames = {
    dynamic = "Dynamic",
    semiDynamic = "Semi-Dynamic",
    static = "Static",
    unk = "Unknown",
    cancelled = "Cancelled",
    interrupted = "Interrupted"
}

UCB.tags.typeTags = {
    Dynamic = "dynamic",
    ["Semi-Dynamic"] = "semiDynamic",
    Static = "static",
    Unknown = "unk",
    Cancelled = "cancelled",
    Interrupted = "interrupted",
}

------------------------------------------------------------UI Options------------------------------------------------------------
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

UCB.UIOptions.fontOutlines = {
    NONE = "None",
    OUTLINE= "Outline",
    THICKOUTLINE= "Thick Outline",
    MONO_NONE = "Monochrome",
    MONO_OUTLINE = "Monochrome Outline",
    MONO_THICKOUTLINE = "Monochrome Thick Outline",
    SHADOW = "Shadow",
    SHADOW_OUTLINE = "Shadow Outline",
    SHADOW_THICKOUTLINE = "Shadow Thick Outline",
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
UCB.UIOptions.shadowOffsetMin = 0
UCB.UIOptions.shadowOffsetMax = 10

UCB.UIOptions.alphaMin = 0.0
UCB.UIOptions.alphaMax = 1.0

UCB.UIOptions.borderThicknessMin = 0.5
UCB.UIOptions.borderThicknessMax = 100

UCB.UIOptions.borderOffsetMin = 0
UCB.UIOptions.borderOffsetMax = 50

UCB.UIOptions.channelTickWidthMin = 0.5
UCB.UIOptions.channelTickWidthMax = 30
UCB.UIOptions.channelTickNumMin = 1
UCB.UIOptions.channelTickNumMax = 20

UCB.UIOptions.empowerTickPositionMin = 0.001
UCB.UIOptions.empowerTickPositionMax = 0.999

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

UCB.UIOptions.frameDelayMin = 0
UCB.UIOptions.frameDelayMax = 10
UCB.UIOptions.frameTriesMin = 1
UCB.UIOptions.frameTriesMax = 1000
UCB.UIOptions.frameIntervalMin = 0.01
UCB.UIOptions.frameIntervalMax = 1.0


UCB.UIOptions.white = "FFFFFFFF"
UCB.UIOptions.black = "FF000000"
UCB.UIOptions.blue = "FF0000FF"
UCB.UIOptions.purple = "FFFF00FF"
UCB.UIOptions.turquoise = "FF00FFFF"
UCB.UIOptions.red = "FFFF0000"
UCB.UIOptions.green = "FF00FF00"
UCB.UIOptions.yellow = "FFFFFF00"
UCB.UIOptions.grey = "FF808080"
UCB.UIOptions.purple = "FFFF00FF"
UCB.UIOptions.orange = "FFFFA500"
UCB.UIOptions.gold = "FFFFD700"

UCB.UIOptions.WHITE     = { r = 1.000000, g = 1.000000, b = 1.000000 }
UCB.UIOptions.BLACK     = { r = 0.000000, g = 0.000000, b = 0.000000 }
UCB.UIOptions.BLUE      = { r = 0.000000, g = 0.000000, b = 1.000000 }
UCB.UIOptions.PURPLE    = { r = 1.000000, g = 0.000000, b = 1.000000 }
UCB.UIOptions.TURQUOISE = { r = 0.000000, g = 1.000000, b = 1.000000 }
UCB.UIOptions.RED       = { r = 1.000000, g = 0.000000, b = 0.000000 }
UCB.UIOptions.GREEN     = { r = 0.000000, g = 1.000000, b = 0.000000 }
UCB.UIOptions.YELLOW    = { r = 1.000000, g = 1.000000, b = 0.000000 }
UCB.UIOptions.GREY      = { r = 0.501961, g = 0.501961, b = 0.501961 }
UCB.UIOptions.ORANGE    = { r = 1.000000, g = 0.647059, b = 0.000000 }
UCB.UIOptions.GOLD      = { r = 1.000000, g = 0.843137, b = 0.000000 }


function UCB.UIOptions:ClassFileToColors(classFile, alpha)
    alpha = alpha or 1

    local c = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]) or nil
    local r, g, b

    if c then
        r, g, b = c.r, c.g, c.b
    else
        r, g, b = 1, 1, 1
    end

    local rgbaList = { r=r, g=g, b=b, a=alpha }
    local colorObj = CreateColor(r, g, b, alpha)

    return rgbaList, colorObj
end

local function BuildClassColorLookup(alpha)
    alpha = alpha or 1
    local t = {}

    if not RAID_CLASS_COLORS then
        return t
    end

    for classFile in pairs(RAID_CLASS_COLORS) do
        local rgbaList, colorObj = UCB.UIOptions:ClassFileToColors(classFile, alpha)
        t[classFile] = { RGBA = rgbaList, COL = colorObj , HEX = string.format("%02X%02X%02X%02X", math.floor(rgbaList.a * 255 + 0.5), math.floor(rgbaList.r * 255 + 0.5), math.floor(rgbaList.g * 255 + 0.5), math.floor(rgbaList.b * 255 + 0.5)) }
    end

    return t
end

UCB.UIOptions.classColoursList = BuildClassColorLookup(1)


UCB.UITextures = UCB.UITextures or {}
UCB.UITextures.DownChevron = "Interface\\AddOns\\UltimateCastbars\\gfx\\chevron-down-rounded.tga"
UCB.UITextures.UpChevron = "Interface\\AddOns\\UltimateCastbars\\gfx\\chevron-up-rounded.tga"
UCB.UITextures.RightChevron = "Interface\\AddOns\\UltimateCastbars\\gfx\\chevron-right-rounded.tga"
UCB.UITextures.ChangelogIcon = "Interface\\AddOns\\UltimateCastbars\\gfx\\changelog.png"



------------------------------------------------------------ Profiles ------------------------------------------------------------
UCB.profiles = UCB.profiles or {}

UCB.profiles.textureFallbacks = {
  statusbar  = "Blizzard",
  background = "Blizzard Dialog Background Gold",
}

UCB.profiles.fontFallbacks = { font = "Friz Quadrata TT" }

UCB.profiles.texture_map = {
  ["styleCastType.general.textureName"]             = { path = "styleCastType.general.texture",                 type = "statusbar" },
  ["styleCastType.general.textureNameBack"]                 = { path = "styleCastType.general.textureBack",                     type = "background" },
  ["styleCastType.general.textureNameBorder"]               = { path = "styleCastType.general.textureBorder",                   type = "statusbar" },
  ["styleCastType.general.textureNameBorderIcon"]           = { path = "styleCastType.general.textureBorderIcon",               type = "statusbar" },

  ["styleCastType.normal.textureName"]                     = { path = "styleCastType.normal.texture",                 type = "statusbar" },
  ["styleCastType.normal.textureNameBack"]                 = { path = "styleCastType.normal.textureBack",                     type = "background" },
  ["styleCastType.normal.textureNameBorder"]               = { path = "styleCastType.normal.textureBorder",                   type = "statusbar" },
  ["styleCastType.normal.textureNameBorderIcon"]           = { path = "styleCastType.normal.textureBorderIcon",               type = "statusbar" },

  ["styleCastType.channel.textureName"]                     = { path = "styleCastType.channel.texture",                 type = "statusbar" },
  ["styleCastType.channel.textureNameBack"]                 = { path = "styleCastType.channel.textureBack",                     type = "background" },
  ["styleCastType.channel.textureNameBorder"]               = { path = "styleCastType.channel.textureBorder",                   type = "statusbar" },
  ["styleCastType.channel.textureNameBorderIcon"]           = { path = "styleCastType.channel.textureBorderIcon",               type = "statusbar" },

  ["styleCastType.empowered.textureName"]                     = { path = "styleCastType.empowered.texture",                 type = "statusbar" },
  ["styleCastType.empowered.textureNameBack"]                 = { path = "styleCastType.empowered.textureBack",                     type = "background" },
  ["styleCastType.empowered.textureNameBorder"]               = { path = "styleCastType.empowered.textureBorder",                   type = "statusbar" },
  ["styleCastType.empowered.textureNameBorderIcon"]           = { path = "styleCastType.empowered.textureBorderIcon",               type = "statusbar" },

  ["styleCastType.default.textureName"]                     = { path = "styleCastType.default.texture",                 type = "statusbar" },
  ["styleCastType.default.textureNameBack"]                 = { path = "styleCastType.default.textureBack",                     type = "background" },
  ["styleCastType.default.textureNameBorder"]               = { path = "styleCastType.default.textureBorder",                   type = "statusbar" },
  ["styleCastType.default.textureNameBorderIcon"]           = { path = "styleCastType.default.textureBorderIcon",               type = "statusbar" },

  ["uninterruptible.fillTextureName"]       = { path = "uninterruptible.fillTexture",           type = "statusbar" },
  ["uninterruptible.backgroundTextureName"] = { path = "uninterruptible.backgroundTexture",     type = "background" },
  ["uninterruptible.textureNameBorder"]     = { path = "uninterruptible.textureBorder",         type = "statusbar" },
  ["uninterruptible.textureNameBorderIcon"] = { path = "uninterruptible.textureBorderIcon",     type = "statusbar" },
  ["uninterruptible.kickTickTextureName"]   = { path = "uninterruptible.kickTickTexture",       type = "statusbar" },
  ["uninterruptible.untilKickTickTextureName"]     = { path = "uninterruptible.untilKickTickTexture",     type = "statusbar" },
  ["uninterruptible.untilKickTickBackTextureName"] = { path = "uninterruptible.untilKickTickBackTexture", type = "statusbar" },

  ["otherFeatures.tickTextureName"]         = { path = "otherFeatures.tickTexture",             type = "statusbar" },
  ["otherFeatures.queueTextureName"]        = { path = "otherFeatures.queueTexture",            type = "statusbar" },
  ["otherFeatures.latency.textureName"]        = { path = "otherFeatures.latency.texture",            type = "statusbar" },

  ["CLASSES.WARRIOR.tickTextureName"]       = { path = "CLASSES.WARRIOR.tickTexture",           type = "statusbar" },
  ["CLASSES.PALADIN.tickTextureName"]       = { path = "CLASSES.PALADIN.tickTexture",           type = "statusbar" },
  ["CLASSES.HUNTER.tickTextureName"]        = { path = "CLASSES.HUNTER.tickTexture",            type = "statusbar" },
  ["CLASSES.ROGUE.tickTextureName"]         = { path = "CLASSES.ROGUE.tickTexture",             type = "statusbar" },
  ["CLASSES.PRIEST.tickTextureName"]        = { path = "CLASSES.PRIEST.tickTexture",            type = "statusbar" },
  ["CLASSES.DEATHKNIGHT.tickTextureName"]   = { path = "CLASSES.DEATHKNIGHT.tickTexture",       type = "statusbar" },
  ["CLASSES.SHAMAN.tickTextureName"]        = { path = "CLASSES.SHAMAN.tickTexture",            type = "statusbar" },
  ["CLASSES.MAGE.tickTextureName"]          = { path = "CLASSES.MAGE.tickTexture",              type = "statusbar" },
  ["CLASSES.WARLOCK.tickTextureName"]       = { path = "CLASSES.WARLOCK.tickTexture",           type = "statusbar" },
  ["CLASSES.MONK.tickTextureName"]          = { path = "CLASSES.MONK.tickTexture",              type = "statusbar" },
  ["CLASSES.DRUID.tickTextureName"]         = { path = "CLASSES.DRUID.tickTexture",             type = "statusbar" },
  ["CLASSES.DEMONHUNTER.tickTextureName"]   = { path = "CLASSES.DEMONHUNTER.tickTexture",       type = "statusbar" },
  ["CLASSES.EVOKER.tickTextureName"]        = { path = "CLASSES.EVOKER.tickTexture",            type = "statusbar" },

  -- Array/list pairs (names list is the key)
  ["otherFeatures.cancelledEffect.frameTextureName"] = { path = "otherFeatures.cancelledEffect.frameTexture", type = "statusbar" },
  ["otherFeatures.interruptedEffect.frameTextureName"] = { path = "otherFeatures.interruptedEffect.frameTexture", type = "statusbar" },
  ["CLASSES.EVOKER.empowerTickTexturesNames"]    = { path = "CLASSES.EVOKER.empowerTickTextures",    type = "statusbar" },
  ["CLASSES.EVOKER.empowerSegmentTexturesNames"] = { path = "CLASSES.EVOKER.empowerSegmentTextures", type = "background" },
}

UCB.profiles.font_map = {
  ["text.generalValues.fontName"] = { path = "text.generalValues.font", type = "font" },
  ["text.defaultValues.fontName"] = { path = "text.defaultValues.font", type = "font" },

  -- wildcard groups: these point to a table of tags; each tag table contains font/fontName
  ["text.textList.*"]      = { type = "font", fontNameKey = "fontName", fontPathKey = "font" },
}