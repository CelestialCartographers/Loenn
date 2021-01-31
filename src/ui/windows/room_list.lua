local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local widgetUtils = require("ui.widgets.utils")
local listWidgets = require("ui.widgets.lists")
local simpleDocks = require("ui.widgets.simple_docks")

local state = require("loaded_state")
local viewportHandler = require("viewport_handler")

local roomList = {}

local function cleanRoomName(name)
    -- Remove "lvl_" prefix

    local nameWithoutPrefix = name:match("lvl_(.*)")

    return nameWithoutPrefix or name
end

local function getRoomItems()
    local rooms = state.map and state.map.rooms or {}
    local roomItems = {}

    for _, room in ipairs(rooms) do
        local name = cleanRoomName(room.name)

        table.insert(roomItems, uiElements.listItem({
            text = name,
            data = name
        }))
    end

    return roomItems
end

local function getRoomByName(name)
    local rooms = state.map and state.map.rooms or {}
    local nameWithLvl = "lvl_" .. name

    for _,room in ipairs(rooms) do
        if room.name == name or room.name == nameWithLvl then
            return room
        end
    end
end

function roomList.roomSelectedCallback(element, item)
    local currentRoom = state.getSelectedRoom()

    if not currentRoom or cleanRoomName(currentRoom.name) ~= item then
        local newRoom = getRoomByName(item)

        if newRoom then
            -- TODO - Allow user to specify zoom after room selection in config
            state.selectItem(newRoom)
            viewportHandler.moveToPosition(newRoom.x + newRoom.width / 2, newRoom.y + newRoom.height / 2, 1, true)
        end
    end
end

function roomList.editorMapTargetChanged(list)
    return function(element, target, targetType)
        if targetType == "room" then
            local roomNameCleaned = cleanRoomName(target.name)
            local selected = listWidgets.setSelection(list, roomNameCleaned, true, true)

            if not selected then
                listWidgets.setFilterText(list, "", true)
                listWidgets.setSelection(list, roomNameCleaned, true, true)
            end
        end
    end
end

function roomList.getWindow()
    local search = ""

    local roomItems = getRoomItems()
    local listOptions = {
        initialSearch = search
    }
    local column, list = listWidgets.getFilteredList(roomList.roomSelectedCallback, roomItems, listOptions)
    local window = uiElements.window("Room List", column:with(uiUtils.fillHeight(true))):with(uiUtils.fillHeight(false))

    window:with({
        editorMapTargetChanged = roomList.editorMapTargetChanged(list)
    })

    widgetUtils.removeWindowTitlebar(window)

    return simpleDocks.pinWidgetToEdge("left", window)
end

return roomList