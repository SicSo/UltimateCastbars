local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.Text_API = UCB.Text_API or {}

local Opt = UCB.Options
local CASTBAR_API = UCB.CASTBAR_API
local CFG_API = UCB.CFG_API
local GetCfg = CFG_API.GetValueConfig
local UIOptions = UCB.UIOptions
local Text_API = UCB.Text_API

UCB.Options._textTreeArgs = UCB.Options._textTreeArgs or {}


local function GoToTag(unit, tagKey)
    UCB:SelectGroup(unit, {"text", tagKey})
end

local function BuildTagButtons(unit)
  local text = GetCfg(unit).text 
  text.tagList = text.tagList or {}

  local btns, order = {}, 1

  for tagType, tagTable in pairs(text.tagList) do
    for key, _ in pairs(tagTable) do
      local tcfg = GetCfg(unit).text.tagList[tagType][key]

      btns["btn_" .. key] = {
        type  = "execute",
        name  = function() return tostring(tcfg.name) end, -- now live
        order = order,
        width = "quarter",
        func  = function() GoToTag(unit, key) end,
      }
      order = order + 1
    end
  end

  return btns
end


local function RefreshTagPickerButtons(unit)
    local tree = UCB.Options._textTreeArgs
    if not tree or not tree.tagPicker then return end
    tree.tagPicker.args = BuildTagButtons(unit)
end




local function tagUI(key, tagType, unit)
    local args = {}
    local bigCFG = GetCfg(unit).text
    local cfg = GetCfg(unit).text.tagList[tagType][key]
    
    args.deleteButton = {
        type = "execute",
        name = "Delete Tag",
        order = 0,
        confirm = function() return "Are you sure you want to delete this tag?" end,
        func = function()
            Text_API:deleteTag(key, cfg, bigCFG)

          
           local treeArgs = UCB.Options._textTreeArgs 
           treeArgs[key] = nil
           RefreshTagPickerButtons(unit)

            UCB:NotifyChange(unit)

            UCB:SelectGroup(unit, {"text"})

            CASTBAR_API:UpdateCastbar(unit)
        end,
    }
    args.grpControls = {
        type = "group",
        name = "Tag Management",
        order = 1,
        inline = true,
        args = {
            -- ---- Name (input)
            name = {
                type = "input",
                name = "Name",
                order = 1,
                width = "full",
                get = function() return tostring(cfg.name) end,
                set = function(_, v) cfg.name = tostring(v) end,
            },
            -- ---- Enabled toggle
            show = {
                type = "toggle",
                name = "Show",
                order = 2,
                width = "full",
                get = function() return cfg.show end,
                set = function(_, v) 
                    cfg.show = v and true or false 
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            }
        },
    }
    args.titleOptions = {
        type = "header",
        name = "Tag Customisation Options",
        order = 1.5,
    }

    args.grpShow = {
        type = "group",
        name = "Show On",
        order = 2,
        inline = true,
        args = {
            showNormal = {
                type = "toggle",
                name = "Normal Casts",
                order = 1,
                get = function() return cfg.showType.normal end,
                set = function(_, v)
                    cfg.showType.normal = v
                    if Text_API:updateStaticShow(key, cfg, bigCFG) then
                        UCB:NotifyChange(unit)
                    end
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
            showChannel = {
                type = "toggle",
                name = "Channelled Casts",
                order = 2,
                get = function() return cfg.showType.channel end,
                set = function(_, v) 
                    cfg.showType.channel = v
                    if Text_API:updateStaticShow(key, cfg, bigCFG) then
                        UCB:NotifyChange(unit)
                    end
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
            showEmpowered = {
                type = "toggle",
                name = "Empowered Casts",
                order = 3,
                get = function() return cfg.showType.empowered end,
                set = function(_, v) 
                    cfg.showType.empowered = v
                    if Text_API:updateStaticShow(key, cfg, bigCFG) then
                        UCB:NotifyChange(unit)
                    end
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
        }
    }

    args.grpText = {
        type = "group",
        name = "Text Options",
        order = 3,
        inline = true,
        args = {
            -- ---- Tag text (input)
            tagText = {
                type = "input",
                name = "Tag Text",
                order = 1,
                width = "full",
                get = function() return tostring(cfg.tagText) end,
                set = function(_, v)
                        if v ~= "" then
                            cfg.tagText = tostring(v)
                            Text_API:updateTagText(key, cfg, bigCFG)
                            UCB:NotifyChange(unit)
                            CASTBAR_API:UpdateCastbar(unit)
                        end
                    end,
            },
            tagHint1 = {
                type = "description",
                name = "Available Preset Tags:\n" ..
                       UIOptions.ColorText(UIOptions.turquoise, "[sName:X]").." - Spell Name (X repesents the number of maximum allowed characters with an additioanl \"...\" and can be ommited for the use [sName], default is full text; text is seen as default)\n" ..
                       UIOptions.ColorText(UIOptions.turquoise, "[rTime:X]").." - Remaining Time (in seconds, X repesents the number of decimals and can be ommited for thse use of [rTime], default is 1 decimal; text is seen as default)\n" ..
                       UIOptions.ColorText(UIOptions.turquoise, "[rTimeInv:X]").." - Invesre Remaining Time (in seconds, X repesents the number of decimals and can be ommited for thse use of [rTime], default is 1 decimal; text is seen as default)\n" ..
                       UIOptions.ColorText(UIOptions.turquoise, "[dTime:X]").." - Duration Time (in seconds, X repesents the number of decimals and can be ommited for thse use of [dTime], default is 1 decimal; text is seen as default)\n" ..
                       UIOptions.ColorText(UIOptions.turquoise, "[rPerTime:X]").." - Remaining Time Percentage (X repesents the number of decimals and can be ommited for thse use of [rPerTime], default is 1 decimal; text is seen as default)\n" ..
                       UIOptions.ColorText(UIOptions.turquoise, "[rPerTimeInv:X]").." - Inverse Remaining Time Percentage (X repesents the number of decimals and can be ommited for thse use of [rPerTime], default is 1 decimal; text is seen as default)\n" ..
                       UIOptions.ColorText(UIOptions.turquoise, "[dPerTime]").." - Duration Time Percentage (just 100)"..
                       UIOptions.ColorText(UIOptions.turquoise, "[cIntr:X]").." - Intreruptable spell (X reprsents the text displayed, by ommiting it is Intr.)"..
                       UIOptions.ColorText(UIOptions.turquoise, "[cIntrInv:X]").." - Unintreruptable spell (X reprsents the text displayed, by ommiting it is Unintr.)",
                width = "full",
                order = 2,
            },
            tagType = {
                type = "header",
                name = function() return "Tag Type: "..UIOptions.ColorText(UIOptions[cfg._typeColour], cfg._type) end,
                order = 3,
            },
            tagHint2 = {
                type = "description",
                name = "The type of a tag is determined by the components used in its formula. Each type has a different performance penalty attached to it.\n" ..
                       UIOptions.ColorText(UIOptions.green, "Static").." tags contain only static text inputed by the user so they are loaded once or when they are chnaged through the UI.\n".. 
                       UIOptions.ColorText(UIOptions.yellow, "Semi-Dynamic").." tags contain at least one of the preset tags provided which come with a smaller penalty beacuse they are loaded once every cast.\n"..
                       UIOptions.ColorText(UIOptions.red, "Dynamic").." tags contain at least one of the preset tags provided which come with a largest penalty because they are loaded every frame.\n"..
                       "Each peset tag has its own class of penalty due to its nature. "..UIOptions.ColorText(UIOptions.red,"DYNAMIC")..": [rTime], [rPerTime], [rTimeInv], [rPerTimeInv]; "..UIOptions.ColorText(UIOptions.yellow,"SEMI-DYNAMIC")..": [sName], [dTime], [dPerTime], [cIntr], [cIntrInv].\n"..
                       "If the state of a "..UIOptions.ColorText(UIOptions.green, "STATIC").." tag is conditionally changed based on type of cast (normal/channel/empowered) it will be converted to a "..UIOptions.ColorText(UIOptions.yellow,"SEMI-DYNAMIC").." tag automatically.",
                width = "full",
                order = 4,
            },
        }
    }

    -- ---- Anchor dropdown
    args.grpAnchors = {
        type = "group",
        name = "Anchor Options",
        order = 4,
        inline = true,
        args = {
            anchorFrom = {
                type = "select",
                name = "Anchor From",
                order = 1,
                values = UIOptions.anchors,
                get = function() return cfg.anchorFrom end,
                set = function(_, v) 
                    cfg.anchorFrom = v 
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
            anchorTo = {
                type = "select",
                name = "Anchor To",
                order = 2,
                values = UIOptions.anchors,
                get = function() return cfg.anchorTo end,
                set = function(_, v)
                    cfg.anchorTo = v
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
            -- ---- Justify dropdown
            justify = {
                type = "select",
                name = "Justify",
                order = 3,
                values = UIOptions.justify,
                get = function() return cfg.justify end,
                set = function(_, v) 
                    cfg.justify = v 
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            }
        }
    }

    args.grpPosition = {
        type = "group",
        name = "Text position",
        order = 5,
        inline = true,
        args = {
            textOffsetX = {
                type = "range",
                name = "X",
                order = 1,
                min = UIOptions.textOffsetMin, max = UIOptions.textOffsetMax, step = 1,
                get = function() return cfg.textOffsetX end,
                set = function(_, v)
                    cfg.textOffsetX = v
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
            textOffsetY = {
                type = "range",
                name = "Y",
                order = 2,
                min = UIOptions.textOffsetMin, max = UIOptions.textOffsetMax, step = 1,
                get = function() return cfg.textOffsetY end,
                set = function(_, v)
                    cfg.textOffsetY = v
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
            frameStrata = {
                type  = "select",
                name  = "Strata",
                desc  = "Controls which UI layer the text bar is drawn on. Higher strata shows above lower strata.",
                order = 3,
                --width = 1.5,
                values = UIOptions.stratSubComponents,
                sorting = {
                    "BACKGROUND","BORDER","ARTWORK","OVERLAY",
                },
                get = function() return cfg.frameStrata end,
                set = function(_, val)
                    cfg.frameStrata = val
                    CASTBAR_API:UpdateCastbar(unit)
                end,
            },
        }
    }

    args.grpStyle = {
        type = "group",
        name = "Text Style",
        order = 6,
        inline = true,
        args = {
            font = Text_API:MakeLSMFontOption(cfg, 0.5, nil, function() return cfg.show == false end, unit),
            textSize = {
                type = "range",
                name = "Text Size",
                order = 1,
                min = UIOptions.sizeMin_text, max = UIOptions.sizeMax_text, step = 2,
                get = function() return cfg.textSize end,
                set = function(_, v)
                    cfg.textSize = v
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
            outline = {
                type = "select",
                name = "Outline",
                order = 2,
                values = UIOptions.fontOutlines,
                sorting = {
                    "NONE", "OUTLINE", "THICKOUTLINE", "MONO_NONE", "MONO_OUTLINE", "MONO_THICKOUTLINE", "SHADOW", "SHADOW_OUTLINE", "SHADOW_THICKOUTLINE",
                },
                get = function() return cfg.outline end,
                set = function(_, v)
                    cfg.outline = v
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
            },
            shadowOffset = {
                type = "range",
                name = "Shadow Offset",
                order = 3,
                min = UIOptions.shadowOffsetMin, max = UIOptions.shadowOffsetMax, step = 1,
                get = function() return cfg.shadowOffset end,
                set = function(_, v)
                    cfg.shadowOffset = v
                    CASTBAR_API:UpdateCastbar(unit)
                    end,
                disabled = function()
                    local tags, shadow = Text_API:OutlineFlags(cfg.outline)
                    return shadow == false
                end,
            },
            shadowColour = {
                type = "color",
                name = "Shadow Color",
                order = 4,
                hasAlpha = true,
                get = function()
                local c = cfg.shadowColour or {}
                return c.r, c.g, c.b, c.a
                end,
                set = function(_, r, g, b, a)
                cfg.shadowColour = cfg.shadowColour or {}
                cfg.shadowColour.r, cfg.shadowColour.g, cfg.shadowColour.b, cfg.shadowColour.a = r, g, b, a
                CASTBAR_API:UpdateCastbar(unit)
                end,
                disabled = function()
                    local tags, shadow = Text_API:OutlineFlags(cfg.outline)
                    return shadow == false
                end,
            },

            -- ---- Color picker
            colour = {
                type = "color",
                name = "Text Color",
                order = 5,
                hasAlpha = true,
                get = function()
                local c = cfg.colour or {}
                return c.r, c.g, c.b, c.a
                end,
                set = function(_, r, g, b, a)
                cfg.colour = cfg.colour or {}
                cfg.colour.r, cfg.colour.g, cfg.colour.b, cfg.colour.a = r, g, b, a
                CASTBAR_API:UpdateCastbar(unit)
                end,
            }
        }
    }

    return args
end


local function addTagUI(unit)
    local cfg  = GetCfg(unit).text
    local generalCFG = cfg.generalValues
    local newName = ""
    local treeArgs = UCB.Options._textTreeArgs
    treeArgs.grpAdd = {
        type = "group",
        name = "Add New Tag",
        order = 1,
        inline = true,
        args = {
            name = {
                type = "input",
                name = "Name",
                order = 1,
                width = "full",
                get = function() return newName end,
                set = function(_, v)
                    newName = tostring(v or "")
                    end,
            },
            addButton = {
                type = "execute",
                name = "Add New Tag",
                order = 2,
                func = function()
                    if newName ~= "" then
                        local key, newCFG, state = Text_API:addNewTag(cfg, newName)
                        treeArgs[key] = {
                            type = "group",
                            name = function() return tostring(newCFG.name) end,
                            order = table.maxn(treeArgs) + 1,
                            args = tagUI(key, state, unit),
                        }
                        newName = ""
                        RefreshTagPickerButtons(unit)
                        UCB:NotifyChange(unit)
                        UCB:SelectGroup(unit, {"text", key})
                    end
                end,
            },
            
        }
    }
    treeArgs.tagPicker = {
        type = "group",
        name = "Jump to tag",
        order = 2,
        inline = true,
        args = BuildTagButtons(unit),
    }

    treeArgs.grpGeneralOpt = {
        type = "group",
        name = "General Text Options",
        order = 3,
        inline = true,
        args = {
            fontGrp = {
                type = "group",
                name = "Font Options",
                order = 1,
                inline = true,
                args = {
                    useGeneralFont = {
                        type = "toggle",
                        name = "Use General Font",
                        order = 1,
                        get = function() return generalCFG.useGeneralFont end,
                        set = function(_, v)
                            generalCFG.useGeneralFont = v and true or false
                            CASTBAR_API:UpdateCastbar(unit)
                            end,
                    },
                    useGlobalFont = {
                        type = "toggle",
                        name = "Use Global Font",
                        order = 2,
                        get = function() return generalCFG.useGlobalFont end,
                        set = function(_, v)
                            generalCFG.useGlobalFont = v and true or false
                            CASTBAR_API:UpdateCastbar(unit)
                            end,
                        disabled = function() return not generalCFG.useGeneralFont end,
                    },
                    font = Text_API:MakeLSMFontOption(generalCFG, 3, nil, function() return not generalCFG.useGeneralFont and not generalCFG.useGlobalFont end, unit),
                },
            },
            sizeGrp = {
                type = "group",
                name = "Size Options",
                order = 2,
                inline = true,
                args = {
                    useGeneralSize = {
                        type = "toggle",
                        name = "Use General Size",
                        order = 1,
                        get = function() return generalCFG.useGeneralSize end,
                        set = function(_, v)
                            generalCFG.useGeneralSize = v and true or false
                            CASTBAR_API:UpdateCastbar(unit)
                            end,
                    },
                    textSize = {
                        type = "range",
                        name = "Text Size",
                        order = 2,
                        min = UIOptions.sizeMin_text, max = UIOptions.sizeMax_text, step = 2,
                        get = function() return generalCFG.textSize end,
                        set = function(_, v)
                            generalCFG.textSize = v
                            CASTBAR_API:UpdateCastbar(unit)
                            end,
                        disabled = function() return not generalCFG.useGeneralSize end,
                    },
                },
            },
            outlinrGrp = {
                type = "group",
                name = "Outline Options",
                order = 3,
                inline = true,
                args = {
                    useGeneralOutline = {
                        type = "toggle",
                        name = "Use General Outline",
                        order = 1,
                        get = function() return generalCFG.useGeneralOutline end,
                        set = function(_, v)
                            generalCFG.useGeneralOutline = v and true or false
                            CASTBAR_API:UpdateCastbar(unit)
                            end,
                    },
                    outline = {
                        type = "select",
                        name = "Outline",
                        order = 2,
                        values = UIOptions.fontOutlines,
                        sorting = {
                            "NONE", "OUTLINE", "THICKOUTLINE", "MONO_NONE", "MONO_OUTLINE", "MONO_THICKOUTLINE", "SHADOW", "SHADOW_OUTLINE", "SHADOW_THICKOUTLINE",
                        },
                        get = function() return generalCFG.outline end,
                        set = function(_, v)
                            generalCFG.outline = v
                            CASTBAR_API:UpdateCastbar(unit)
                            end,
                        disabled = function() return not generalCFG.useGeneralOutline end,
                    },
                    shadowOffset = {
                        type = "range",
                        name = "Shadow Offset",
                        order = 3,
                        min = UIOptions.shadowOffsetMin, max = UIOptions.shadowOffsetMax, step = 1,
                        get = function() return generalCFG.shadowOffset end,
                        set = function(_, v)
                            generalCFG.shadowOffset = v
                            CASTBAR_API:UpdateCastbar(unit)
                            end,
                        disabled = function()
                            local tags, useShadow = Text_API:OutlineFlags(generalCFG.outline)
                            return not generalCFG.useGeneralOutline or not useShadow
                        end,
                    },
                    shadowColour = {
                        type = "color",
                        name = "Shadow Colour",
                        order = 4,
                        hasAlpha = true,
                        get = function()
                            local c = generalCFG.shadowColour or {}
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            generalCFG.shadowColour = generalCFG.shadowColour or {}
                            generalCFG.shadowColour.r, generalCFG.shadowColour.g, generalCFG.shadowColour.b, generalCFG.shadowColour.a = r, g, b, a
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                        disabled = function()
                            local tags, useShadow = Text_API:OutlineFlags(generalCFG.outline)
                            return not generalCFG.useGeneralOutline or not useShadow
                        end,
                    },
                },
            },
            colorGrp = {
                type = "group",
                name = "Color Options",
                order = 3,
                inline = true,
                args = {
                    useGeneralColor = {
                        type = "toggle",
                        name = "Use General Color",
                        order = 1,
                        get = function() return generalCFG.useGeneralColor end,
                        set = function(_, v)
                            generalCFG.useGeneralColor = v and true or false
                            CASTBAR_API:UpdateCastbar(unit)
                            end,
                    },
                    colour = {
                        type = "color",
                        name = "Text Color",
                        order = 2,
                        hasAlpha = true,
                        get = function()
                            local c = generalCFG.colour or {}
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            generalCFG.colour = generalCFG.colour or {}
                            generalCFG.colour.r, generalCFG.colour.g, generalCFG.colour.b, generalCFG.colour.a = r, g, b, a
                            CASTBAR_API:UpdateCastbar(unit)
                        end,
                        disabled = function() return not generalCFG.useGeneralColor end,
                    },
                },
            }
        }
    }
end


local function BuildTagsTreeArgs(unit)
    --print("Here")
    local text = GetCfg(unit).text
    text.tagList = text.tagList or {}

    local args, order = {}, 1

    for tagType, tagTable in pairs(text.tagList) do
        for key, _ in pairs(tagTable) do
            local cfg = GetCfg(unit).text.tagList[tagType][key]

            args[key] = {
                type  = "group",
                name  = function() return tostring(cfg.name) end,
                order = order,
                args  = tagUI(key, tagType, unit),
            }
            order = order + 1
        end
    end

    return args
end


function Opt.BuildGeneralSettingsTextArgs(unit, opts)
    opts = opts or {}
    local tree = UCB.Options._textTreeArgs
    wipe(tree)

    addTagUI(unit)  -- just to initialise new tag UI elements

    local tags = BuildTagsTreeArgs(unit)
    for k, v in pairs(tags) do
        tree[k] = v
    end

    return tree
end
