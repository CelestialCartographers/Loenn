local configs = require("configs")
local loadedState = require("loaded_state")
local debugUtils = require("debug_utils")
local viewportHandler = require("viewport_handler")
local history = require("history")
local movementUtils = require("room_movement_utils")

local hotkeyStruct = require("structs.hotkey")

-- TODO - Clean up this file at some point when we start getting a few actuall hotkeys
local rawHotkeys = {
    {configs.hotkeys.redo, history.redo, "Redo last action"},
    {configs.hotkeys.undo, history.undo, "Undo last action"},
    {configs.hotkeys.open, loadedState.openMap, "Open file"},
    {configs.hotkeys.save, loadedState.saveCurrentMap, "Save file"},
    {configs.hotkeys.saveAs, loadedState.saveAsCurrentMap, "Save file as"},

    -- Room Movement
    {configs.hotkeys.roomMoveLeft, movementUtils.moveCurrentRoomOneTileLeft, "Move room left one tile"},
    {configs.hotkeys.roomMoveRight, movementUtils.moveCurrentRoomOneTileRight, "Move room right one tile"},
    {configs.hotkeys.roomMoveUp, movementUtils.moveCurrentRoomOneTileUp, "Move room up one tile"},
    {configs.hotkeys.roomMoveDown, movementUtils.moveCurrentRoomOneTileDown, "Move room down one tile"},

    {configs.hotkeys.roomMoveLeftPrecise, movementUtils.moveCurrentRoomOnePixelLeft, "Move room left one pixel"},
    {configs.hotkeys.roomMoveRightPrecise, movementUtils.moveCurrentRoomOnePixelRight, "Move room right one pixel"},
    {configs.hotkeys.roomMoveUpPrecise, movementUtils.moveCurrentRoomOnePixelUp, "Move room up one pixel"},
    {configs.hotkeys.roomMoveDownPrecise, movementUtils.moveCurrentRoomOnePixelDown, "Move room down one pixel"},

    -- Debug hotkeys
    {configs.hotkeys.debugReloadEverything, debugUtils.reloadEverything, "Reload everything™"},
    {configs.hotkeys.debugReloadEntities, debugUtils.reloadEntities, "Reload entities"},
    {configs.hotkeys.debugReloadTools, debugUtils.reloadTools, "Reload tools"},
    {configs.hotkeys.debugRedrawMap, debugUtils.redrawMap, "Redraw map"},
    {configs.hotkeys.debugMode, debugUtils.debug, "Debug mode"},

    -- Camera
    {configs.hotkeys.cameraZoomIn, viewportHandler.zoomIn, "Zoom in"},
    {configs.hotkeys.cameraZoomOut, viewportHandler.zoomOut, "Zoom out"},
}

local hotkeys = {}

for i, data <- rawHotkeys do
    local activation, callback, description = unpack(data)

    table.insert(hotkeys, hotkeyStruct.createHotkey(activation, callback))
end

return hotkeys

