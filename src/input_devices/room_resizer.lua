local roomResizer = {_enabled = true, _type = "device"}

local celesteRender = require("celeste_render")
local viewportHandler = require("viewport_handler")
local loadedState = require("loaded_state")
local drawing = require("drawing")
local utils = require("utils")
local configs = require("configs")
local colors = require("colors")

local roomStruct = require("structs.room")
local fillerStruct = require("structs.filler")

local dragging
local draggingStartX
local draggingStartY
local itemPosition

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
        local dx, dy, theta = point[1], point[2], point[3]
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

local function getItemStruct(itemType)
    if itemType == "room" then
        return roomStruct

    elseif itemType == "filler" then
        return fillerStruct
    end
end

function roomResizer.draw()
    local item, itemType = loadedState.getSelectedItem()

    if itemType == "room" or itemType == "filler" then
        local viewport = viewportHandler.viewport
        local itemStruct = getItemStruct(itemType)

        local x, y = itemStruct.getPosition(item)
        local width, height = itemStruct.getSize(item)

        love.graphics.push()

        love.graphics.translate(math.floor(x * viewport.scale - viewport.x), math.floor(y * viewport.scale - viewport.y))

        drawing.callKeepOriginalColor(function()
            love.graphics.setColor(triangleColor)

            for i, point in ipairs(getTrianglePoints(x, y, width, height, viewport.scale)) do
                local dx, dy, theta = point[1], point[2], point[3]

                drawing.triangle("fill", dx, dy, theta, triangleHeight)
            end
        end)

        love.graphics.pop()
    end
end

function roomResizer.mousepressed(x, y, button, istouch, presses)
    local item, itemType = loadedState.getSelectedItem()
    local actionButton = configs.editor.toolActionButton

    if button == actionButton and (itemType == "room" or itemType == "filler") then
        local viewport = viewportHandler.viewport
        local itemStruct = getItemStruct(itemType)

        local itemX, itemY = itemStruct.getPosition(item)
        local width, height = itemStruct.getSize(item)

        local newItemPosition = {x = itemX, y = itemY}

        local cursorX, cursorY = viewportHandler.getRoomCoordindates(newItemPosition, x, y)
        local tileX, tileY = viewportHandler.pixelToTileCoordinates(cursorX, cursorY)
        local side = draggingResizeTriangle(cursorX * viewport.scale, cursorY * viewport.scale, itemX, itemY, width, height, viewport)

        if side then
            dragging = side
            draggingStartX = tileX
            draggingStartY = tileY
            itemPosition = newItemPosition

            return true
        end
    end
end

function roomResizer.mousereleased(x, y, button, istouch, presses)
    local consume = not not dragging

    dragging = false

    return consume
end

-- TODO - Bug with resizing on Up/Down
function roomResizer.mousemoved(x, y, dx, dy, istouch)
    local item, itemType = loadedState.getSelectedItem()

    if dragging and (itemType == "room" or itemType == "filler") then
        local itemStruct = getItemStruct(itemType)

        local startX, startY = draggingStartX, draggingStartY
        local tileX, tileY = viewportHandler.pixelToTileCoordinates(viewportHandler.getRoomCoordindates(itemPosition, x, y))
        local deltaX, deltaY = tileX - startX, tileY - startY

        local width, height = itemStruct.getSize(item)

        if deltaX ~= 0 or deltaY ~= 0 then
            local resizeHorizontal, resizeVertical = getResizeDirections(dragging)

            deltaX, deltaY = fixDeltas(resizeHorizontal, resizeVertical, deltaX, deltaY)

            local newWidth = width + deltaX * 8
            local newHeight = height + deltaY * 8

            if resizeHorizontal and deltaX ~= 0 and newWidth >= itemStruct.recommendedMinimumWidth then
                itemStruct.directionalResize(item, resizeHorizontal, deltaX)
            end

            if resizeVertical and deltaY ~= 0 and newHeight >= itemStruct.recommendedMinimumHeight then
                itemStruct.directionalResize(item, resizeVertical, deltaY)
            end

            draggingStartX = tileX
            draggingStartY = tileY

            if itemType == "room" then
                -- TODO - Improve this, very expensive update
                celesteRender.invalidateRoomCache(item)
                celesteRender.forceRoomBatchRender(item, viewportHandler.viewport)
            end
        end

        return true
    end
end

function roomResizer.mouseclicked(x, y, button, istouch, presses)
    return not not dragging
end

function roomResizer.mousedragged(startX, startY, button, dx, dy)
    return not not dragging
end

function roomResizer.mousedragmoved(dx, dy, button, istouch)
    return not not dragging
end

return roomResizer