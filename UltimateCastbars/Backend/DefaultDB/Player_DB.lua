local _, UCB = ...

UCB.Default_DB = UCB.Default_DB or {}

UCB.Default_DB.Player = {
     enabled = true,

    general = {
        offsetX = 0,
        offsetY = 0,
        anchorFrom = "CENTER", --"TOP" "BOTTOM" "LEFT" "RIGHT" "CENTER" "TOPLEFT" "TOPRIGHT" "BOTTOMLEFT" "BOTTOMRIGHT"
        anchorTo = "CENTER",
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
        syncIconBar = false,
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
        newIDTags = 4,
        oldIDTags = {},
        useGlobalFont = false,
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

            _dynamicTag = false,
            _type = "Unknown",
            _typeColour = "grey",
            _formula = {},
            _limits = {},

        },
        tagList = {
            dynamic = {
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
                },
            },
            semiDynamic = {
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
                },
            },
            static = {
            },
            unk = {
            }
        },
    },

    style = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        textureName = "Blizzard",
        textureBack = "Interface\\DialogFrame\\UI-DialogBox-Background",
        textureNameBack = "Blizzard Dialog Background",
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

        showBorder = false,
        borderThickness = 1,
        borderColour = {r=1, g=1, b=1, a=1},
        borderOffsetTop = 0,
        borderOffsetBottom = 0,
        borderOffsetLeft = 0,
        borderOffsetRight = 0,

        
        showBorderIcon = false,
        syncBorderIcon = false,
        borderThicknessIcon = 1,
        borderColourIcon = {r=1, g=1, b=1, a=1},
        borderOffsetTopIcon = 0,
        borderOffsetBottomIcon = 0,
        borderOffsetLeftIcon = 0,
        borderOffsetRightIcon = 0,
    },

    visibility = {
        frameStrata = "MEDIUM",
        frameLevel = 20,
    },

    unintreruptable = {
        showColour = false,
        colour = {r=0.5, g=0.5, b=0.5, a=1}, -- grey

        showBackground = false,
        bgColour = {r=0, g=0, b=0, a=1},
       
        showBorder = false,
        borderTexture = "Interface\\Buttons\\WHITE8X8",
        borderTextureName = "1 Pixel",
        borderColour = {r=0.5, g=0.5, b=0.5, a=1}, -- grey
        borderThickness = 5,
        
        borderOffsetTop = 0,
        borderOffsetBottom = 0,
        borderOffsetLeft = 0,
        borderOffsetRight = 0,

        showBorderIcon = false,
        borderTextureIcon = "Interface\\Buttons\\WHITE8X8",
        borderTextureNameIcon = "1 Pixel",
        borderColourIcon = {r=0.5, g=0.5, b=0.5, a=1}, -- grey
        borderThicknessIcon = 5,
        borderOffsetTopIcon = 0,
        borderOffsetBottomIcon = 0,
        borderOffsetLeftIcon = 0,
        borderOffsetRightIcon = 0,

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

        invertBar = {
            normal = false,
            channel = false,
            empowered = false,
        },

    },

    previewSettings = {
        previewDuration = 30,
        previewNormalDefaultDuration = false,
        previewEmpowerStages = 5,
        previewNotIntrerruptible = true,
        previewSpellID = {
            normal = 359073,
            channel = 198013,
            empowered = 339690,
        }
        
    },

    CLASSES = {

        WARRIOR = {
            useMainSettingsChannel = true,
            channeledSpels = {},
            showChannelTicks = true,
            useTickTexture = false,
            tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            tickTextureName = "Blizzard",
            channelTickWidth = 2,
            channelTickColour = {r=1, g=1, b=1, a=0.7},
        },

        PALADIN = {
            useMainSettingsChannel = true,
            channeledSpels = {},
            showChannelTicks = true,
            useTickTexture = false,
            tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            tickTextureName = "Blizzard",
            channelTickWidth = 2,
            channelTickColour = {r=1, g=1, b=1, a=0.7},
        },

        HUNTER = {
            useMainSettingsChannel = true,
            channeledSpels = {},
            showChannelTicks = true,
            useTickTexture = false,
            tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            tickTextureName = "Blizzard",
            channelTickWidth = 2,
            channelTickColour = {r=1, g=1, b=1, a=0.7},
        },

        ROGUE = {
            useMainSettingsChannel = true,
            channeledSpels = {},
            showChannelTicks = true,
            useTickTexture = false,
            tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            tickTextureName = "Blizzard",
            channelTickWidth = 2,
            channelTickColour = {r=1, g=1, b=1, a=0.7},
        },

        PRIEST = {
            useMainSettingsChannel = true,
            channeledSpels = {},
            showChannelTicks = true,
            useTickTexture = false,
            tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            tickTextureName = "Blizzard",
            channelTickWidth = 2,
            channelTickColour = {r=1, g=1, b=1, a=0.7},
        },

        DEATHKNIGHT = {
            useMainSettingsChannel = true,
            channeledSpels = {},
            showChannelTicks = true,
            useTickTexture = false,
            tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            tickTextureName = "Blizzard",
            channelTickWidth = 2,
            channelTickColour = {r=1, g=1, b=1, a=0.7},
        },

        SHAMAN = {
            useMainSettingsChannel = true,
            channeledSpels = {},
            showChannelTicks = true,
            useTickTexture = false,
            tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            tickTextureName = "Blizzard",
            channelTickWidth = 2,
            channelTickColour = {r=1, g=1, b=1, a=0.7},
        },

        MAGE = {
            useMainSettingsChannel = true,
            channeledSpels = {},
            showChannelTicks = true,
            useTickTexture = false,
            tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            tickTextureName = "Blizzard",
            channelTickWidth = 2,
            channelTickColour = {r=1, g=1, b=1, a=0.7},
        },

        WARLOCK = {
            useMainSettingsChannel = true,
            channeledSpels = {},
            showChannelTicks = true,
            useTickTexture = false,
            tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            tickTextureName = "Blizzard",
            channelTickWidth = 2,
            channelTickColour = {r=1, g=1, b=1, a=0.7},
        },

        MONK = {
            useMainSettingsChannel = true,
            channeledSpels = {},
            showChannelTicks = true,
            useTickTexture = false,
            tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            tickTextureName = "Blizzard",
            channelTickWidth = 2,
            channelTickColour = {r=1, g=1, b=1, a=0.7},
        },

        DRUID = {
            useMainSettingsChannel = true,
            channeledSpels = {},
            showChannelTicks = true,
            useTickTexture = false,
            tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            tickTextureName = "Blizzard",
            channelTickWidth = 2,
            channelTickColour = {r=1, g=1, b=1, a=0.7},
        },

        DEMONHUNTER = {
            useMainSettingsChannel = true,
            channeledSpels = {},
            showChannelTicks = true,
            useTickTexture = false,
            tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            tickTextureName = "Blizzard",
            channelTickWidth = 2,
            channelTickColour = {r=1, g=1, b=1, a=0.7},
        },

        EVOKER = {
            useMainSettingsChannel = true,
            channeledSpels = {},
            showChannelTicks = true,
            useTickTexture = false,
            tickTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            tickTextureName = "Blizzard",
            channelTickWidth = 2,
            channelTickColour = {r=1, g=1, b=1, a=0.7},

            disintegrateDynamicTicks = true,
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

    debug = {
        enabled = false,
        _addonList = {}
    },
}


