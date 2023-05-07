local utils = require("utils")
local brushHelper = require("brushes")
local matrixLib = require("utils.matrix")
local tilesStruct = require("structs.tiles")

local tiles = {}

local function getRectanglePoints(room, rectangle)
    local widthTiles = math.floor(room.width / 8)
    local heightTiles = math.floor(room.height / 8)

    local tileStartX = math.max(math.floor(rectangle.x / 8) + 1, 1)
    local tileStartY = math.max(math.floor(rectangle.y / 8) + 1, 1)

    local tileStopX = math.min(math.ceil((rectangle.x + rectangle.width) / 8), widthTiles)
    local tileStopY = math.min(math.ceil((rectangle.y + rectangle.height) / 8), heightTiles)

    return tileStartX, tileStartY, tileStopX, tileStopY
end

local function getTileSize(startX, startY, stopX, stopY)
    return stopX - startX + 1, stopY - startY + 1
end

local function getSelectionRectangle(tileStartX, tileStartY, tileStopX, tileStopY)
    local selectionWidth = (tileStopX - tileStartX + 1) * 8
    local selectionHeight = (tileStopY - tileStartY + 1) * 8

    if selectionWidth > 0 and selectionHeight > 0 then
        return utils.rectangle(tileStartX * 8 - 8, tileStartY * 8 - 8, selectionWidth, selectionHeight)
    end
end

local function clearArea(room, layer, startX, startY, stopX, stopY)
    local width, height = getTileSize(startX, startY, stopX, stopY)
    local material = matrixLib.filled("0", width, height)

    brushHelper.placeTile(room, startX, startY, material, layer)
end

-- TODO - Improve, this is a temporary history workaround
function tiles.getRoomItems(room, layer)
    return room[layer]
end

function tiles.moveSelection(room, layer, selection, offsetX, offsetY)
    local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, selection)

    selection.x += offsetX
    selection.y += offsetY

    local tileXAfter, tileYAfter = getRectanglePoints(room, selection)
    local deltaX, deltaY = tileXAfter - tileStartX, tileYAfter - tileStartY
    local needsChanges = deltaX ~= 0 or deltaY ~= 0

    if needsChanges then
        clearArea(room, layer, tileStartX, tileStartY, tileStopX, tileStopY)
        brushHelper.placeTile(room, tileStartX + deltaX, tileStartY + deltaY, selection.item, layer)
    end

    return needsChanges
end

function tiles.rotateSelection(room, layer, selection, direction)
    -- TODO - Implement
end

function tiles.deleteSelection(room, layer, selection)
    local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, selection)

    clearArea(room, layer, tileStartX, tileStartY, tileStopX, tileStopY)

    return true
end

function tiles.flipSelection(room, layer, selection, horizontal, vertical)
    -- TODO - Implement
end

function tiles.getSelectionFromRectangle(room, layer, rectangle)
    local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, rectangle)
    local selection = getSelectionRectangle(tileStartX, tileStartY, tileStopX, tileStopY)
    local matrix = room[layer].matrix

    if selection then
        selection.item = matrix:getSlice(tileStartX, tileStartY, tileStopX, tileStopY, "0")
        selection.layer = layer
        selection.node = 0
    end

    return selection
end

function tiles.clipboardPrepareCopy(target)
    local item = target.item

    if utils.typeof(item) == "matrix" then
        target.item = {}
        target.item.tiles = tilesStruct.matrixToTileStringMinimized(item)
        target.item.x = math.floor(target.x / 8 + 1)
        target.item.y = math.floor(target.y / 8 + 1)
        target.item.width, target.item.height = item:size()
    end
end

function tiles.rebuildSelection(room, item)
    if item.tiles then
        local rectangle = utils.rectangle(item.x * 8 - 8, item.y * 8 - 8, item.width * 8, item.height * 8)
        local item = tilesStruct.tileStringToMatrix(item.tiles)

        item.x = rectangle.x
        item.y = rectangle.y

        return rectangle, item
    end
end

return tiles