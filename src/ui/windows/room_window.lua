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
local snapshotUtils = require("snapshot_utils")
local history = require("history")
local celesteRender = require("celeste_render")
local viewportHandler = require("viewport_handler")

local roomWindow = {}

local roomWindows = {}
local windowPreviousX = 0
local windowPreviousY = 0
local roomWindowGroup = uiElements.group(roomWindows)

local minimumRoomWidth = 320
local minimumRoomHeight = 184

local fieldOrder = {
    "name", "color",
    "x", "y",
    "width", "height",
    "cameraOffsetX", "cameraOffsetY",
    "windPattern", "underwater", "space",
    "disableDownTransition", "checkpoint", "dark", "whisper",
    "musicLayer1", "musicLayer2", "musicLayer3", "musicLayer4",
    "ambienceProgress", "musicProgress",
    "music",
}

local fieldTypes = {
    name = "room_name_unique"
}

function roomWindow.createNewRoom()
    roomWindow.createRoomWindow(nil, false)
end

function roomWindow.editExistingRoom(room)
    roomWindow.createRoomWindow(room, true)
end

local function roomWindowUpdate(orig, self, dt)
    orig(self, dt)

    windowPreviousX = self.x
    windowPreviousY = self.y
end

local saveRoomManualAttributes = {
    width = true,
    height = true,
    checkpoint = true
}

-- TODO - Handle checkpoint flag
-- TODO - Adding new room
local function saveRoomCallback(room, editing)
    return function(formFields)
        local newRoomData = form.getFormData(formFields)

        if editing then
            local targetRoom = loadedState.getRoomByName(room.name)
            local before = utils.deepcopy(targetRoom)

            local newWidth = math.max(minimumRoomWidth, newRoomData.width)
            local newHeight = math.max(minimumRoomHeight, newRoomData.height)

            local deltaWidth = math.ceil((newWidth - before.width) / 8)
            local deltaHeight = math.ceil((newHeight - before.height) / 8)

            for attribute, value in pairs(newRoomData) do
                if not saveRoomManualAttributes[attribute] and targetRoom[attribute] ~= value then
                    targetRoom[attribute] = value
                end
            end

            roomStruct.directionalResize(targetRoom, "right", deltaWidth)
            roomStruct.directionalResize(targetRoom, "down", deltaHeight)

            local snapshot = snapshotUtils.roomSnapshot(targetRoom, "Edited room", before, utils.deepcopy(targetRoom))

            history.addSnapshot(snapshot)
            celesteRender.invalidateRoomCache(targetRoom)
            celesteRender.forceRoomBatchRender(targetRoom, viewportHandler.viewport)

        else
            -- TODO
        end
    end
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

function roomWindow.createRoomWindow(room, editing)
    if editing then
        room = utils.deepcopy(room)

    else
        -- Decoding with empty data produces a default room
        room = roomStruct.decode({})

        -- Copy over attributes from currently selected room
        local currentRoom = loadedState.getSelectedRoom()

        if currentRoom then
            for _, attribute in ipairs(fieldOrder) do
                room[attribute] = currentRoom[attribute]
            end
        end
    end

    -- Not a actual attribute of the room
    -- Used to add a checkpoint entity
    room.checkpoint = checkCheckpointEntity(room)

    local window

    local language = languageRegistry.getLanguage()
    local titleKey = editing and "editing_room" or "creating_room"
    local windowTitle = tostring(language.ui.room_window[titleKey]):format(room.name)

    local windowX = windowPreviousX
    local windowY = windowPreviousY

    -- Don't stack windows on top of each other
    if #roomWindows > 0 then
        windowX, windowY = 0, 0
    end

    local fieldInformation = {}

    for _, field in ipairs(fieldOrder) do
        fieldInformation[field] = {
            displayName = tostring(language.room[field].name),
            tooltipText = tostring(language.room[field].description)
        }
    end

    for field, fieldType in pairs(fieldTypes) do
        fieldInformation[field].fieldType = fieldType
    end

    -- Make sure new rooms can't use name from template room
    fieldInformation.name.editedRoom = editing and room.name or false

    local buttons = {
        {
            text = tostring(language.ui.room_window.save_changes),
            formMustBeValid = true,
            callback = saveRoomCallback(room, editing)
        },
        {
            text = tostring(language.ui.room_window.close_window),
            callback = function(formFields)
                window:removeSelf()
            end
        }
    }

    local roomForm = form.getForm(buttons, room, {
        fields = fieldInformation,
        fieldOrder = fieldOrder,
        ignoreUnordered = true
    })

    window = uiElements.window(windowTitle, roomForm):with({
        x = windowX,
        y = windowY,

        updateHidden = true
    }):hook({
        update = roomWindowUpdate
    })

    table.insert(roomWindowGroup.parent.children, window)
    roomWindowGroup.parent:reflow()

    return window
end

-- Group to get access to the main group and sanely inject windows in it
function roomWindow.getWindow()
    roomEditor.roomWindow = roomWindow

    return roomWindowGroup
end

return roomWindow