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
UCB.ADDON_NAME = C_AddOns.GetAddOnMetadata("UltimateCastbars", "Title")

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
  },

  PALADIN = {
    classId = 2,
    specs = {
      [65] = "Holy",
      [66] = "Protection",
      [70] = "Retribution",
      [1451] = "Initial (below level 10)",
    },
  },

  HUNTER = {
    classId = 3,
    specs = {
      [253] = "Beast Mastery",
      [254] = "Marksmanship",
      [255] = "Survival",
      [1448] = "Initial (below level 10)",
    },
  },

  ROGUE = {
    classId = 4,
    specs = {
      [259] = "Assassination",
      [260] = "Outlaw",
      [261] = "Subtlety",
      [1453] = "Initial (below level 10)",
    },
  },

  PRIEST = {
    classId = 5,
    specs = {
      [256] = "Discipline",
      [257] = "Holy",
      [258] = "Shadow",
      [1452] = "Initial (below level 10)",
    },
  },

  DEATHKNIGHT = {
    classId = 6,
    specs = {
      [250] = "Blood",
      [251] = "Frost",
      [252] = "Unholy",
      [1455] = "Initial (below level 10)",
    },
  },

  SHAMAN = {
    classId = 7,
    specs = {
      [262] = "Elemental",
      [263] = "Enhancement",
      [264] = "Restoration",
      [1444] = "Initial (below level 10)",
    },
  },

  MAGE = {
    classId = 8,
    specs = {
      [62] = "Arcane",
      [63] = "Fire",
      [64] = "Frost",
      [1449] = "Initial (below level 10)",
    },
  },

  WARLOCK = {
    classId = 9,
    specs = {
      [265] = "Affliction",
      [266] = "Demonology",
      [267] = "Destruction",
      [1454] = "Initial (below level 10)",
    },
  },

  MONK = {
    classId = 10,
    specs = {
      [268] = "Brewmaster",
      [269] = "Windwalker",
      [270] = "Mistweaver",
      [1450] = "Initial (below level 10)",
    },
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
  },

  DEMONHUNTER = {
    classId = 12,
    specs = {
      [577] = "Havoc",
      [581] = "Vengeance",
      [1480] = "Devourer",
      [1456] = "Initial (below level 10)",
    },
  },

  EVOKER = {
    classId = 13,
    specs = {
      [1467] = "Devastation",
      [1468] = "Preservation",
      [1473] = "Augmentation",
      [1465] = "Initial (below level 10)",
    },
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