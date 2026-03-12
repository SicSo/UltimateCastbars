local _, UCB = ...

UCB.Default_DB = UCB.Default_DB or {}

function UCB.Default_DB:createStyle()
    local style = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        textureName = "Blizzard",
        textureBack = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
        textureNameBack = "Blizzard Dialog Background Gold",
        textureBorder = "Interface\\TargetingFrame\\UI-StatusBar",
        textureNameBorder = "Blizzard",
        textureBorderIcon = "Interface\\TargetingFrame\\UI-StatusBar",
        textureNameBorderIcon = "Blizzard",

        colourMode = "class", -- "class", "ombre", "custom"
        gradientEnable = false,
        customColour = {r=1, g=1, b=1, a=1}, -- default white
        customColour2 = {r=1, g=1, b=1, a=1}, -- default white for gradient end

        showBackground = true,
        bgColour = {r=0, g=0, b=0, a=1},
        bgUseCustomAlpha = false,
        bgAlpha = 1,
        bgColourMode = "custom", -- "class", "custom"

        effects = {
            spark = {
                enable = true,
                texture = "Interface\\CastingBar\\UI-CastingBar-Spark",
                textureName = "Blizzard Spark",
                blendMode = "ADD",
                colour = {r=1, g=1, b=1, a=0.8},
                width = 20,
                heightMult = 2.2
            }
        },

        showBorder = false,
        borderFillCorners = true,
        borderThickness = 1,
        borderColour = {r=1, g=1, b=1, a=1},
        borderOffsetTop = 0,
        borderOffsetBottom = 0,
        borderOffsetLeft = 0,
        borderOffsetRight = 0,

        
        showBorderIcon = false,
        syncBorderIcon = false,
        borderFillCornersIcon = true,
        borderThicknessIcon = 1,
        borderColourIcon = {r=1, g=1, b=1, a=1},
        borderOffsetTopIcon = 0,
        borderOffsetBottomIcon = 0,
        borderOffsetLeftIcon = 0,
        borderOffsetRightIcon = 0,
    }
    return style
end

local function createClassSettings()
    local generalClassSettings = {
        useMainSettingsChannel = true,
        channeledSpels = {},
        showChannelTicks = true,
        useTickTexture = false,
        tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        tickTextureName = "Blizzard",
        channelTickWidth = 2,
        channelTickColour = {r=1, g=1, b=1, a=0.7},

        blacklistWhitelist = {
            enableAbilityFilter = false,
            blackList = true,
            useManualTable = true,
            usePlayerSpellList = true,
            blackListSpells = {},
            whiteListSpells = {},
        },

        spellStyling = {
            useStyleSpell = false,
            styleSpells = {}
        }

    }
    return generalClassSettings
end

local function merge(dst, src)
  if dst == nil then dst = {} end
  if src == nil then return dst end

  for k, v in pairs(src) do
    dst[k] = v
  end

  return dst
end

UCB.Default_DB.player = {
     enabled = true,

    general = {
        offsetX = 0,
        offsetY = 0,
        anchorFrom = "CENTER", --"TOP" "BOTTOM" "LEFT" "RIGHT" "CENTER" "TOPLEFT" "TOPRIGHT" "BOTTOMLEFT" "BOTTOMRIGHT"
        anchorTo = "CENTER",
        anchorFromDefault = "CENTER",
        anchorToDefault = "CENTER",
        anchorName = "", -- Name of frame to anchor to
        useDefaultAnchor = true,
        frameLastClicked = "",

        anchoredFrameList = {},
        anchorDelay = 0.1, -- delay in seconds for resolving anchor frames when changing settings or on login
        anchorFrameTries = 50,
        anchorFrameInterval = 0.1,

        syncDelay = 0.1, -- delay in seconds for syncing position across bars when moving one
        syncFrameTries = 50,
        syncFrameInterval = 0.1,

        widthInput = "",
        heightInput = "",
        frameSizeList = {},
        manualWidth = true,
        manualHeight = true,
        widthOffset = 0,
        heightOffset = 0,
        barHeight = 20,
        barWidth = 220,
        widthMinValue = 50,
        heightMinValue = 15,

        includeBorderInWidth = true,
        includeBorderInHeight = true,

        _widthFrameError = false,
        _heightFrameError = false,

        actualBarWidth = 220,
        fullBarWidth = 240,

        showCastIcon = true,
        syncIconBar = true,
        iconWidth = 20,
        iconHeight = 20,
        iconOffsetX = 0,
        iconOffsetY = 0,
        iconAnchor = "LEFT",

        _defaultWidthMode = "Manual",
        _defaultAnchor = "UIParent",
        _anchorCustomError = false,
        _iconInternalOffsetMultiplier = -1,
        _iconAnchor = "LEFT",
    },

    text = {
        generalValues = {
            useGeneralSize = false,
            useGeneralFont = false,
            useGeneralColour = false,
            useGlobalFont = false,
            useGeneralOutline = false,
            textSize = 12,
            fontName = "Friz Quadrata TT",
            font = "Fonts\\FRIZQT__.TTF",
            outline = "NONE",
            shadowColour = {r=0, g=0, b=0, a=1},
            shadowOffset = 1,

            colour = {r=1, g=1, b=1, a=1},
        },
        defaultValues = {
            name = "NewTag",

            show = true,

            tagText = "",

            anchorFrom = "CENTER",
            anchorTo = "CENTER",
            justify = "CENTER",
            textOffsetX = 0,
            textOffsetY = 0,
            frameStrata = "OVERLAY",

            font = "Fonts\\FRIZQT__.TTF",
            fontName = "Friz Quadrata TT",
            outline = "NONE",
            shadowColour = {r=0, g=0, b=0, a=1},
            shadowOffset = 1,
            textSize = 12,
            colour = {r=1, g=1, b=1, a=1},

            showType = {
                normal = true,
                channel = true,
                empowered = true,
            },

             showOnEffect = {
                interrupted = false,
                cancelled = false,
            },

            mainType = "cast",

            extraOptions = {
                useClassColour = true,
            }
        },
        textList = {
            tag1 = {
                name = "Spell name",
                show = true,
                tagText = "[sName]",

                font = "Fonts\\FRIZQT__.TTF",
                fontName = "Friz Quadrata TT",
                outline = "NONE",
                shadowColour = {r=0, g=0, b=0, a=1},
                shadowOffset = 1,
                textSize = 12,
                textOffsetX = 4,
                textOffsetY = 0,
                colour = {r=1, g=1, b=1, a=1},

                frameStrata = "OVERLAY",
                frameLevel = 10,
                anchorFrom = "LEFT",
                anchorTo = "LEFT",
                justify = "LEFT",

                showType = {
                    normal = true,
                    channel = true,
                    empowered = true,
                },

                showOnEffect = {
                    interrupted = true,
                    cancelled = true,
                },

                mainType = "cast",

                extraOptions = {
                    useClassColour = true,
                }
            },
            tag2 = {
                name = "Timer (decrease)",
                show = true,
                tagText = "[rTime]/[dTime]",

                anchorFrom = "RIGHT",
                anchorTo = "RIGHT",
                justify = "RIGHT",
                textOffsetX = -4,
                textOffsetY = 0,
                frameStrata = "OVERLAY",

                font = "Fonts\\FRIZQT__.TTF",
                fontName = "Friz Quadrata TT",
                outline = "NONE",
                shadowColour = {r=0, g=0, b=0, a=1},
                shadowOffset = 1,
                textSize = 12,
                colour = {r=1, g=1, b=1, a=1},

                showType = {
                    normal = true,
                    channel = false,
                    empowered = true,
                },

                showOnEffect = {
                    interrupted = false,
                    cancelled = false,
                },

                mainType = "cast",

                extraOptions = {
                    useClassColour = true,
                }
            },
            tag3 = {
                name = "Timer (increase)",
                show = true,
                tagText = "[rTimeInv]/[dTime]",

                anchorFrom = "RIGHT",
                anchorTo = "RIGHT",
                justify = "RIGHT",
                textOffsetX = -4,
                textOffsetY = 0,
                frameStrata = "OVERLAY",

                font = "Fonts\\FRIZQT__.TTF",
                fontName = "Friz Quadrata TT",
                outline = "NONE",
                shadowColour = {r=0, g=0, b=0, a=1},
                shadowOffset = 1,
                textSize = 12,
                colour = {r=1, g=1, b=1, a=1},

                showType = {
                    normal = false,
                    channel = true,
                    empowered = false,
                },
                
                showOnEffect = {
                    interrupted = false,
                    cancelled = false,
                },

                mainType = "cast",

                extraOptions = {
                    useClassColour = true,
                }
            },
            tag4 = {
                name = "Cancelled",
                show = true,
                tagText = "CANCELLED",

                anchorFrom = "RIGHT",
                anchorTo = "RIGHT",
                justify = "RIGHT",
                textOffsetX = -4,
                textOffsetY = 0,
                frameStrata = "OVERLAY",

                font = "Fonts\\FRIZQT__.TTF",
                fontName = "Friz Quadrata TT",
                outline = "NONE",
                shadowColour = {r=0, g=0, b=0, a=1},
                shadowOffset = 1,
                textSize = 12,
                colour = {r=1, g=1, b=1, a=1},

                showType = {
                    normal = true,
                    channel = true,
                    empowered = true,
                },

                showOnEffect = {
                    interrupted = false,
                    cancelled = false,
                },

                mainType = "cancelled",

                extraOptions = {
                    useClassColour = true,
                }
            },
            tag5 = {
                name = "Interrupted By",
                show = true,
               tagText = "INTER.- [kName:5]",

                anchorFrom = "RIGHT",
                anchorTo = "RIGHT",
                justify = "RIGHT",
                textOffsetX = -4,
                textOffsetY = 0,
                frameStrata = "OVERLAY",

                font = "Fonts\\FRIZQT__.TTF",
                fontName = "Friz Quadrata TT",
                outline = "NONE",
                shadowColour = {r=0, g=0, b=0, a=1},
                shadowOffset = 1,
                textSize = 12,
                colour = {r=1, g=1, b=1, a=1},

                showType = {
                    normal = true,
                    channel = true,
                    empowered = true,
                },

                showOnEffect = {
                    interrupted = false,
                    cancelled = false,
                },

                mainType = "interrupted",

                extraOptions = {
                    useClassColour = true,
                }
            },
        },
    },

    styleCastType = {
        useGeneralStyle = true,
        default = UCB.Default_DB:createStyle(),
        general = UCB.Default_DB:createStyle(),
        normal = UCB.Default_DB:createStyle(),
        channel = UCB.Default_DB:createStyle(),
        empowered = UCB.Default_DB:createStyle(),
    },

    visibility = {
        frameStrata = "MEDIUM",
        frameLevel = 20,
    },

    uninterruptible = {
        disableBarUnInt = false,

        changeAlphaBarUnint = false,
        includeIconAlphaUnint = true,
        alphaBarUnint = 0.5,

        showUninterruptibleFill = true,
        fillColour = {r=1, g=0, b=0, a=1}, -- red, semi-transparent
        fillTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        fillTextureName = "Blizzard",

        showUninterruptibleBackground = true,
        backgroundColour = {r=1, g=0, b=0, a=0.5}, -- red, semi-transparent
        backgroundUseTexture = false,
        backgroundTexture = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
        backgroundTextureName = "Blizzard Dialog Background Gold",

        showUninterruptibleBorder = false,
        borderColour = {r=1, g=1, b=1, a=1},
        textureBorder = "Interface\\TargetingFrame\\UI-StatusBar",
        textureNameBorder = "Blizzard",
        borderFillCorners = true,
        borderThickness = 1,
        borderOffsetTop = 0,
        borderOffsetBottom = 0,
        borderOffsetLeft = 0,
        borderOffsetRight = 0,

        showUninterruptibleBorderIcon = false,
        syncBorderIcon = true,
        textureBorderIcon = "Interface\\TargetingFrame\\UI-StatusBar",
        textureNameBorderIcon = "Blizzard",
        borderFillCornersIcon = true,
        borderColourIcon = {r=1, g=1, b=1, a=1},
        borderThicknessIcon = 1,
        borderOffsetTopIcon = 0,
        borderOffsetBottomIcon = 0,
        borderOffsetLeftIcon = 0,
        borderOffsetRightIcon = 0,

        disableBarUnKick = false,

        changeAlphaBarUnKick = false,
        dynamicKickAlphaBar = false,
        includeIconAlphaUnKick = true,
        alphaBarUnKick = 0.5,

        showKickTick = false,
        kickTickColour = {r=1, g=0, b=0, a=1}, -- red
        kickTickUseTexture = false,
        kickTickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        kickTickTextureName = "Blizzard",
        kickTickWidth = 2,

        showUntilKickTick = false,
        untilKickTickColour = {r=1, g=0.5, b=0, a=1}, -- orange
        untilKickTickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        untilKickTickTextureName = "Blizzard",
        showUntilKickTickBackground = false,
        untilKickTickBackColour = {r=1, g=0.5, b=0, a=0.5}, -- orange, semi-transparent
        untilKickTickBackUseTexture = false,
        untilKickTickBackTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        untilKickTickBackTextureName = "Blizzard",

        blacklistWhitelist = {
            enableAbilityFilter = false,
            blackList = true,
            useManualTable = true,
            usePlayerSpellList = true,
            blackListSpells = {},
            whiteListSpells = {},
        }

    },

    otherFeatures = {
        showChannelTicks = true,
        useTickTexture = false,
        tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        tickTextureName = "Blizzard",
        channelTickWidth = 2,
        channelTickColour = {r=1, g=1, b=1, a=0.7},
        _prevChannelNumTicks = 0,

        showQueueWindow = {
            normal = true,
            channel = false,
            empowered = false,
        },
        queueMatchCVAR = true,
        queueWindow = 400, -- milliseconds
        queueWindowColour = {r=1, g=0, b=1, a=0.5}, -- magenta, semi-transparent
        useQueueTexture = false,
        queueTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        queueTextureName = "Blizzard",
        queuePlacement = "over", -- "over" or "under"

        latency = {
            enabled = false,
            show = {
                normal = true,
                channel = true,
                empowered = false,
            },
            colour = {r=0, g=1, b=1, a=0.5}, -- cyan, semi-transparent
            useTexture = false,
            texture = "Interface\\TargetingFrame\\UI-StatusBar",
            textureName = "Blizzard",
        },

        invertBar = {
            normal = false,
            channel = false,
            empowered = false,
        },

        mirrorBar = {
            normal = false,
            channel = false,
            empowered = false,
        },

        interruptedEffect = {
            enableEffect = {
                normal = true,
                channel = true,
                empowered = true,
            },
            useSameTextureAsMain = {
                normal = true,
                channel = true,
                empowered = true,
            },
            frameTexture = {
                normal = "Interface\\TargetingFrame\\UI-StatusBar",
                channel = "Interface\\TargetingFrame\\UI-StatusBar",
                empowered = "Interface\\TargetingFrame\\UI-StatusBar",
            },
            frameTextureName = {
                normal = "Blizzard",
                channel = "Blizzard",
                empowered = "Blizzard",
            },
            frameColour = {
                normal = {r=0.5, g=0.5, b=0.5, a=1}, -- grey
                channel = {r=0.5, g=0.5, b=0.5, a=1}, -- grey
                empowered = {r=0.5, g=0.5, b=0.5, a=1}, -- grey
            },
            displayTimer = {
                normal = 0.5,
                channel = 0.5,
                empowered = 0.5,
            },
        },

        cancelledEffect = {
            enableEffect = {
                normal = true,
                channel = true,
                empowered = true,
            },
            useSameTextureAsMain = { 
                normal = true,
                channel = true,
                empowered = true,
            },
            frameTexture = {
                normal = "Interface\\TargetingFrame\\UI-StatusBar",
                channel = "Interface\\TargetingFrame\\UI-StatusBar",
                empowered = "Interface\\TargetingFrame\\UI-StatusBar",
            },
            frameTextureName = {
                normal = "Blizzard",
                channel = "Blizzard",
                empowered = "Blizzard",
            },
            frameColour = {
                normal = {r=1, g=0, b=0, a=1}, -- red
                channel = {r=1, g=0, b=0, a=1}, -- red
                empowered = {r=1, g=0, b=0, a=1}, -- red
            },
            displayTimer = {
                normal = 0.5,
                channel = 0.5,
                empowered = 0.5,
            },
            useManualChannelError = false,
            channelError = 100,

            blacklistWhitelist = {
                enableAbilityFilter = false,
                blackList = true,
                useManualTable = true,
                usePlayerSpellList = true,
                blackListSpells = {},
                whiteListSpells = {},
            }
        },
    },

    previewSettings = {
        previewDuration = 30,
        previewNormalDefaultDuration = false,
        previewEmpowerStages = 5,
        previewSpellID = {
            normal = 585,
            channel = 356995,
            empowered = 359073,
        },
        previewLatency = 0.123,
        previewNotIntrerruptible = false,
        previewShowKickCD = true,
        previewKickCD = 2,
    },

    copySettings = {
        paths = {
            general = true,
            text = true,
            styleCastType = true,
            visibility = true,
            uninterruptible = true,
            otherFeatures = true,
            CLASSES = true,
        }
    },

    CLASSES = {

        WARRIOR = {
        },

        PALADIN = {
        },

        HUNTER = {
        },

        ROGUE = {
        },

        PRIEST = {
        },

        DEATHKNIGHT = {
        },

        SHAMAN = {
        },

        MAGE = {
        },

        WARLOCK = {
        },

        MONK = {
        },

        DRUID = {
        },

        DEMONHUNTER = {
        },

        EVOKER = {

            disintegrateDynamicTicks = true,

            enableEmpowerEffects = true,
            empowerManualTicks = {0.19, 0.33, 0.47, 0.60},
            _empowerManualTicksDefault = {[5]={0.19, 0.33, 0.47, 0.60}, [4]={0.24, 0.42, 0.60}},
            empowerTickWidth = 2,
            empowerStageTickColours = {
                {r=0, g=1, b=0, a=1},    -- Stage 1 (Green)
                {r=1, g=1, b=0, a=1},    -- Stage 2 (Yellow)
                {r=1, g=0.5, b=0, a=1},  -- Stage 3 (Orange)
                {r=1, g=0, b=0, a=1},    -- Stage 4 (Red)
            },
            empowerSegBackColours = {
                {r=1, g=1, b=1, a=0.25},   -- Segment 0
                {r=0, g=1, b=0, a=0.25},   -- Segment 1
                {r=1, g=1, b=0, a=0.25},   -- Segment 2
                {r=1, g=0.5, b=0, a=0.25}, -- Segment 3
                {r=1, g=0, b=0, a=0.25},   -- Segment 4
            },
            empowerBarColours = {
                {r=1, g=1, b=1, a=0.8},   -- Segment 0
                {r=0, g=1, b=0, a=0.8},   -- Segment 1
                {r=1, g=1, b=0, a=0.8},   -- Segment 2
                {r=1, g=0.5, b=0, a=0.8}, -- Segment 3
                {r=1, g=0, b=0, a=0.8},   -- Segment 4
            },

            showEmpowerTickTexture = false,
            showEmpowerSegmentTexture = false,
            empowerTickTextures = {
                "Interface\\TargetingFrame\\UI-StatusBar",
                "Interface\\TargetingFrame\\UI-StatusBar",
                "Interface\\TargetingFrame\\UI-StatusBar",
                "Interface\\TargetingFrame\\UI-StatusBar",
            },

            empowerTickTexturesNames = {
                "Blizzard",
                "Blizzard",
                "Blizzard",
                "Blizzard",
            },
            empowerSegmentTextures = {
                "Interface\\TargetingFrame\\UI-StatusBar",
                "Interface\\TargetingFrame\\UI-StatusBar",
                "Interface\\TargetingFrame\\UI-StatusBar",
                "Interface\\TargetingFrame\\UI-StatusBar",
                "Interface\\TargetingFrame\\UI-StatusBar",
            },
            empowerSegmentTexturesNames = {
                "Blizzard",
                "Blizzard",
                "Blizzard",
                "Blizzard",
                "Blizzard",
            }
        },
    },

    defaultBar = {
        enabled = false,
        defaultConfig = true,
        shorBarOnEnable = true,
        blizzBarScale = 1,
        offsetX = 0,
        offsetY = 0,
        anchorPoint = "CENTER",
    },
}


for class, classSettings in pairs(UCB.Default_DB.player.CLASSES) do
    UCB.Default_DB.player.CLASSES[class] = merge(classSettings, createClassSettings())
end


