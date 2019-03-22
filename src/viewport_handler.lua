local inputDevice = require("input_device")
local utils = require("utils")

local viewportHandler = {}

-- TODO - Put in config/constants files
local movementButton = 2

local viewport = {
    x = 0,
    y = 0,

    scale = 1,

    width = love.graphics.getWidth(),
    height = love.graphics.getHeight(),

    visible = true
}

local viewportDevice = {}

viewportHandler.viewport = viewport
viewportHandler.device = viewportDevice

function viewportHandler.roomVisible(room, viewport)
    local actuallX = viewport.x / viewport.scale
    local actuallY = viewport.y / viewport.scale

    local actuallWidth = viewport.width / viewport.scale
    local actuallHeight = viewport.height / viewport.scale

    local cameraRect = {x = actuallX, y = actuallY, width = actuallWidth, height = actuallHeight}
    local roomRect = {x = room.x, y = room.y, width = room.width, height = room.height}

    return utils.aabbCheck(cameraRect, roomRect)
end

function viewportHandler.fillerVisible(filler, viewport)
    local actuallX = viewport.x / viewport.scale
    local actuallY = viewport.y / viewport.scale

    local actuallWidth = viewport.width / viewport.scale
    local actuallHeight = viewport.height / viewport.scale

    local cameraRect = {x = actuallX, y = actuallY, width = actuallWidth, height = actuallHeight}
    local fillerRect = {x = filler.x * 8, y = filler.y * 8, width = filler.width * 8, height = filler.height * 8}

    return utils.aabbCheck(cameraRect, fillerRect)
end

function viewportHandler.getMousePosition()
    if love.mouse.isCursorSupported() then
        return love.mouse.getX(), love.mouse.getY()

    else
        return viewport.width / 2, viewport.height / 2
    end
end

function viewportHandler.getMapCoordinates(x, y)
    local mouseX, mouseY = viewportHandler.getMousePosition()
    local x, y = x or mouseX, y or mouseY

    return math.floor((x + viewport.x) / viewport.scale), math.floor((y + viewport.y) / viewport.scale)
end

function viewportHandler.getRoomCoordindates(room, x, y)
    local mapX, mapY = viewportHandler.getMapCoordinates(x, y)

    return mapX - room.x, mapY - room.y
end

function viewportHandler.pixelToTileCoordinates(x, y)
    return math.floor(x / 8), math.floor(y / 8)
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

function viewportHandler.enable()
    viewportHandler.device._enabled = true
end

function viewportHandler.disable()
    viewportHandler.device._enabled = false
end



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
    
    return true
end

function viewportDevice.mousedragmoved(dx, dy, button, istouch)
    if button == movementButton then
        viewport.x -= dx
        viewport.y -= dy

        return true
    end
end

function viewportDevice.mousemoved(x, y, dx, dy, istouch)
    if istouch then
        viewport.x -= dx
        viewport.y -= dy

        return true
    end
end

function viewportDevice.resize(width, height)
    viewport.width = width
    viewport.height = height
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
    viewport.visible = visible
end

return viewportHandler