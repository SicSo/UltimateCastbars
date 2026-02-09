local _, UCB = ...
UCB.Options = UCB.Options or {}
UCB.CASTBAR_API = UCB.CASTBAR_API or {}
UCB.UIOptions = UCB.UIOptions or {}
UCB.CFG_API = UCB.CFG_API or {}
UCB.BarUpdate_API = UCB.BarUpdate_API or {}
UCB.OtherFeatures_API = UCB.OtherFeatures_API or {}

UCB.Profiles = UCB.Profiles or {}

local Profiles = UCB.Profiles

local CASTBAR_API = UCB.CASTBAR_API
local Opt = UCB.Options
local CFG_API = UCB.CFG_API
local UIOptions = UCB.UIOptions
local BarUpdate_API = UCB.BarUpdate_API
local OtherFeatures_API = UCB.OtherFeatures_API

local LSM  = UCB.LSM



local function DeepCopySerializable(src, seen)
    local t = type(src)
    if t == "nil" or t == "boolean" or t == "number" or t == "string" then
        return src
    end
    if t ~= "table" then
        return nil -- drop function/userdata/thread
    end

    seen = seen or {}
    if seen[src] then return nil end -- avoid cycles
    seen[src] = true

    local out = {}
    for k, v in pairs(src) do
        local kt = type(k)
        if kt == "string" or kt == "number" then
            local vv = DeepCopySerializable(v, seen)
            if vv ~= nil then
                out[k] = vv
            end
        end
    end
    return out
end

-- Deep copy but only serializable primitives/tables
local function CopyPrimitive(v)
    local t = type(v)
    if t == "nil" or t == "boolean" or t == "number" or t == "string" then
        return v
    end
    return nil
end

-- Filters `src` by the "shape" of `schema` (defaults).
-- Only keys existing in schema are copied.
-- Special handling:
--  - arrays are copied index-wise up to schema length (if schema is an array)
--  - maps with "template entries" can be whitelisted using `mapTemplates`
local function FilterBySchema(src, schema, mapTemplates)
    local st = type(schema)
    if st ~= "table" then
        -- leaf: copy primitive only, otherwise fall back to schema
        local pv = CopyPrimitive(src)
        if pv ~= nil then return pv end
        return schema
    end

    if type(src) ~= "table" then
        -- schema expects table but src isn't: return schema defaults
        return schema
    end

    -- If schema table is empty, treat as "freeform container": copy everything serializable
    if next(schema) == nil then
        local t = DeepCopySerializable(src)
        return t or {}
    end


    local out = {}

    -- detect array-like schema (1..n)
    local schemaIsArray = (schema[1] ~= nil)
    if schemaIsArray then
        for i = 1, #schema do
            out[i] = FilterBySchema(src[i], schema[i], mapTemplates)
        end
        return out
    end

    -- normal keyed schema
    for k, vSchema in pairs(schema) do
        local vSrc = src[k]
        out[k] = FilterBySchema(vSrc, vSchema, mapTemplates)
    end

    -- Optional: handle "map tables" where keys aren't fixed, but each entry has a template
    -- mapTemplates is a table of paths -> template schema
    -- e.g. mapTemplates["text.tagList.dynamic"] = schema.text.tagList.dynamic.tag2 (template)
    if mapTemplates then
        for path, template in pairs(mapTemplates) do
            -- path walker that returns outTable and srcTable at that path
            local function GetAtPath(root, p)
                local t = root
                for seg in string.gmatch(p, "[^%.]+") do
                    if type(t) ~= "table" then return nil end
                    t = t[seg]
                end
                return t
            end

            local outMap = GetAtPath(out, path)
            local srcMap = GetAtPath(src, path)

            if type(outMap) == "table" and type(srcMap) == "table" then
                -- copy ALL entries from srcMap, but filter each entry by template
                -- IMPORTANT: we still keep existing schema keys too.
                for entryKey, entryVal in pairs(srcMap) do
                    if type(entryKey) == "string" then
                        outMap[entryKey] = FilterBySchema(entryVal, template, mapTemplates)
                    end
                end
            end
        end
    end

    return out
end




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

    local filtered = FilterBySchema(srcProfile, schemaProfile)

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

        local srcTagList = srcText.tagList
        if type(srcTagList) ~= "table" then return end

        dstText.tagList = dstText.tagList or {}

        for _, cat in ipairs({ "dynamic", "semiDynamic", "static", "unk" }) do
            if type(srcTagList[cat]) == "table" then
                local outMap = {}
                for tagKey, tagTable in pairs(srcTagList[cat]) do
                    if type(tagKey) == "string" and type(tagTable) == "table" then
                        outMap[tagKey] = FilterBySchema(tagTable, template)
                    end
                end
                dstText.tagList[cat] = outMap
            end
        end
    end

    ExpandTagLists("player")
    ExpandTagLists("target")
    ExpandTagLists("focus")

    local s = Serializer:Serialize(filtered)
    return EncodeExportString(s)
end


local function DeepCopyTable(src, seen)
    if type(src) ~= "table" then return src end
    seen = seen or {}
    if seen[src] then return seen[src] end
    local out = {}
    seen[src] = out
    for k, v in pairs(src) do
        if type(v) ~= "function" and type(v) ~= "userdata" and type(v) ~= "thread" then
            out[k] = DeepCopyTable(v, seen)
        end
    end
    return out
end

local function Overlay(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then return end
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
            Overlay(dst[k], v)
        else
            dst[k] = v
        end
    end
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

    local filtered = FilterBySchema(data, schemaProfile)

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

        local srcTagList = srcText.tagList
        if type(srcTagList) ~= "table" then return end

        dstText.tagList = dstText.tagList or {}

        for _, cat in ipairs({ "dynamic", "semiDynamic", "static", "unk" }) do
            if type(srcTagList[cat]) == "table" then
                local outMap = {}
                for tagKey, tagTable in pairs(srcTagList[cat]) do
                    if type(tagKey) == "string" and type(tagTable) == "table" then
                        outMap[tagKey] = FilterBySchema(tagTable, template)
                    end
                end
                dstText.tagList[cat] = outMap
            end
        end
    end

    ExpandTagLists("player")
    ExpandTagLists("target")
    ExpandTagLists("focus")

    local rebuilt = DeepCopyTable(schemaProfile)
    Overlay(rebuilt, filtered)

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
        if CASTBAR_API and CASTBAR_API.UpdateCastbar then
            CASTBAR_API:UpdateCastbar("player")
        end
        if UCB.UpdateAllCastBars then
            UCB:UpdateAllCastBars()
        end
    end

    return true
end


local function GetProfileValues()
    local vals = {}
    if not UCB.db or not UCB.db.GetProfiles then return vals end
    local list = UCB.db:GetProfiles()
    for _, name in ipairs(list) do
        vals[name] = name
    end
    return vals
end


-- Builds the Profiles page with:
--  - "Profile Management" (AceDBOptions-3.0)
--  - "Import / Export" (AceSerializer-3.0 string)
local function BuildProfilesOptions()
    -- Base profile management (choose/copy/reset/delete)
    local profilesMgmt = UCB.ADBO:GetOptionsTable(UCB.db)
    profilesMgmt.order = 1
    profilesMgmt.name  = "Profile Management"

    -- Optional LibDualSpec support (apply to management tab only)
    local LibDualSpec = LibStub and LibStub("LibDualSpec-1.0", true)
    if LibDualSpec then
        LibDualSpec:EnhanceOptions(profilesMgmt, UCB.db)
    end

    -- Storage for the transfer box
    Profiles._profileImport = Profiles._profileImport or ""
    Profiles._profileExport = Profiles._profileExport or ""
    Profiles._exportProfileName = Profiles._exportProfileName or "" -- "" means current
    Profiles._importProfileName = Profiles._importProfileName or "" -- "" means current
    local currentProfile = (UCB.db and UCB.db.GetCurrentProfile and UCB.db:GetCurrentProfile()) or "Default"
    Profiles._exportProfileName = Profiles._exportProfileName or currentProfile
    Profiles._importProfileName = Profiles._importProfileName or currentProfile
    Profiles._newProfileName = Profiles._newProfileName or ""


    return {
        type = "group",
        name = "Profiles",
        order = 100,
        childGroups = "tab",
        args = {
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
                        type = "input",
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
                                type = "execute",
                                name = "Import Into Selected Profile",
                                order = 2,
                                confirm = true,
                                confirmText = "This will overwrite your current profile settings. Continue?",
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

                                    -- Re-apply visuals/state after import
                                    if CASTBAR_API and CASTBAR_API.UpdateCastbar then
                                        CASTBAR_API:UpdateCastbar("player")
                                        UCB:UpdateAllCastBars()
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
                                    type = "execute",
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

                                        -- Re-apply visuals/state (since current profile changed)
                                        if CASTBAR_API and CASTBAR_API.UpdateCastbar then
                                            CASTBAR_API:UpdateCastbar("player")
                                            UCB:UpdateAllCastBars()
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
                                type = "input",
                                name = "New Profile Name",
                                order = 1,
                                width = "full",
                                get = function() return Profiles._newProfileName end,
                                set = function(_, v) Profiles._newProfileName = (v or ""):match("^%s*(.-)%s*$") end,
                            },
                            importAsNew = {
                                type = "execute",
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
                        type = "execute",
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
                        type = "execute",
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
                        type = "input",
                        name = "Export String",
                        order = 5,
                        width = "full",
                        multiline = 12,
                        get = function() return Profiles._profileExport end,
                        set = function(_, val) end,
                    },
                }
            },
        },
    }
end

local function EnsureProfilesOptionsRegistered()
    if UCB._profilesOptionsRegistered then return end

    -- Make the Profiles group the ROOT table for this AceConfig app
    local profilesRoot = BuildProfilesOptions()

    -- Important: this must be a "group" root table, which it already is
    UCB.AC:RegisterOptionsTable("UCB_Profiles", profilesRoot)

    UCB._profilesOptionsRegistered = true
end


function UCB:OpenProfilesInContainer(parentWidget)
    EnsureProfilesOptionsRegistered()

    if UCB.ACD and UCB.ACD.Close then
        UCB.ACD:Close("UCB")          -- close main options if open
        UCB.ACD:Close("UCB_Profiles") -- close profiles if open elsewhere
    end

    if parentWidget.SetLayout then parentWidget:SetLayout("Fill") end
    if parentWidget.SetFullWidth then parentWidget:SetFullWidth(true) end
    if parentWidget.SetFullHeight then parentWidget:SetFullHeight(true) end

    UCB.ACD:Open("UCB_Profiles", parentWidget)

    -- optional: select the "profiles" group so it shows immediately
    C_Timer.After(0, function()
        if UCB.ACD and UCB.ACD.SelectGroup then
            UCB.ACD:SelectGroup("UCB_Profiles", "management") -- or "transfer"
        end
    end)
end




function UCB:NormalizeCurrentProfileToSchema()
    local defaults = UCB:GetDefaultDB()
    local schemaProfile = defaults and defaults.profile
    if not schemaProfile then return false, "No default schema found." end

    -- Take what you currently have, but only keys in schema
    local filtered = FilterBySchema(UCB.db.profile, schemaProfile)

    -- IMPORTANT: also preserve extra tags, clamped, like you do on import/export
    local function ExpandTagListsFromCurrent(unitKey)
        local srcUnit = UCB.db.profile[unitKey]
        local dstUnit = filtered[unitKey]
        if type(srcUnit) ~= "table" or type(dstUnit) ~= "table" then return end

        local schemaUnit = schemaProfile[unitKey]
        local template   = schemaUnit and schemaUnit.text and schemaUnit.text.defaultValues
        if type(template) ~= "table" then return end

        local srcText = srcUnit.text
        local dstText = dstUnit.text
        if type(srcText) ~= "table" or type(dstText) ~= "table" then return end

        local srcTagList = srcText.tagList
        if type(srcTagList) ~= "table" then return end

        dstText.tagList = dstText.tagList or {}
        for _, cat in ipairs({ "dynamic", "semiDynamic", "static", "unk" }) do
            if type(srcTagList[cat]) == "table" then
                local outMap = {}
                for tagKey, tagTable in pairs(srcTagList[cat]) do
                    if type(tagKey) == "string" and type(tagTable) == "table" then
                        outMap[tagKey] = FilterBySchema(tagTable, template)
                    end
                end
                dstText.tagList[cat] = outMap
            end
        end
    end

    ExpandTagListsFromCurrent("player")
    ExpandTagListsFromCurrent("target")
    ExpandTagListsFromCurrent("focus")

    -- Rebuild full schema with defaults, then overlay what you have
    local rebuilt = DeepCopyTable(schemaProfile)
    Overlay(rebuilt, filtered)

    wipe(UCB.db.profile)
    for k, v in pairs(rebuilt) do
        UCB.db.profile[k] = v
    end

    return true
end


