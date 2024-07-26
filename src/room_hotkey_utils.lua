local roomHotkeyUtils = {}

-- Exists to make hotkeys somewhat sane

local loadedState = require("loaded_state")
local mapItemUtils = require("map_item_utils")
local sceneHandler = require("scene_handler")
local configs = require("configs")

local directions = {
    Left = "left",
    Right = "right",
    Up = "up",
    Down = "down"
}

for name, direction in pairs(directions) do
    roomHotkeyUtils["moveCurrentRoomOneTile" .. name] = function()
        local item = loadedState.getSelectedItem()

        return mapItemUtils.directionalMove(item, direction, 1)
    end

    roomHotkeyUtils["moveCurrentRoomOnePixel" .. name] = function()
        if configs.editor.itemAllowPixelPerfect then
            local item = loadedState.getSelectedItem()

            return mapItemUtils.directionalMove(item, direction, 1, 1)
        end
    end

    roomHotkeyUtils["growCurrentRoomOneTile" .. name] = function()
        local item = loadedState.getSelectedItem()

        return mapItemUtils.directionalResize(item, direction, 1)
    end

    roomHotkeyUtils["shrinkCurrentRoomOneTile" .. name] = function()
        local item = loadedState.getSelectedItem()

        return mapItemUtils.directionalResize(item, direction, -1)
    end
end

function roomHotkeyUtils.deleteSelectedRoom()
    local map = loadedState.map
    local item = loadedState.getSelectedItem()

    if map and item then
        sceneHandler.sendEvent("editorRoomDelete", map, item)
    end
end

function roomHotkeyUtils.addRoom()
    local map = loadedState.map
    local item = loadedState.getSelectedItem()

    if map then
        sceneHandler.sendEvent("editorRoomAdd", map, item)
    end
end

function roomHotkeyUtils.configureSelectedRoom()
    local map = loadedState.map
    local item = loadedState.getSelectedItem()

    if map and item then
        sceneHandler.sendEvent("editorRoomConfigure", map, item)
    end
end

return roomHotkeyUtils