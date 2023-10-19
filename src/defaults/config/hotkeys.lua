local utils = require("utils")

local defaultHotkeys = {
    undo = "ctrl + z",
    redo = "ctrl + shift + z",
    new = "ctrl + n",
    open = "ctrl + o",
    save = "ctrl + s",
    saveAs = "ctrl + shift + s",

    -- Camera
    cameraZoomIn = "ctrl + plus",
    cameraZoomOut = "ctrl + minus",

    -- Room Movement
    roomMoveLeft = "alt + left",
    roomMoveRight = "alt + right",
    roomMoveUp = "alt + up",
    roomMoveDown = "alt + down",
    roomMoveLeftPrecise = "ctrl + alt + left",
    roomMoveRightPrecise = "ctrl + alt + right",
    roomMoveUpPrecise = "ctrl + alt + up",
    roomMoveDownPrecise = "ctrl + alt + down",

    -- Copy / Paste
    itemsCopy = "ctrl + c",
    itemsCut = "ctrl + x",
    itemsPaste = "ctrl + v",

    -- Selection
    itemsSelectAll = "ctrl + a",

    itemAreaFlipVertical = "shift + v",
    itemAreaFlipHorizontal = "shift + h",

    -- Room Resizing
    roomResizeLeftGrow = false,
    roomResizeRightGrow = false,
    roomResizeUpGrow = false,
    roomResizeDownGrow = false,
    roomResizeLeftShrink = false,
    roomResizeRightShrink = false,
    roomResizeUpShrink = false,
    roomResizeDownShrink = false,

    -- Rooms
    roomAddNew = "ctrl + t",
    roomConfigureCurrent = "ctrl + shift + t",
    roomDelete = "alt + delete",

    -- Debug
    debugReloadEntities = "f5",
    debugRedrawMap = "f6",
    debugReloadTools = "f7",
    debugReloadEverything = "ctrl + f5",
    debugReloadLuaInstance = "ctrl + shift + f5",
    debugMode = false,

    -- Window
    toggleFullscreen = "f11"
}

-- Use command instead of control on Mac
-- Don't need to replace control -> command, we only use ctrl for defaults
if utils.getOS() == "OS X" then
    for name, activator in pairs(defaultHotkeys) do
        if type(activator) == "string" then
            defaultHotkeys[name] = activator:gsub("ctrl", "cmd")
        end
    end
end

return defaultHotkeys