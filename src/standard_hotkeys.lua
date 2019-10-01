local configs = require("configs")
local filesystem = require("filesystem")
local loadedState = require("loaded_state")
local fileLocations = require("file_locations")
local debugUtils = require("debug_utils")
local viewportHandler = require("viewport_handler")

local hotkeyStruct = require("structs.hotkey")

-- TODO - Clean up this file at some point when we start getting a few actuall hotkeys
local rawHotkeys = {
    {configs.hotkeys.redo, (-> print("REDO")), "Redo last action"},
    {configs.hotkeys.undo, (-> print("UNDO")), "Undo last action"},
    {configs.hotkeys.open, (-> filesystem.openDialog(fileLocations.getCelesteDir(), nil, loadedState.loadFile)), "Open file"},
    {configs.hotkeys.save, (-> loadedState.filename and loadedState.saveFile(loadedState.filename)), "Save file"},
    {configs.hotkeys.saveAs, (-> loadedState.side and filesystem.saveDialog(loadedState.filename, nil, loadedState.saveFile)), "Save file as"},

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

