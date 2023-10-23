local utils = require("utils")
local persistence = require("persistence")

local viewportHandler = {}

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
    return utils.aabbCheckInline(
        viewport.x / viewport.scale, viewport.y / viewport.scale, viewport.width / viewport.scale, viewport.height / viewport.scale,
        room.x, room.y, room.width, room.height
    )
end

function viewportHandler.getRoomVisibleSize(room, viewport)
    return room.width * viewport.scale, room.height * viewport.scale
end

function viewportHandler.fillerVisible(filler, viewport)
    return utils.aabbCheckInline(
        viewport.x / viewport.scale, viewport.y / viewport.scale, viewport.width / viewport.scale, viewport.height / viewport.scale,
        filler.x * 8, filler.y * 8, filler.width * 8, filler.height * 8
    )
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
    x, y = x or mouseX, y or mouseY

    return math.floor((x + viewport.x) / viewport.scale), math.floor((y + viewport.y) / viewport.scale)
end

function viewportHandler.getRoomCoordinates(room, x, y)
    local mapX, mapY = viewportHandler.getMapCoordinates(x, y)

    return mapX - room.x, mapY - room.y
end

function viewportHandler.pixelToTileCoordinates(x, y)
    return math.floor(x / 8), math.floor(y / 8)
end

function viewportHandler.updateSize(width, height)
    viewport.width = width or love.graphics.getWidth()
    viewport.height = height or love.graphics.getHeight()
end

function viewportHandler.persistCamera()
    persistence.cameraPositionX = viewport.x
    persistence.cameraPositionY = viewport.y
    persistence.cameraPositionScale = viewport.scale
end

function viewportHandler.cameraFromPersistence()
    viewport.x = persistence.cameraPositionX or 0
    viewport.y = persistence.cameraPositionY or 0
    viewport.scale = persistence.cameraPositionScale or 1
end

function viewportHandler.zoomIn()
    local mouseX, mouseY = viewportHandler.getMousePosition()

    viewport.scale *= 2
    viewport.x = viewport.x * 2 + mouseX
    viewport.y = viewport.y * 2 + mouseY

    viewportHandler.persistCamera()
end

function viewportHandler.zoomOut()
    local mouseX, mouseY = viewportHandler.getMousePosition()

    viewport.scale /= 2
    viewport.x = (viewport.x - mouseX) / 2
    viewport.y = (viewport.y - mouseY) / 2

    viewportHandler.persistCamera()
end

function viewportHandler.moveToPosition(x, y, scale, centered)
    if scale then
        viewport.scale = scale
    end

    if centered then
        local windowWidth, windowHeight = love.graphics.getDimensions()

        viewport.x = x * viewport.scale - windowWidth / 2
        viewport.y = y * viewport.scale - windowHeight / 2

    else
        viewport.x = x * viewport.scale
        viewport.y = y * viewport.scale
    end

    viewportHandler.persistCamera()
end

function viewportHandler.zoomToRectangle(rectangle)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local halfWidth = math.floor(rectangle.width / 2)
    local halfHeight = math.floor(rectangle.height / 2)

    local scale = utils.getBestScale(rectangle.width, rectangle.height, windowWidth, windowHeight)
    local moveX = rectangle.x + halfWidth
    local moveY = rectangle.y + halfHeight

    viewportHandler.moveToPosition(moveX, moveY, scale, true)
end

function viewportHandler.drawRelativeTo(x, y, func, customViewport)
    local viewport = customViewport or viewportHandler.viewport

    love.graphics.push()

    love.graphics.translate(math.floor(-viewport.x), math.floor(-viewport.y))
    love.graphics.scale(viewport.scale, viewport.scale)
    love.graphics.translate(x, y)

    func()

    love.graphics.pop()
end


return viewportHandler