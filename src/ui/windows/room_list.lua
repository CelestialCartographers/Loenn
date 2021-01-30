local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local widgetUtils = require("ui.widgets.utils")
local listWidgets = require("ui.widgets.lists")
local simpleDocks = require("ui.widgets.simple_docks")

local state = require("loaded_state")

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

function roomList.roomSelectedCallback(element, item)
    print(item)
end

function roomList.getWindow()
    local search = ""

    local roomItems = getRoomItems()
    local listOptions = {
        initialSearch = search
    }
    local list = listWidgets.getFilteredList(roomList.roomSelectedCallback, roomItems, listOptions)
    local window = uiElements.window("Room List", list:with(uiUtils.fillHeight(true))):with(uiUtils.fillHeight(false))

    widgetUtils.removeWindowTitlebar(window)

    return simpleDocks.pinWidgetToEdge("left", window)
end

return roomList