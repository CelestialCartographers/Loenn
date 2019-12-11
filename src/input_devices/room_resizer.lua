local roomResizer = {_enabled = true, _type = "device"}

local celesteRender = require("celeste_render")
local viewportHandler = require("viewport_handler")
local loadedState = require("loaded_state")
local drawing = require("drawing")
local utils = require("utils")
local configs = require("configs")
local colors = require("colors")

local roomStruct = require("structs.room")

local dragging
local draggingStartX
local draggingStartY
local roomPosition

local actionButton = configs.editor.toolActionButton

local triangleColor = colors.resizeTriangleColor
local triangleHeight = 16
local triangleOffset = 20

-- Starting at top, going clockwise
local angles = {
    math.pi,
    math.pi * 5 / 4,
    math.pi * 3 / 2,
    math.pi * 7 / 4,
    math.pi * 2,
    math.pi * 1 / 4,
    math.pi * 1 / 2,
    math.pi * 3 / 4
}

-- Starting at top, going clockwise
local widthHeightMultipliers = {
    {0.5, 0.0},
    {1.0, 0.0},
    {1.0, 0.5},
    {1.0, 1.0},
    {0.5, 1.0},
    {0.0, 1.0},
    {0.0, 0.5},
    {0.0, 0.0}
}

local function getTrianglePoints(x, y, width, height, scale)
    local res = {}

    for i = 1, 8 do
        local widthMul, heightMul = unpack(widthHeightMultipliers[i])
        local theta = angles[i]

        local borderOffsetX = widthMul == 0 and -triangleOffset or (widthMul == 1 and triangleOffset) or 0
        local borderOffsetY = heightMul == 0 and -triangleOffset or (heightMul == 1 and triangleOffset) or 0

        local triangleOffsetX = math.cos(theta + math.pi / 2) * triangleHeight * 1 / 3
        local triangleOffsetY = math.sin(theta + math.pi / 2) * triangleHeight * 1 / 3

        res[i] = {(width * widthMul) * scale + borderOffsetX + triangleOffsetX, (height * heightMul) * scale + borderOffsetY + triangleOffsetY, theta}
    end

    return res
end

local function draggingResizeTriangle(cursorX, cursorY, roomX, roomY, width, height, viewport)
    local cursor = utils.point(cursorX, cursorY)

    for i, point in ipairs(getTrianglePoints(roomX, roomY, width, height, viewport.scale)) do
        local dx, dy, theta = unpack(point)
        local rect = utils.rectangle(utils.coverTriangle(drawing.getTrianglePoints(dx, dy, theta, triangleHeight)))

        if utils.aabbCheck(cursor, rect) then
            return i
        end
    end
end

local function fixDeltas(vertical, horizontal, deltaX, deltaY)
    if vertical == "left" then
        deltaX *= -1
    end

    if horizontal == "up" then
        deltaY *= -1
    end

    return deltaX, deltaY
end

local function getResizeDirections(side)
    local widthMul, heightMul = unpack(widthHeightMultipliers[side])

    local resizeHorizontal = widthMul == 0 and "left" or (widthMul == 1 and "right") or nil
    local resizeVertical = heightMul == 0 and "up" or (heightMul == 1 and "down") or nil

    return resizeHorizontal, resizeVertical
end

function roomResizer.draw()
    local room = loadedState.getSelectedRoom()

    if room then
        local viewport = viewportHandler.viewport

        local x, y = room.x, room.y
        local width, height = room.width, room.height

        love.graphics.push()

        love.graphics.translate(math.floor(x * viewport.scale - viewport.x), math.floor(y * viewport.scale - viewport.y))

        drawing.callKeepOriginalColor(function()
            love.graphics.setColor(triangleColor)

            for i, point in ipairs(getTrianglePoints(x, y, width, height, viewport.scale)) do
                local dx, dy, theta = unpack(point)

                drawing.triangle("fill", dx, dy, theta, triangleHeight)
            end
        end)

        love.graphics.pop()
    end
end

function roomResizer.mousepressed(x, y, button, istouch, presses)
    local room = loadedState.getSelectedRoom()

    if button == actionButton and room then
        local viewport = viewportHandler.viewport

        local roomX, roomY = room.x, room.y
        local width, height = room.width, room.height

        local cursorX, cursorY = viewportHandler.getRoomCoordindates(room, x, y)
        local tileX, tileY = viewportHandler.pixelToTileCoordinates(cursorX, cursorY)
        local side = draggingResizeTriangle(cursorX * viewport.scale, cursorY * viewport.scale, roomX, roomY, width, height, viewport)

        if side then
            dragging = side
            draggingStartX = tileX
            draggingStartY = tileY
            roomPosition = {x = roomX, y = roomY}
        end
    end

    return true
end

function roomResizer.mousereleased(x, y, button, istouch, presses)
    local consume = not not dragging

    dragging = false

    return consume
end

-- TODO - Bug with resizing on Up/Down
function roomResizer.mousemoved(x, y, dx, dy, istouch)
    local room = loadedState.getSelectedRoom()

    if dragging and room then
        local startX, startY = draggingStartX, draggingStartY
        local tileX, tileY = viewportHandler.pixelToTileCoordinates(viewportHandler.getRoomCoordindates(roomPosition, x, y))
        local deltaX, deltaY = tileX - startX, tileY - startY

        if deltaX ~= 0 or deltaY ~= 0 then
            local resizeHorizontal, resizeVertical = getResizeDirections(dragging)

            deltaX, deltaY = fixDeltas(resizeHorizontal, resizeVertical, deltaX, deltaY)

            local newWidth = room.width + deltaX * 8
            local newHeight = room.height + deltaY * 8

            if resizeHorizontal and deltaX ~= 0 and newWidth >= roomStruct.recommendedMinimumWidth then
                roomStruct.directionalResize(room, resizeHorizontal, deltaX)
            end

            if resizeVertical and deltaY ~= 0 and newHeight >= roomStruct.recommendedMinimumHeight then
                roomStruct.directionalResize(room, resizeVertical, deltaY)
            end

            draggingStartX = tileX
            draggingStartY = tileY

            -- TODO - Improve this, very expensive update
            celesteRender.invalidateRoomCache(room)
            celesteRender.forceRoomBatchRender(room, viewportHandler.viewport)
        end

        return true
    end

    return false
end

function roomResizer.mouseclicked(x, y, button, istouch, presses)
    return not not dragging
end

function roomResizer.mousedragged(startX, startY, button, dx, dy)
    return not not dragging
end

return roomResizer