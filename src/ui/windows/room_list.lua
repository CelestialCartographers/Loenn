local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")
local filteredList = require("ui.widgets.filtered_list")

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
    local list = filteredList.getFilteredList(roomList.roomSelectedCallback, roomItems, search)

    return uiElements.window("Room List", list):with(uiUtils.fillHeight(false))
end

return roomList