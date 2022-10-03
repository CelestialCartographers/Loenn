-- Any empty values should not be written!
-- IE empty background tiles -> don't write!

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local loadedState = require("loaded_state")
local celesteRender = require("celeste_render")
local defaultMetadata = require("defaults.editor.metadata")
local languageRegistry = require("language_registry")
local utils = require("utils")
local widgetUtils = require("ui.widgets.utils")
local form = require("ui.forms.form")
local metadataEditor = require("ui.metadata_editor")
local snapshotUtils = require("snapshot_utils")
local history = require("history")
local configs = require("configs")
local enums = require("consts.celeste_enums")

local metadataWindow = {}

local activeWindows = {}

local songs = enums.songs
local cassetteSongs = enums.cassette_songs
local ambientSounds = enums.ambient_sounds

table.sort(songs)
table.sort(cassetteSongs)
table.sort(ambientSounds)

local defaultFieldGroups = {
    {
        title = "ui.metadata_window.group.general",
        fieldOrder = {
            "IntroType", "ColorGrade", "Wipe",
            "DarknessAlpha", "BloomBase", "BloomStrength",
            "Jumpthru", "CoreMode", "mode.Inventory",
            "mode.StartLevel", "mode.HeartIsEnd",
            "mode.SeekerSlowdown", "mode.TheoInBubble",
            "Dreaming", "OverrideASideMeta", "Interlude"
        }
    },
    {
        title = "ui.metadata_window.group.overworld",
        fieldOrder = {
            "Name", "SID", "Icon",
            "CompleteScreenName",
            "TitleBaseColor", "TitleAccentColor",
            "TitleTextColor"
        }
    },
    {
        title = "ui.metadata_window.group.xml",
        fieldOrder = {
            "ForegroundTiles", "BackgroundTiles", "AnimatedTiles",
            "Portraits", "Sprites"
        }
    },
    {
        title = "ui.metadata_window.group.music",
        fieldOrder = {
            "mode.audiostate.Music", "mode.audiostate.Ambience",
            "CassetteCheckpointIndex", "CassetteNoteColor", "CassetteSong",
            "mode.cassettemodifier.BeatsMax", "mode.cassettemodifier.BeatsPerTick",
            "mode.cassettemodifier.TicksPerSwap", "mode.cassettemodifier.LeadBeats",
            "mode.cassettemodifier.BeatIndexOffset", "mode.cassettemodifier.TempoMult",
            "mode.cassettemodifier.Blocks", "mode.cassettemodifier.OldBehavior",
            "mode.IgnoreLevelAudioLayerData"
        }
    }
}

local defaultFieldInformation = {
    Icon = {
        fieldType = "path",
        filePickerExtensions = {"png"},
        allowMissingPath = false,
        filenameProcessor = function(filename)
            -- Discard leading "Graphics/Atlases/Gui/" and file extension
            local filename, ext = utils.splitExtension(filename)
            local parts = utils.splitpath(filename, "/")

            return utils.convertToUnixPath(utils.joinpath(unpack(parts, 4)))
        end,
        filenameResolver = function(filename, text, prefix)
            return string.format("%s/Graphics/Atlases/Gui/%s.png", prefix, text)
        end
    },
    ForegroundTiles = {
        fieldType = "path",
        allowedExtensions = {"xml"},
        allowMissingPath = false
    },
    BackgroundTiles = {
        fieldType = "path",
        allowedExtensions = {"xml"},
        allowMissingPath = false
    },
    AnimatedTiles = {
        fieldType = "path",
        allowedExtensions = {"xml"},
        allowMissingPath = false
    },
    Portraits = {
        fieldType = "path",
        allowedExtensions = {"xml"},
        allowMissingPath = false
    },
    Sprites = {
        fieldType = "path",
        allowedExtensions = {"xml"},
        allowMissingPath = false
    },

    TitleBaseColor = {
        fieldType = "color"
    },
    TitleAccentColor = {
        fieldType = "color"
    },
    TitleTextColor = {
        fieldType = "color"
    },

    IntroType = {
        options = enums.intro_types
    },
    ColorGrade = {
        options = enums.color_grades
    },
    CoreMode = {
        options = enums.core_modes,
        editable = false
    },
    CassetteSong = {
        options = cassetteSongs
    },
    Wipe = {
        options = enums.wipe_names
    },

    DarknessAlpha = {
        fieldType = "number"
    },
    BloomBase = {
        fieldType = "number"
    },
    BloomStrength = {
        fieldType = "number"
    },

    ["mode.Inventory"] = {
        options = enums.inventories
    },
    ["mode.StartLevel"] = {
        options = {} -- Dynamically added when window is opened
    },

    ["mode.audiostate.Music"] = {
        options = songs
    },
    ["mode.audiostate.Ambience"] = {
        options = ambientSounds
    },

    ["mode.cassettemodifier.TempoMult"] = {
        fieldType = "number"
    },
    ["mode.cassettemodifier.LeadBeats"] = {
        fieldType = "integer"
    },
    ["mode.cassettemodifier.BeatsPerTick"] = {
        fieldType = "integer"
    },
    ["mode.cassettemodifier.TicksPerSwap"] = {
        fieldType = "integer"
    },
    ["mode.cassettemodifier.Blocks"] = {
        fieldType = "integer"
    },
    ["mode.cassettemodifier.BeatsMax"] = {
        fieldType = "integer"
    },
    ["mode.cassettemodifier.BeatIndexOffset"] = {
        fieldType = "integer"
    }
}

local metadataWindowGroup = uiElements.group({}):with({
    editMetadata = metadataWindow.createMetadataWindow
})

-- Value is considered unused if it is empty table or empty string
local function prepareSaveData(data)
    local dataType = type(data)

    if dataType == "string" then
        if #data > 0 then
            return data
        end

    elseif dataType == "table" then
        for k, v in pairs(data) do
            data[k] = prepareSaveData(v)
        end

        if utils.countKeys(data) > 0 then
            return data
        end

    else
        return data
    end
end

local function mergeDefaults(data, key, defaults)
    if not data[key] then
        data[key] = {}
    end

    for k, v in pairs(defaults) do
        if data[key][k] == nil then
            data[key][k] = v
        end
    end
end

local function prepareFormData(side)
    local metadata = side.meta or {}
    local data = utils.deepcopy(metadata)

    for k, v in pairs(defaultMetadata.meta) do
        if data[k] == nil then
            data[k] = v
        end
    end

    mergeDefaults(data, "mode", defaultMetadata.mode)
    mergeDefaults(data.mode, "audiostate", defaultMetadata.audioState)
    mergeDefaults(data.mode, "cassettemodifier", defaultMetadata.cassetteModifiers)

    return data
end

local function saveMetadataCallback(formFields, side)
    local formData = form.getFormData(formFields)
    local newMetadata = prepareSaveData(formData)

    side.meta = newMetadata

    celesteRender.loadCustomTilesetAutotiler(loadedState)

    -- Invalidate all tile renders
    celesteRender.invalidateRoomCache(nil, {"tilesFg", "tilesBg", "canvas", "complete"})

    -- Redraw any visible rooms
    local selectedItem, selectedItemType = loadedState.getSelectedItem()

    celesteRender.clearBatchingTasks()
    celesteRender.forceRedrawVisibleRooms(loadedState.map.rooms, loadedState, selectedItem, selectedItemType)

    -- TODO - History
end

local function getRoomOptions(side)
    local map = side.map
    local options = {
        {"", ""}
    }

    for i, room in ipairs(map.rooms) do
        local nameNoPrefix = room.name:match("^lvl_(.*)") or room.name

        table.insert(options, {
            nameNoPrefix,
            room.name
        })
    end

    return options
end

function metadataWindow.editMetadata(side)
    if not side then
        return
    end

    local language = languageRegistry.getLanguage()
    local windowTitle = tostring(language.ui.metadata_window.window_title)

    local formData = prepareFormData(side)
    local fieldInformation = utils.deepcopy(defaultFieldInformation)
    local fieldGroups = utils.deepcopy(defaultFieldGroups) -- TODO - Inject translations

    fieldInformation["mode.StartLevel"].options = getRoomOptions(side)

    local fieldNames = {}

    for _, group in ipairs(fieldGroups) do
        -- Use title name as language path
        if group.title then
            local parts = group.title:split(".")()
            local baseLanguage = utils.getPath(language, parts)

            group.title = tostring(baseLanguage.name)
        end

        for _, name in ipairs(group.fieldOrder) do
            table.insert(fieldNames, name)
        end
    end

    for _, field in ipairs(fieldNames) do
        if not fieldInformation[field] then
            fieldInformation[field] = {}
        end

        local nameParts = form.getNameParts(field)
        local baseLanguageKey = "meta"
        local fieldLanguageKey = nameParts[#nameParts]

        -- Use second to last part if name has multiple parts
        if #nameParts > 1 then
            baseLanguageKey = nameParts[#nameParts - 1]
        end

        local metadataAttributes = language.metadata[baseLanguageKey].attribute
        local metadataDescriptions = language.metadata[baseLanguageKey].description

        fieldInformation[field].displayName = tostring(metadataAttributes[fieldLanguageKey])
        fieldInformation[field].tooltipText = tostring(metadataDescriptions[fieldLanguageKey])
    end

    local buttons = {
        {
            text = tostring(language.ui.metadata_window.save_changes),
            formMustBeValid = true,
            callback = function(formFields)
                saveMetadataCallback(formFields, side)
            end
        }
    }

    local metadataForm = form.getForm(buttons, formData, {
        fields = fieldInformation,
        groups = fieldGroups,
        ignoreUnordered = true
    })

    local window = uiElements.window(windowTitle, metadataForm):with({
        x = windowX,
        y = windowY,

        updateHidden = true
    })

    table.insert(activeWindows, window)
    metadataWindowGroup.parent:addChild(window)
    widgetUtils.addWindowCloseButton(window)
    form.prepareScrollableWindow(window)

    return window
end

-- Group to get access to the main group and sanely inject windows in it
function metadataWindow.getWindow()
    metadataEditor.metadataWindow = metadataWindow

    return metadataWindowGroup
end

return metadataWindow