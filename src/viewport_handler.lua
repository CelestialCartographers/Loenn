local inputDevice = require("input_device")
local utils = require("utils")

local viewportHandler = {}

local movementButton = 2

local viewport = {
    x = 0,
    y = 0,

    scale = 1,

    width = love.graphics.getWidth(),
    height = love.graphics.getHeight(),

    visible = true
}

viewportHandler.viewport = viewport

function viewportHandler.roomVisible(room, viewport)
    local actuallX = viewport.x / viewport.scale
    local actuallY = viewport.y / viewport.scale

    local actuallWidth = viewport.width / viewport.scale
    local actuallHeight = viewport.height / viewport.scale

    local cameraRect = {x = actuallX, y = actuallY, width = actuallWidth, height = actuallHeight}
    local roomRect = {x = room.x, y = room.y, width = room.width, height = room.height}

    return utils.aabbCheck(cameraRect, roomRect)
end

function viewportHandler.getMousePosition()
    if love.mouse.isCursorSupported() then
        return love.mouse.getX(), love.mouse.getY()

    else
        return viewport.width / 2, viewport.height / 2
    end
end

function viewportHandler.getMapCoordinates()
    local mouseX, mouseY = viewportHandler.getMousePosition()

    return math.floor((mouseX + viewport.x) / viewport.scale), math.floor((mouseY + viewport.y) / viewport.scale)
end

function viewportHandler.getRoomCoorindates(room)
    local mapX, mapY = viewportHandler.getMapCoordinates()

    return mapX - room.x, mapY - room.y
end

function viewportHandler.zoomIn()
    local mouseX, mouseY = viewportHandler.getMousePosition()

    viewport.scale *= 2
    viewport.x = viewport.x * 2 + mouseX
    viewport.y = viewport.y * 2 + mouseY
end

function viewportHandler.zoomOut()
    local mouseX, mouseY = viewportHandler.getMousePosition()

    viewport.scale /= 2
    viewport.x = (viewport.x - mouseX) / 2
    viewport.y = (viewport.y - mouseY) / 2
end

local viewportDevice = {}

function viewportDevice.keypressed(key, scancode, isrepeat)
    if key == "+" and not isrepeat then
        viewportHandler.zoomIn()

    elseif key == "-" and not isrepeat then
        viewportHandler.zoomOut()

    elseif key == "w" or key == "up" then
        viewport.y -= 8

    elseif key == "a" or key == "left" then
        viewport.x -= 8

    elseif key == "s" or key == "down" then
        viewport.y += 8

    elseif key == "d" or key == "right" then
        viewport.x += 8
    end
end

function viewportDevice.mousedragmoved(dx, dy, button, istouch)
    if button == movementButton then
        viewport.x -= dx
        viewport.y -= dy
    end
end

function viewportDevice.mousemoved(x, y, dx, dy, istouch)
    if istouch then
        viewport.x -= dx
        viewport.y -= dy
    end
end

function viewportDevice.resize(width, height)
    viewport.width = width
    viewport.height = height
end

function viewportDevice.wheelmoved(dx, dy)
    if dy > 0 then
        viewportHandler.zoomIn()

    elseif dy < 0 then
        viewportHandler.zoomOut()
    end
end

function viewportDevice.visible(visible)
    viewport.visible = visible
end

function viewportHandler.enable()
    viewportDevice._enabled = true
end

function viewportHandler.disable()
    viewportDevice._enabled = false
end


inputDevice.newInputDevice(viewportDevice)

return viewportHandler