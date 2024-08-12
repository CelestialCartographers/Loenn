local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local loadedState = require("loaded_state")
local languageRegistry = require("language_registry")
local utils = require("utils")
local widgetUtils = require("ui.widgets.utils")
local form = require("ui.forms.form")
local roomEditor = require("ui.room_editor")
local roomStruct = require("structs.room")
local tilesStruct = require("structs.tiles")
local objectTilesStruct = require("structs.object_tiles")
local snapshotUtils = require("snapshot_utils")
local history = require("history")
local celesteRender = require("celeste_render")
local viewportHandler = require("viewport_handler")
local mapItemUtils = require("map_item_utils")
local sceneHandler = require("scene_handler")
local entityStruct = require("structs.entity")
local configs = require("configs")
local enums = require("consts.celeste_enums")
local colors = require("consts.colors")

local windowPersister = require("ui.window_position_persister")
local windowPersisterName = "room_window"

local roomWindow = {}

local songs = table.keys(enums.songs)
local ambientSounds = table.keys(enums.ambient_sounds)
local colorOptions = {}

for i = 1, #colors.roomBorderColors do
    table.insert(colorOptions, i - 1)
end

table.sort(songs)
table.sort(ambientSounds)

local defaultFieldOrder = {
    "name", "color",
    "x", "y",
    "width", "height",
    "cameraOffsetX", "cameraOffsetY",
    "windPattern", "underwater", "space",
    "disableDownTransition", "checkpoint", "dark", "whisper",
    "musicLayer1", "musicLayer2", "musicLayer3", "musicLayer4",
    "music", "musicProgress",
    "ambience", "ambienceProgress",
}

local defaultFieldInformation = {
    x = {
        fieldType = "integer"
    },
    y = {
        fieldType = "integer"
    },

    name = {
        fieldType = "room_name_unique"
    },

    width = {
        fieldType = "integer",
        minimumValue = 8,
        warningBelowValue = roomStruct.recommendedMinimumWidth,
    },
    height = {
        fieldType = "integer",
        minimumValue = 8,
        warningBelowValue = roomStruct.recommendedMinimumHeight,
    },

    color = {
        fieldType = "integer",
        options = colorOptions,
        editable = false
    },

    musicProgress = {
        fieldType = "string"
    },
    ambienceProgress = {
        fieldType = "string"
    },

    music = {
        options = songs
    },
    ambience = {
        options = ambientSounds
    },

    windPattern = {
        options = enums.wind_patterns,
        editable = false
    }
}

function roomWindow.editorRoomAdd(self, map, item)
    roomWindow.createNewRoom(item)
end

function roomWindow.editorRoomConfigure(self, map, item)
    roomWindow.editExistingRoom(item)
end

function roomWindow.createNewRoom(room)
    roomWindow.createRoomWindow(room, false)
end

function roomWindow.editExistingRoom(room)
    roomWindow.createRoomWindow(room, true)
end

local roomWindowGroup = uiElements.group({}):with({
    editorRoomAdd = roomWindow.editorRoomAdd,
    editorRoomConfigure = roomWindow.editorRoomConfigure,
})

local saveRoomManualAttributesEditing = {
    width = true,
    height = true,
    checkpoint = true
}

local saveRoomManualAttributesCreating = {
    checkpoint = true
}

local structTilesNames = {
    {"tilesFg", tilesStruct},
    {"tilesBg", tilesStruct},
    {"tilesObj", objectTilesStruct}
}

local function findFirstEntity(room, name)
    for _, entity in ipairs(room.entities) do
        if entity._name == name then
            return entity
        end
    end
end

local function handleCheckpoint(room, hasCheckpoint)
    if hasCheckpoint then
        local existingCheckpoint = findFirstEntity(room, "checkpoint")

        if not existingCheckpoint then
            local locationDefault = {
                x = math.floor(room.width / 2),
                y = math.floor(room.height / 2)
            }
            local player = findFirstEntity(room, "player") or locationDefault
            local checkpoint = entityStruct.decode({
                __name = "checkpoint",

                x = player.x or 0,
                y = player.y or 0,

                checkpointID = -1,
                allowOrigin = true,
                bg = "",

                -- Don't add dreaming, coremode and inventory
                -- They default to nil
            })

            table.insert(room.entities, checkpoint)
        end

    else
        local entities = room.entities

        for i = #entities, 1, -1 do
            local entity = entities[i]

            if entity._name == "checkpoint" then
                table.remove(entities, i)
            end
        end
    end
end

local function saveRoomCallback(formFields, room, editing, usingPixels)
    local newRoomData = form.getFormData(formFields)

    -- Restore tile to pixel values
    if not usingPixels then
        newRoomData.x = newRoomData.x * 8
        newRoomData.y = newRoomData.y * 8

        newRoomData.width = newRoomData.width * 8
        newRoomData.height = newRoomData.height * 8

        room.x = room.x * 8
        room.y = room.y * 8

        room.width = room.width * 8
        room.height = room.height * 8
    end

    newRoomData.width = math.max(8, newRoomData.width)
    newRoomData.height = math.max(8, newRoomData.height)

    if editing then
        local previousName = room.name
        local targetRoom = loadedState.getRoomByName(room.name)
        local before = utils.deepcopy(targetRoom)

        local deltaWidth = math.ceil((newRoomData.width - before.width) / 8)
        local deltaHeight = math.ceil((newRoomData.height - before.height) / 8)

        for attribute, value in pairs(newRoomData) do
            if not saveRoomManualAttributesEditing[attribute] then
                targetRoom[attribute] = value
            end
        end

        roomStruct.directionalResize(targetRoom, "right", deltaWidth)
        roomStruct.directionalResize(targetRoom, "down", deltaHeight)

        handleCheckpoint(targetRoom, newRoomData.checkpoint)

        local snapshot = snapshotUtils.roomSnapshot(targetRoom, "Edited room", before, utils.deepcopy(targetRoom))

        history.addSnapshot(snapshot)
        celesteRender.invalidateRoomCache(previousName)
        celesteRender.invalidateRoomCache(targetRoom)
        celesteRender.forceRoomBatchRender(targetRoom, loadedState)

        sceneHandler.sendEvent("editorRoomChanged", targetRoom)

        room.name = targetRoom.name

    else
        local map = loadedState.map
        local newRoom = utils.deepcopy(room)

        room.name = newRoomData.name

        local roomTilesWidth = math.ceil(newRoomData.width / 8)
        local roomTilesHeight = math.ceil(newRoomData.height / 8)

        for attribute, value in pairs(newRoomData) do
            if not saveRoomManualAttributesCreating[attribute] then
                newRoom[attribute] = value
            end
        end

        for _, handlerData in ipairs(structTilesNames) do
            local target, struct = handlerData[1], handlerData[2]

            newRoom[target] = struct.resize(struct.decode(""), roomTilesWidth, roomTilesHeight)
        end

        handleCheckpoint(newRoom, newRoomData.checkpoint)

        if map then
            mapItemUtils.addItem(map, newRoom)
            loadedState.selectItem(newRoom)
        end
    end

    mapItemUtils.sortRoomList(loadedState.map)
end

local function checkCheckpointEntity(room)
    if room then
        for _, entity in ipairs(room.entities) do
            if entity._name == "checkpoint" then
                return true, entity
            end
        end
    end

    return false
end

local function prepareRoomData(room, usingPixels)
    -- Floor position and size attributes in room data to convert to tiles
    -- Multiplied back to pixel values in the save callback
    if not usingPixels then
        room.x = math.floor(room.x / 8)
        room.y = math.floor(room.y / 8)

        room.width = math.floor(room.width / 8)
        room.height = math.floor(room.height / 8)
    end

    -- Not a actual attribute of the room
    -- Used to add a checkpoint entity
    room.checkpoint = checkCheckpointEntity(room)

    -- Music progress and ambience from vanilla maps might be saved as numbers
    if type(room.musicProgress) == "number" then
        room.musicProgress = tostring(room.musicProgress)
    end

    if type(room.ambienceProgress) == "number" then
        room.ambienceProgress = tostring(room.ambienceProgress)
    end
end

local function getWindowTitle(language, room, editing)
    local titleKey = editing and "editing_room" or "creating_room"
    local windowTitle = tostring(language.ui.room_window[titleKey]):format(room.name)

    return windowTitle
end

function roomWindow.createRoomWindow(room, editing)
    if not loadedState.map then
        return
    end

    if editing then
        room = utils.deepcopy(room or loadedState.getSelectedRoom())

    else
        -- Copy over attributes from currently selected room
        local templateRoom = room or loadedState.getSelectedRoom()
        -- Decoding with empty data produces a default room
        room = roomStruct.decode({})

        if templateRoom and utils.typeof(templateRoom) == "room" then
            for _, attribute in ipairs(defaultFieldOrder) do
                room[attribute] = templateRoom[attribute]
            end
        end
    end

    -- Not a room, nothing to edit
    -- TODO - Filler editor?
    if utils.typeof(room) ~= "room" then
        return
    end

    local usingPixels = configs.editor.itemAllowPixelPerfect

    prepareRoomData(room, usingPixels)

    local window

    local language = languageRegistry.getLanguage()
    local windowTitle = getWindowTitle(language, room, editing)

    local fieldInformation = utils.deepcopy(defaultFieldInformation)

    local roomAttributes = language.room.attribute
    local roomDescriptions = language.room.description

    for _, field in ipairs(defaultFieldOrder) do
        if not fieldInformation[field] then
            fieldInformation[field] = {}
        end

        fieldInformation[field].displayName = tostring(roomAttributes[field])
        fieldInformation[field].tooltipText = tostring(roomDescriptions[field])
    end

    -- Make sure new rooms can't use name from template room
    fieldInformation.name.editedRoom = editing and room.name or false

    -- Adjust minimums for size based on setting
    if not usingPixels then
        fieldInformation.width.minimumValue /= 8
        fieldInformation.width.warningBelowValue /= 8

        fieldInformation.height.minimumValue /= 8
        fieldInformation.height.warningBelowValue /= 8
    end

    local languageKey = editing and "save_changes_update" or "save_changes_create"
    local saveText = tostring(language.ui.room_window[languageKey])
    local buttons = {
        {
            text = saveText,
            formMustBeValid = true,
            enabled = function(formFields)
                if not editing and formFields then
                    local data = form.getFormData(formFields)

                    return data.name ~= room.name
                end

                return true
            end,
            callback = function(formFields)
                saveRoomCallback(formFields, room, editing, usingPixels)
                widgetUtils.setWindowTitle(window, getWindowTitle(language, room, editing))
                form.formDataSaved(formFields)

                if not editing then
                    widgetUtils.closeWindow(window)
                end
            end
        }
    }

    local roomForm, formFields = form.getForm(buttons, room, {
        fields = fieldInformation,
        fieldOrder = defaultFieldOrder,
        ignoreUnordered = true
    })

    window = uiElements.window(windowTitle, roomForm)

    local windowCloseCallback = windowPersister.getWindowCloseCallback(windowPersisterName)

    windowPersister.trackWindow(windowPersisterName, window)
    roomWindowGroup.parent:addChild(window)
    widgetUtils.addWindowCloseButton(window, windowCloseCallback)
    widgetUtils.preventOutOfBoundsMovement(window)
    form.prepareScrollableWindow(window)
    form.addTitleChangeHandler(window, windowTitle, formFields)

    return window
end

-- Group to get access to the main group and sanely inject windows in it
function roomWindow.getWindow()
    roomEditor.roomWindow = roomWindow

    return roomWindowGroup
end

return roomWindow