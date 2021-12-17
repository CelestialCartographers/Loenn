local configs = require("configs")
local loadedState = require("loaded_state")
local debugUtils = require("debug_utils")
local viewportHandler = require("viewport_handler")
local history = require("history")
local roomHotkeyUtils = require("room_hotkey_utils")
local windowUtils = require("window_utils")

local hotkeyStruct = require("structs.hotkey")

-- TODO - Language file
-- TODO - Clean up this file at some point when we start getting a few actuall hotkeys
-- TODO - Support hotswapping hotkey activators
-- TODO - Use language file
local rawHotkeys = {
    {configs.hotkeys.redo, history.redo, "Redo last action"},
    {configs.hotkeys.undo, history.undo, "Undo last action"},
    {configs.hotkeys.new, loadedState.newMap, "New map"},
    {configs.hotkeys.open, loadedState.openMap, "Open file"},
    {configs.hotkeys.save, loadedState.saveCurrentMap, "Save file"},
    {configs.hotkeys.saveAs, loadedState.saveAsCurrentMap, "Save file as"},

    -- Room Movement
    {configs.hotkeys.roomMoveLeft, roomHotkeyUtils.moveCurrentRoomOneTileLeft, "Move room left one tile"},
    {configs.hotkeys.roomMoveRight, roomHotkeyUtils.moveCurrentRoomOneTileRight, "Move room right one tile"},
    {configs.hotkeys.roomMoveUp, roomHotkeyUtils.moveCurrentRoomOneTileUp, "Move room up one tile"},
    {configs.hotkeys.roomMoveDown, roomHotkeyUtils.moveCurrentRoomOneTileDown, "Move room down one tile"},

    {configs.hotkeys.roomMoveLeftPrecise, roomHotkeyUtils.moveCurrentRoomOnePixelLeft, "Move room left one pixel"},
    {configs.hotkeys.roomMoveRightPrecise, roomHotkeyUtils.moveCurrentRoomOnePixelRight, "Move room right one pixel"},
    {configs.hotkeys.roomMoveUpPrecise, roomHotkeyUtils.moveCurrentRoomOnePixelUp, "Move room up one pixel"},
    {configs.hotkeys.roomMoveDownPrecise, roomHotkeyUtils.moveCurrentRoomOnePixelDown, "Move room down one pixel"},

    -- Room Resizing
    {configs.hotkeys.roomResizeLeftGrow, roomHotkeyUtils.growCurrentRoomOneTileLeft, "Grow room one tile left"},
    {configs.hotkeys.roomResizeRightGrow, roomHotkeyUtils.growCurrentRoomOneTileRight, "Grow room one tile right"},
    {configs.hotkeys.roomResizeUpGrow, roomHotkeyUtils.growCurrentRoomOneTileUp, "Grow room one tile up"},
    {configs.hotkeys.roomResizeDownGrow, roomHotkeyUtils.growCurrentRoomOneTileDown, "Grow room one tile down"},

    {configs.hotkeys.roomResizeLeftShrink, roomHotkeyUtils.shrinkCurrentRoomOneTileLeft, "Shrink room one tile left"},
    {configs.hotkeys.roomResizeRightShrink, roomHotkeyUtils.shrinkCurrentRoomOneTileRight, "Shrink room one tile right"},
    {configs.hotkeys.roomResizeUpShrink, roomHotkeyUtils.shrinkCurrentRoomOneTileUp, "Shrink room one tile up"},
    {configs.hotkeys.roomResizeDownShrink, roomHotkeyUtils.shrinkCurrentRoomOneTileDown, "Shrink room one tile down"},

    -- Room
    {configs.hotkeys.roomDelete, roomHotkeyUtils.deleteSelectedRoom, "Delete selected room"},
    {configs.hotkeys.roomAddNew, roomHotkeyUtils.addRoom, "Add new room"},
    {configs.hotkeys.roomConfigureCurrent, roomHotkeyUtils.configureSelectedRoom, "Edit selected room"},

    -- Debug hotkeys
    {configs.hotkeys.debugReloadEverything, debugUtils.reloadEverything, "Reload everything™"},
    {configs.hotkeys.debugReloadLuaInstance, debugUtils.restartLuaInstance, "Reload Lua instance"},
    {configs.hotkeys.debugReloadEntities, debugUtils.reloadEntities, "Reload entities"},
    {configs.hotkeys.debugReloadTools, debugUtils.reloadTools, "Reload tools"},
    {configs.hotkeys.debugRedrawMap, debugUtils.redrawMap, "Redraw map"},
    {configs.hotkeys.debugMode, debugUtils.debug, "Debug mode"},

    -- Camera
    {configs.hotkeys.cameraZoomIn, viewportHandler.zoomIn, "Zoom in"},
    {configs.hotkeys.cameraZoomOut, viewportHandler.zoomOut, "Zoom out"},

    -- Window
    {configs.hotkeys.toggleFullscreen, windowUtils.toggleFullscreen, "Toggle fullscreen"}
}

local hotkeys = {}

for _, data in ipairs(rawHotkeys) do
    local activation, callback, description = data[1], data[2], data[3]
    local hotkey = hotkeyStruct.createHotkey(activation, callback)

    table.insert(hotkeys, hotkey)
end

return hotkeys

