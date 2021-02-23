local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")
local loadedState = require("loaded_state")

local languageRegistry = require("language_registry")
local utils = require("utils")
local widgetUtils = require("ui.widgets.utils")
local form = require("ui.forms.form")
local roomEditor = require("ui.room_editor")

local roomWindow = {}

local roomWindows = {}
local targetRoom = nil
local windowPreviousX = 0
local windowPreviousY = 0
local roomWindowGroup = uiElements.group(roomWindows)

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

function roomWindow.createNewRoom()
    roomWindow.createRoomWindow(nil, false)
end

function roomWindow.editExistingRoom(room)
    targetRoom = room or loadedState.getSelectedRoom()

    roomWindow.createRoomWindow(room, true)
end

local function roomWindowUpdate(orig, self, dt)
    orig(self, dt)

    windowPreviousX = self.x
    windowPreviousY = self.y
end

function roomWindow.createRoomWindow(room, editing)
    -- TODO - Fake key, needs to be handled properly later
    room.checkpoint = false

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

    local buttons = {
        {
            text = tostring(language.ui.room_window.save_changes),
            formMustBeValid = true,
            callback = function(formFields)
                -- TODO - Implement
                print(require("utils").serialize(form.getFormData(formFields)))
            end
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