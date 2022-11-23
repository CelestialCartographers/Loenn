local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local widgetUtils = require("ui.widgets.utils")
local listWidgets = require("ui.widgets.lists")
local simpleDocks = require("ui.widgets.simple_docks")
local contextMenu = require("ui.context_menu")
local roomEditor = require("ui.room_editor")
local sceneHandler = require("scene_handler")
local languageRegistry = require("language_registry")

local state = require("loaded_state")
local viewportHandler = require("viewport_handler")

local roomList = {}

local function cleanRoomName(name)
    -- Remove "lvl_" prefix

    local nameWithoutPrefix = name:match("^lvl_(.*)")

    return nameWithoutPrefix or name
end

local function roomContextEditAction(room)
    roomEditor.editExistingRoom(nil, room)
end

local function roomContextDeleteAction(room)
    local map = state.map

    sceneHandler.sendEvent("editorRoomDelete", map, room)
end

local roomContextActions = {
    edit = roomContextEditAction,
    delete = roomContextDeleteAction
}

local function handleContextListClickHandler(room)
    return function(element, action)
        if roomContextActions[action] then
            roomContextActions[action](room)
        end

        element:removeSelf()
    end
end

local function roomListItemContexthandler(room, language)
    return function()
        return uiElements.list({
            uiElements.listItem({
                text = tostring(language.ui.room_list.action.edit),
                data = "edit"
            }),
            uiElements.listItem({
                text = tostring(language.ui.room_list.action.delete),
                data = "delete"
            })
        }, handleContextListClickHandler(room))
    end
end

local function getRoomItems()
    local language = languageRegistry.getLanguage()
    local rooms = state.map and state.map.rooms or {}
    local roomItems = {}

    for _, room in ipairs(rooms) do
        local name = cleanRoomName(room.name)
        local roomItem = uiElements.listItem({
            text = name,
            data = room.name
        })

        table.insert(roomItems, contextMenu.addContextMenu(
            roomItem,
            roomListItemContexthandler(room, language))
        )
    end

    return roomItems
end

local function updateList(list, target)
    local roomItems = getRoomItems()

    listWidgets.updateItems(list, roomItems, target)
end

function roomList.roomSelectedCallback(element, item)
    local currentRoom = state.getSelectedRoom()

    if not currentRoom or cleanRoomName(currentRoom.name) ~= item then
        local newRoom = state.getRoomByName(item)

        if newRoom then
            -- TODO - Allow user to specify zoom after room selection in config
            state.selectItem(newRoom)
            viewportHandler.moveToPosition(newRoom.x + newRoom.width / 2, newRoom.y + newRoom.height / 2, 1, true)
        end
    end
end

function roomList:editorMapTargetChanged()
    return function(element, target, targetType)
        if targetType == "room" then
            local roomNameCleaned = cleanRoomName(target.name)
            local selected = listWidgets.setSelection(self, roomNameCleaned, true, true)

            if not selected then
                listWidgets.setFilterText(self, "", true)
                listWidgets.setSelection(self, roomNameCleaned, true, true)
            end
        end
    end
end

function roomList:editorMapLoaded()
    return function()
        updateList(self)
    end
end

function roomList:editorMapNew()
    return function()
        updateList(self)
    end
end

function roomList:editorRoomDeleted()
    return function(list, room)
        updateList(self, 1)
    end
end

function roomList:editorRoomAdded()
    return function(list, room)
        updateList(self, room.name)
    end
end

function roomList:editorRoomOrderChanged()
    return function()
        updateList(self)
    end
end

function roomList:uiRoomWindowRoomChanged()
    return function(list, room)
        updateList(self, room.name)
    end
end

function roomList.getWindow()
    local search = ""

    local roomItems = getRoomItems()
    local listOptions = {
        initialSearch = search,
        searchBarLocation = "below"
    }
    local column, list = listWidgets.getList(roomList.roomSelectedCallback, roomItems, listOptions)
    local window = uiElements.window("Room List", column:with(uiUtils.fillHeight(true))):with(uiUtils.fillHeight(false))

    window:with({
        editorMapTargetChanged = roomList.editorMapTargetChanged(list),
        editorMapLoaded = roomList.editorMapLoaded(list),
        editorMapNew = roomList.editorMapNew(list),
        editorRoomDeleted = roomList.editorRoomDeleted(list),
        editorRoomAdded = roomList.editorRoomAdded(list),
        uiRoomWindowRoomChanged = roomList.uiRoomWindowRoomChanged(list)
    })

    widgetUtils.removeWindowTitlebar(window)

    return simpleDocks.pinWidgetToEdge("left", window)
end

return roomList