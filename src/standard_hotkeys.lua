local configs = require("configs")
local filesystem = require("filesystem")
local loadedState = require("loaded_state")
local fileLocations = require("file_locations")
local debugUtils = require("debug_utils")
local viewportHandler = require("viewport_handler")

local hotkeyStruct = require("structs.hotkey")
local roomStruct = require("structs.room")

-- TODO - Clean up this file at some point when we start getting a few actuall hotkeys
local rawHotkeys = {
    {configs.hotkeys.redo, (-> print("REDO")), "Redo last action"},
    {configs.hotkeys.undo, (-> print("UNDO")), "Undo last action"},
    {configs.hotkeys.open, (-> filesystem.openDialog(fileLocations.getCelesteDir(), nil, loadedState.loadFile)), "Open file"},
    {configs.hotkeys.save, (-> loadedState.filename and loadedState.saveFile(loadedState.filename)), "Save file"},
    {configs.hotkeys.saveAs, (-> loadedState.side and filesystem.saveDialog(loadedState.filename, nil, loadedState.saveFile)), "Save file as"},

    -- Room Movement
    {configs.hotkeys.roomMoveLeft, (-> loadedState.selectedRoom and roomStruct.directionalMove(loadedState.selectedRoom, "left", 1)), "Move room left"},
    {configs.hotkeys.roomMoveRight, (-> loadedState.selectedRoom and roomStruct.directionalMove(loadedState.selectedRoom, "right", 1)), "Move room right"},
    {configs.hotkeys.roomMoveUp, (-> loadedState.selectedRoom and roomStruct.directionalMove(loadedState.selectedRoom, "up", 1)), "Move room up"},
    {configs.hotkeys.roomMoveDown, (-> loadedState.selectedRoom and roomStruct.directionalMove(loadedState.selectedRoom, "down", 1)), "Move room down"},

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

