local configs = require("configs")
local viewportHandler = require("viewport_handler")
local mapItemUtils = require("map_item_utils")
local loadedState = require("loaded_state")
local utils = require("utils")

local viewportDevice = {}

function viewportDevice.mousedragmoved(x, y, dx, dy, button, istouch)
    local movementButton = configs.editor.canvasMoveButton
    local viewport = viewportHandler.viewport

    if button == movementButton then
        viewport.x -= dx
        viewport.y -= dy

        viewportHandler.persistCamera()

        return true
    end
end

function viewportDevice.mousemoved(x, y, dx, dy, istouch)
    local viewport = viewportHandler.viewport

    if istouch then
        viewport.x -= dx
        viewport.y -= dy

        viewportHandler.persistCamera()

        return true
    end
end

function viewportDevice.zoomToExtents(map)
    map = loadedState.map or map

    if not map then
        return
    end

    if #map.rooms == 0 then
        return
    end

    local tlx, tly, brx, bry = mapItemUtils.getMapBounds(map)
    local rectangle = utils.rectangle(tlx, tly, brx - tlx, bry - tly)

    viewportHandler.zoomToRectangle(rectangle)
    viewportHandler.persistCamera()
end

function viewportDevice.mouseclicked(x, y, button, istouch, presses)
    local zoomToExtentsButton = configs.editor.canvasZoomExtentsButton

    if button == zoomToExtentsButton and presses % 2 == 0 then
        viewportDevice.zoomToExtents()
    end
end

function viewportDevice.resize(width, height)
    viewportHandler.updateSize(width, height)
end

function viewportDevice.wheelmoved(dx, dy)
    if dy > 0 then
        viewportHandler.zoomIn()

        return true

    elseif dy < 0 then
        viewportHandler.zoomOut()

        return true
    end
end

function viewportDevice.visible(visible)
    local viewport = viewportHandler.viewport

    viewport.visible = visible
end

return viewportDevice
