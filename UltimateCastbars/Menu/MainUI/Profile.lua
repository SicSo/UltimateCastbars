local _, UCB = ...

UCB.UIOptions = UCB.UIOptions or {}
UCB.Profiles = UCB.Profiles or {}
UCB.GUI = UCB.GUI or {}
UCB.Normiliser = UCB.Normiliser or {}

local Profiles = UCB.Profiles
local GUI = UCB.GUI
local Normiliser = UCB.Normiliser
local UIOptions = UCB.UIOptions


local function EncodeExportString(serialized)
    local LD = LibStub("LibDeflate", true)
    if not LD then return serialized end -- fallback: no compression

    local compressed = LD:CompressDeflate(serialized)
    if not compressed then return serialized end

    return LD:EncodeForPrint(compressed)
end

local function DecodeImportString(encoded)
    local LD = LibStub("LibDeflate", true)
    if not LD then return encoded end -- fallback: treat as raw serialized

    local decoded = LD:DecodeForPrint(encoded or "")
    if not decoded then
        -- not a LibDeflate string, assume raw AceSerializer text
        return encoded
    end

    local decompressed = LD:DecompressDeflate(decoded)
    if not decompressed then
        return nil, "Decompress failed."
    end

    return decompressed
end



local function ExportFilteredProfile(profileName)
    local Serializer = LibStub("AceSerializer-3.0", true)
    if not Serializer then
        print("UCB: AceSerializer-3.0 not found.")
        return ""
    end

    local defaults = UCB:GetDefaultDB()
    local schemaProfile = defaults and defaults.profile
    if not schemaProfile then
        print("UCB: No default schema found.")
        return ""
    end

    -- Choose source profile without switching
    local srcProfile
    if profileName and profileName ~= "" then
        srcProfile = UCB.db.profiles and UCB.db.profiles[profileName]
        if type(srcProfile) ~= "table" then
            print("UCB: Profile not found: " .. tostring(profileName))
            return ""
        end
    else
        srcProfile = UCB.db.profile -- current
    end

    local filtered = Normiliser:FilterBySchema(srcProfile, schemaProfile)

    local function ExpandTagLists(unitKey)
        local srcUnit = srcProfile[unitKey]
        local dstUnit = filtered[unitKey]
        if type(srcUnit) ~= "table" or type(dstUnit) ~= "table" then return end

        local schemaUnit = schemaProfile[unitKey]
        local schemaText = schemaUnit and schemaUnit.text
        local template   = schemaText and schemaText.defaultValues
        if type(template) ~= "table" then return end

        local srcText = srcUnit.text
        local dstText = dstUnit.text
        if type(srcText) ~= "table" or type(dstText) ~= "table" then return end

        local srcTagList = srcText.textList
        if type(srcTagList) ~= "table" then return end

        dstText.textList = dstText.textList or {}

        local outMap = {}
        for tagKey, tagTable in pairs(srcTagList) do
            if type(tagKey) == "string" and type(tagTable) == "table" then
                outMap[tagKey] = Normiliser:FilterBySchema(tagTable, template)
            end
        end
        dstText.textList = outMap
         
    end

    ExpandTagLists("player")
    ExpandTagLists("target")
    ExpandTagLists("focus")

    local s = Serializer:Serialize(filtered)
    return EncodeExportString(s)
end


local function ImportFilteredProfile(targetProfileName, serialized)
    local Serializer = LibStub("AceSerializer-3.0", true)
    if not Serializer then
        return false, "AceSerializer-3.0 not found."
    end

    local decoded, derr = DecodeImportString(serialized or "")
    if not decoded then
        return false, derr or "Bad import string."
    end

    local ok, data = Serializer:Deserialize(decoded)
    if not ok or type(data) ~= "table" then
        return false, "Bad import string."
    end

    local defaults = UCB:GetDefaultDB()
    local schemaProfile = defaults and defaults.profile
    if not schemaProfile then
        return false, "No default schema found."
    end

    local filtered = Normiliser:FilterBySchema(data, schemaProfile)

    local function ExpandTagLists(unitKey)
        local srcUnit = data[unitKey]
        local dstUnit = filtered[unitKey]
        if type(srcUnit) ~= "table" or type(dstUnit) ~= "table" then return end

        local schemaUnit = schemaProfile[unitKey]
        local schemaText = schemaUnit and schemaUnit.text
        local template   = schemaText and schemaText.defaultValues
        if type(template) ~= "table" then return end

        local srcText = srcUnit.text
        local dstText = dstUnit.text
        if type(srcText) ~= "table" or type(dstText) ~= "table" then return end

        local srcTagList = srcText.textList
        if type(srcTagList) ~= "table" then return end

        dstText.textList = dstText.textList or {}

        local outMap = {}
        for tagKey, tagTable in pairs(srcTagList) do
            if type(tagKey) == "string" and type(tagTable) == "table" then
                outMap[tagKey] = Normiliser:FilterBySchema(tagTable, template)
            end
        end
        dstText.textList = outMap
    end

    ExpandTagLists("player")
    ExpandTagLists("target")
    ExpandTagLists("focus")

    local rebuilt = Normiliser:DeepCopyTable(schemaProfile)
    Normiliser:Overlay(rebuilt, filtered)

    Normiliser:NormalizeAllUnitTextures(rebuilt)
    Normiliser:NormalizeAllUnitFonts(rebuilt)

    -- Choose destination without switching
    local destTable
    if targetProfileName and targetProfileName ~= "" then
        UCB.db.profiles = UCB.db.profiles or {}
        destTable = UCB.db.profiles[targetProfileName]
        if type(destTable) ~= "table" then
            destTable = {}
            UCB.db.profiles[targetProfileName] = destTable
        end
    else
        destTable = UCB.db.profile -- current
    end

    wipe(destTable)
    for k, v in pairs(rebuilt) do
        destTable[k] = v
    end

    -- If we imported into the active profile, re-apply immediately
    local activeName = UCB.db.GetCurrentProfile and UCB.db:GetCurrentProfile()
    if not targetProfileName or targetProfileName == "" or targetProfileName == activeName then
        if UCB.UpdateAllCastBars then
            UCB:UpdateAllCastBars()
        end
    end

    return true
end


local function GetProfileValues(excludeCurrent)
    local vals = {}
    if not UCB.db or not UCB.db.GetProfiles then return vals end
    local current = nil
    if excludeCurrent and UCB.db.GetCurrentProfile then
        current = UCB.db:GetCurrentProfile()
    end
    local list = UCB.db:GetProfiles()
    for _, name in ipairs(list) do
        if name ~= current then
            vals[name] = name
        end
    end
    return vals
end


local function DeepCopySimple(orig, seen)
    if type(orig) ~= "table" then
        return orig
    end

    seen = seen or {}
    if seen[orig] then
        return seen[orig]
    end

    local copy = {}
    seen[orig] = copy

    for k, v in pairs(orig) do
        -- avoid copying userdata/frames/forbidden things recursively
        if type(v) == "table" then
            copy[k] = DeepCopySimple(v, seen)
        else
            copy[k] = v
        end
    end

    return copy
end

local function AttachLibDualSpecPluginWithoutNew(customOptions, db)
    local LibDualSpec = LibStub and LibStub("LibDualSpec-1.0", true)
    if not LibDualSpec or not customOptions or not db then
        return false
    end

    local aceProfilesMgmt = UCB.ADBO:GetOptionsTable(db)
    if not aceProfilesMgmt then
        return false
    end

    local pluginKey = "LibDualSpec-1.0"

    -- Make sure DB is enhanced
    LibDualSpec:EnhanceDatabase(db, UCB.ADDON_NAME or "Ultimate Castbars")

    -- LibDualSpec only accepts the real AceDBOptions table
    local ok, err = pcall(function()
        LibDualSpec:EnhanceOptions(aceProfilesMgmt, db)
    end)
    if not ok then
        print("UCB: LibDualSpec EnhanceOptions failed: " .. tostring(err))
        return false
    end

    local originalPlugin = aceProfilesMgmt.plugins and aceProfilesMgmt.plugins[pluginKey]
    if type(originalPlugin) ~= "table" then
        print("UCB: LibDualSpec plugin not found on Ace options table.")
        return false
    end

    -- Copy plugin so changes apply only to this addon
    local pluginCopy = DeepCopySimple(originalPlugin)

    -- Remove the duplicate New field only for this addon
    pluginCopy.new = nil

    -- Optional: if your custom UI already has its own profile chooser and you also
    -- don't want LibDualSpec's replacement chooser, uncomment this too:
    -- pluginCopy.choose = nil

    customOptions.handler = customOptions.handler or aceProfilesMgmt.handler
    customOptions.plugins = customOptions.plugins or {}
    customOptions.plugins[pluginKey] = pluginCopy

    return true
end

local function BuildProfileMgmtOptions()
    -- Standalone profile management
    -- Does NOT modify AceDBOptions table
    -- Does NOT deep-copy forbidden tables
    -- Uses AceDB methods directly

    local currentProfile = (UCB.db and UCB.db.GetCurrentProfile and UCB.db:GetCurrentProfile()) or "Default"

    Profiles._profileImport = Profiles._profileImport or ""
    Profiles._profileExport = Profiles._profileExport or ""
    Profiles._exportProfileName = Profiles._exportProfileName or currentProfile
    Profiles._importProfileName = Profiles._importProfileName or currentProfile
    Profiles._newProfileName = Profiles._newProfileName or ""
    Profiles._copyFromSelection = Profiles._copyFromSelection or nil
    Profiles._deleteProfileSelection = Profiles._deleteProfileSelection or nil
    Profiles._chooseProfileSelection = Profiles._chooseProfileSelection or currentProfile

    local function GetCurrentProfile()
        return (UCB.db and UCB.db.GetCurrentProfile and UCB.db:GetCurrentProfile()) or "Default"
    end

    local function GetProfileValues(includeCurrent)
        local values = {}
        local db = UCB.db
        local current = GetCurrentProfile()

        if db and db.profiles then
            for profileName in pairs(db.profiles) do
                if includeCurrent or profileName ~= current then
                    values[profileName] = profileName
                end
            end
        end

        return values
    end

    local function ProfileExists(name)
        return UCB.db and UCB.db.profiles and UCB.db.profiles[name] ~= nil
    end

    local profilesMgmt = {
        type = "group",
        name = "Profile Management",
        order = 1,
        args = {
            currentProfile = {
                type = "description",
                name = function()
                    return "Current Profile: ".. UIOptions.ColorText(UIOptions.turquoise, tostring(GetCurrentProfile()))
                end,
                order = 1,
                fontSize = "medium",
            },

            spacer1 = {
                type = "description",
                name = " ",
                order = 2,
            },

            chooseHeader = {
                type = "header", dialogControl = "UCB_Heading",
                name = "Choose Profile",
                order = 10,
            },

            chooseProfile = {
                type = "select",
                name = "Profile",
                desc = "Select an existing profile to activate.",
                order = 11,
                width = 1.6,
                values = function()
                    return GetProfileValues(true)
                end,
                get = function()
                    local current = GetCurrentProfile()
                    if ProfileExists(Profiles._chooseProfileSelection) then
                        return Profiles._chooseProfileSelection
                    end
                    return current
                end,
                set = function(_, value)
                    Profiles._chooseProfileSelection = value
                end,
            },

            activateProfile = {
                type = "execute", dialogControl = "UCB_Button",
                name = "Activate",
                desc = "Switch to the selected profile.",
                order = 12,
                width = 1.0,
                disabled = function()
                    local selected = Profiles._chooseProfileSelection
                    local current = GetCurrentProfile()
                    return not selected or selected == "" or selected == current or not ProfileExists(selected)
                end,
                confirm = true,
                confirmText = "Switch to the selected profile?",
                func = function()
                    local db = UCB.db
                    local selected = Profiles._chooseProfileSelection

                    if not db or not db.SetProfile or not selected or not ProfileExists(selected) then
                        return
                    end

                    db:SetProfile(selected)
                    Profiles._chooseProfileSelection = GetCurrentProfile()

                    if UCB.UpdateAllCastBars then
                        UCB:UpdateAllCastBars()
                    end

                    print("UCB: Switched to profile: " .. tostring(selected))
                end,
            },

            spacer2 = {
                type = "description",
                name = " ",
                order = 19,
            },

            newHeader = {
                type = "header", dialogControl = "UCB_Heading",
                name = "Create / Copy Profile",
                order = 20,
            },

            newProfileName = {
                type = "input", dialogControl = "UCB_EditBox",
                name = "New Profile Name",
                desc = "Enter a name for the new profile.",
                order = 21,
                width = 1.6,
                get = function()
                    return Profiles._newProfileName or ""
                end,
                set = function(_, value)
                    Profiles._newProfileName = value or ""
                end,
            },

            createProfile = {
                type = "execute", dialogControl = "UCB_Button",
                name = "Create New",
                desc = "Create and switch to a new profile.",
                order = 22,
                width = 1.0,
                disabled = function()
                    local name = Profiles._newProfileName
                    return not name or name == ""
                end,
                confirm = true,
                confirmText = "Create and switch to this new profile?",
                func = function()
                    local db = UCB.db
                    local name = Profiles._newProfileName and Profiles._newProfileName:match("^%s*(.-)%s*$")

                    if not db or not db.SetProfile or not name or name == "" then
                        return
                    end

                    db:SetProfile(name)
                    Profiles._chooseProfileSelection = GetCurrentProfile()
                    Profiles._copyFromSelection = nil
                    Profiles._deleteProfileSelection = nil

                    if UCB.UpdateAllCastBars then
                        UCB:UpdateAllCastBars()
                    end

                    print("UCB: Created and switched to profile: " .. tostring(name))
                end,
            },

            copyFrom = {
                type = "select",
                name = "Copy From",
                desc = "Select another profile to copy into the current profile.",
                order = 23,
                width = 1.6,
                values = function()
                    return GetProfileValues(false)
                end,
                get = function()
                    local selected = Profiles._copyFromSelection
                    local values = GetProfileValues(false)

                    if selected and values[selected] then
                        return selected
                    end
                    return nil
                end,
                set = function(_, value)
                    Profiles._copyFromSelection = value
                end,
            },

            copyProfile = {
                type = "execute", dialogControl = "UCB_Button",
                name = "Copy To Current",
                desc = "Copy the selected profile into the current profile.",
                order = 24,
                width = 1.0,
                disabled = function()
                    local selected = Profiles._copyFromSelection
                    local current = GetCurrentProfile()

                    return not selected or selected == "" or selected == current or not ProfileExists(selected)
                end,
                confirm = true,
                confirmText = "Copy the selected profile into the current profile?",
                func = function()
                    local db = UCB.db
                    local selected = Profiles._copyFromSelection
                    local current = GetCurrentProfile()

                    if not db or not db.CopyProfile then
                        print("UCB: CopyProfile is not available on the database object.")
                        return
                    end

                    if not selected or selected == "" then
                        return
                    end

                    if selected == current then
                        print("UCB: You cannot copy from the current active profile.")
                        return
                    end

                    if not ProfileExists(selected) then
                        print("UCB: Invalid source profile.")
                        return
                    end

                    db:CopyProfile(selected, false)

                    if UCB.UpdateAllCastBars then
                        UCB:UpdateAllCastBars()
                    end

                    print("UCB: Copied settings from profile: " .. tostring(selected))
                end,
            },

            spacer3 = {
                type = "description",
                name = " ",
                order = 29,
            },

            resetHeader = {
                type = "header", dialogControl = "UCB_Heading",
                name = "Reset / Delete",
                order = 30,
            },

            resetCurrent = {
                type = "execute", dialogControl = "UCB_Button",
                name = "Reset Current Profile",
                desc = "Reset the current profile to defaults.",
                order = 31,
                width = 1.3,
                confirm = true,
                confirmText = "Reset the current profile to defaults?",
                func = function()
                    local db = UCB.db
                    if not db or not db.ResetProfile then
                        return
                    end

                    db:ResetProfile()

                    if UCB.UpdateAllCastBars then
                        UCB:UpdateAllCastBars()
                    end

                    print("UCB: Reset current profile: " .. tostring(GetCurrentProfile()))
                end,
            },

            deleteProfileSelect = {
                type = "select",
                name = "Delete Profile",
                desc = "Select a profile to delete.",
                order = 32,
                width = 1.6,
                values = function()
                    return GetProfileValues(false)
                end,
                get = function()
                    local selected = Profiles._deleteProfileSelection
                    local values = GetProfileValues(false)

                    if selected and values[selected] then
                        return selected
                    end
                    return nil
                end,
                set = function(_, value)
                    Profiles._deleteProfileSelection = value
                end,
            },

            deleteProfile = {
                type = "execute", dialogControl = "UCB_Button",
                name = "Delete",
                desc = "Delete the selected profile.",
                order = 33,
                width = 0.9,
                disabled = function()
                    local selected = Profiles._deleteProfileSelection
                    local current = GetCurrentProfile()

                    return not selected or selected == "" or selected == current or not ProfileExists(selected)
                end,
                confirm = true,
                confirmText = "Delete the selected profile? This cannot be undone.",
                func = function()
                    local db = UCB.db
                    local selected = Profiles._deleteProfileSelection
                    local current = GetCurrentProfile()

                    if not db or not db.DeleteProfile then
                        return
                    end

                    if not selected or selected == "" then
                        return
                    end

                    if selected == current then
                        print("UCB: You cannot delete the current active profile.")
                        return
                    end

                    if not ProfileExists(selected) then
                        print("UCB: Invalid profile selected for deletion.")
                        return
                    end

                    db:DeleteProfile(selected)
                    Profiles._deleteProfileSelection = nil
                    Profiles._copyFromSelection = nil
                    Profiles._chooseProfileSelection = GetCurrentProfile()

                    print("UCB: Deleted profile: " .. tostring(selected))
                end,
            },
        },
    }

    AttachLibDualSpecPluginWithoutNew(profilesMgmt, UCB.db)
    return profilesMgmt
end

function GUI:BuildProfilesOptions()
    local profilesMgmt = BuildProfileMgmtOptions()

    return {
            management = profilesMgmt,

            import = {
                type  = "group",
                name  = "Import",
                order = 2,
                args = {
                    desc = {
                        type = "description",
                        order = 1,
                        name = "Import can be used to copy settings from another profile, or to transfer your profile to another player or account."..
                        " You can either import into an existing profile (overwriting it), or create a new profile from the import string. The import string is a compressed and encoded representation of the profile data.",
                    },
                    box = {
                        type = "input", dialogControl = "UCB_EditBox",
                        name = "Import String",
                        order = 2,
                        width = "full",
                        multiline = 12,
                        get = function() return Profiles._profileImport end,
                        set = function(_, val) Profiles._profileImport = val end,
                    },
                    normalImportGrp = {
                        type = "group",
                        name = "Import into Existing Profile",
                        order = 3,
                        args = {
                            importProfile = {
                                type = "select",
                                name = "Import Into Profile",
                                order = 1,
                                values = GetProfileValues,
                                get = function() return Profiles._importProfileName end,
                                set = function(_, v) Profiles._importProfileName = v end,
                            },
                            gap1 = {
                                type = "description",
                                name = "",
                                order = 1.5,
                                width = 0.1,
                            },
                            importButton = {
                                type = "execute",dialogControl = "UCB_Button",
                                name = function()
                                    local p = Profiles._importProfileName
                                    if not p or p == "" then p = "(current)" end
                                    return "Import Into: " .. p
                                end,
                                order = 2,
                                confirm = true,
                                confirmText = "This will overwrite the selected profile with the import string. Continue?",
                                func = function()
                                    if not ImportFilteredProfile then
                                        print("UCB: ImportFilteredProfile() not found.")
                                        return
                                    end

                                    local ok, err = ImportFilteredProfile(Profiles._importProfileName, Profiles._profileImport)
                                    if not ok then
                                        print("UCB: Import failed: " .. tostring(err))
                                        return
                                    end

                                    print("UCB: Import complete.")
                                end,
                            },
                            auxGrp = {
                                type = "group",
                                name = "",
                                order = 2.5,
                                inline = true,
                                args = {
                                importCurrent = {
                                    type = "execute",dialogControl = "UCB_Button",
                                    name = "Import Into Current Profile",
                                    order = 3,
                                    confirm = true,
                                    confirmText = "This will overwrite your CURRENT active profile settings. Continue?",
                                    func = function()
                                        if not ImportFilteredProfile then
                                            print("UCB: ImportFilteredProfile() not found.")
                                            return
                                        end

                                        local current = (UCB.db and UCB.db.GetCurrentProfile and UCB.db:GetCurrentProfile()) or "Default"
                                        Profiles._importProfileName = current -- keep UI in sync

                                        local ok, err = ImportFilteredProfile(current, Profiles._profileImport)
                                        if not ok then
                                            print("UCB: Import failed: " .. tostring(err))
                                            return
                                        end

                                        print("UCB: Import complete.")
                                    end,
                                    },
                                }
                            }
                        },
                    },
                    newImportGrp = {
                        type = "group",
                        name = "Import as New Profile",
                        order = 4,
                        args = {
                            newProfileName = {
                                type = "input", dialogControl = "UCB_EditBox",
                                name = "New Profile Name",
                                order = 1,
                                width = "full",
                                get = function() return Profiles._newProfileName end,
                                set = function(_, v) Profiles._newProfileName = (v or ""):match("^%s*(.-)%s*$") end,
                            },
                            importAsNew = {
                                type = "execute",dialogControl = "UCB_Button",
                                name = "Import as New Profile",
                                order = 1.7,
                                confirm = true,
                                confirmText = "This will create a NEW profile from the import string. It will NOT overwrite an existing profile. Continue?",
                                func = function()
                                    if not ImportFilteredProfile then
                                        print("UCB: ImportFilteredProfile() not found.")
                                        return
                                    end

                                    -- Get + trim name
                                    local name = (Profiles._newProfileName or "")
                                    name = name:match("^%s*(.-)%s*$")

                                    if name == "" then
                                        print("UCB: Please enter a new profile name.")
                                        return
                                    end

                                    -- Access AceDB profile store
                                    local store = UCB.db and UCB.db.sv and UCB.db.sv.profiles
                                    if not store then
                                        print("UCB: Profile store not available.")
                                        return
                                    end

                                    -- Refuse overwrite
                                    if store[name] ~= nil then
                                        print("UCB: A profile named '" .. name .. "' already exists. Choose a different name.")
                                        return
                                    end

                                    -- Create empty table for new profile
                                    store[name] = {}

                                    -- Import into the new profile
                                    local ok, err = ImportFilteredProfile(name, Profiles._profileImport)
                                    if not ok then
                                        -- Cleanup on failure so we don't leave a broken empty profile
                                        store[name] = nil
                                        print("UCB: Import failed: " .. tostring(err))
                                        return
                                    end

                                    -- Optional QoL: set the "Import Into Profile" dropdown to this new one (no switching)
                                    Profiles._importProfileName = name

                                    print("UCB: Imported into new profile: " .. name)
                                end,
                            },

                        }
                    },
                }
            },

            export = {
                type  = "group",
                name  = "Export",
                order = 3,
                args = {
                    desc = {
                        type = "description",
                        order = 1,
                        name = "Export creates a string for your selected profile. You can use this to copy settings to another profile, or to transfer your profile to another player or account. The export string is a compressed and encoded representation of the profile data.",
                        width = "full",
                    },
                    exportProfile = {
                        type = "select",
                        name = "Export From Profile",
                        order = 2,
                        width = 1.5,
                        values = GetProfileValues,
                        get = function() return Profiles._exportProfileName end,
                        set = function(_, v) Profiles._exportProfileName = v end,
                    },
                    gap1 = {
                        type = "description",
                        name = "",
                        order = 2.5,
                        width = 0.1,
                    },
                    exportButton = {
                        type = "execute",dialogControl = "UCB_Button",
                        name = "Generate Export String for Selected Profile",
                        order = 3,
                        width = 1.5,
                        func = function()
                            if not ExportFilteredProfile then
                                print("UCB: ExportFilteredProfile() not found.")
                                return
                            end

                            local str = ExportFilteredProfile(Profiles._exportProfileName)
                            if not str or str == "" then
                                print("UCB: Export failed.")
                                return
                            end

                            Profiles._profileExport = str
                        end,
                    },
                    gap2 = {
                        type = "description",
                        name = "",
                        order = 3.5,
                        width = 0.1,
                    },
                    exportCurrent = {
                        type = "execute",dialogControl = "UCB_Button",
                        name = "Export Current Profile",
                        order = 4,
                        width = 1.5,
                        func = function()
                            if not ExportFilteredProfile then
                                print("UCB: ExportFilteredProfile() not found.")
                                return
                            end

                            local current = (UCB.db and UCB.db.GetCurrentProfile and UCB.db:GetCurrentProfile()) or "Default"
                            Profiles._exportProfileName = current -- keep UI in sync

                            local str = ExportFilteredProfile(current)
                            if not str or str == "" then
                                print("UCB: Export failed.")
                                return
                            end

                            Profiles._profileExport = str
                        end,
                    },
                    box = {
                        type = "input", dialogControl = "UCB_EditBox",
                        name = "Export String",
                        order = 5,
                        width = "full",
                        multiline = 12,
                        get = function() return Profiles._profileExport end,
                        set = function(_, val) end,
                    },
                }
            },
        }
end


