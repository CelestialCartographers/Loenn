local utils = require("utils")
local brushHelper = require("brushes")
local matrixLib = require("utils.matrix")
local tilesStruct = require("structs.tiles")
local loadedState = require("loaded_state")

local tiles = {}

tiles.tileLayers = {
    "tilesFg",
    "tilesBg",

    tilesFg = true,
    tilesBg = true
}

-- Keeps a copy of the tile matrix with the selections "popped off"
-- Used to create the illusion of tiles being moved actually being selected
local backingMatrices = {}

local function getRectanglePoints(room, rectangle, clampInbounds)
    local rectangleX, rectangleY = rectangle.x, rectangle.y
    local rectangleWidth, rectangleHeight = rectangle.width, rectangle.height

    if rectangle.fromClick then
        rectangleX += math.floor(rectangle.width / 2)
        rectangleY += math.floor(rectangle.height / 2)

        rectangleWidth = 1
        rectangleHeight = 1
    end

    local widthTiles = math.floor(room.width / 8)
    local heightTiles = math.floor(room.height / 8)

    local tileStartX = math.floor(rectangleX / 8) + 1
    local tileStartY = math.floor(rectangleY / 8) + 1

    local tileStopX = math.ceil((rectangleX + rectangleWidth) / 8)
    local tileStopY = math.ceil((rectangleY + rectangleHeight) / 8)

    if clampInbounds then
        tileStartX, tileStartY = math.max(tileStartX, 1), math.max(tileStartY, 1)
        tileStopX, tileStopY = math.min(tileStopX, widthTiles), math.min(tileStopY, heightTiles)
    end

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

local function deleteArea(room, layer, startX, startY, stopX, stopY)
    local width, height = getTileSize(startX, startY, stopX, stopY)
    local material = matrixLib.filled("0", width, height)

    brushHelper.placeTile(room, startX, startY, material, layer)
end

-- Use minimized string
-- This might still use too much memory, but it is a start
function tiles.getRoomTileSnapshotValue(room, layer)
    if room and room[layer] then
        return tilesStruct.matrixToTileStringMinimized(room[layer].matrix)
    end
end

function tiles.restoreRoomSnapshotValue(snapshotValue)
    if snapshotValue then
        return tilesStruct.tileStringToMatrix(snapshotValue)
    end
end

-- Used for room layer snapshots
function tiles.getRoomItems(room, layer)
    return tiles.getRoomTileSnapshotValue(room, layer)
end

function tiles.moveSelection(room, layer, selection, offsetX, offsetY)
    local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, selection)

    selection.x += offsetX
    selection.y += offsetY

    local tileXAfter, tileYAfter = getRectanglePoints(room, selection)
    local deltaX, deltaY = tileXAfter - tileStartX, tileYAfter - tileStartY
    local needsChanges = deltaX ~= 0 or deltaY ~= 0

    if needsChanges then
        local backingSlice = backingMatrices[layer]:getSlice(tileStartX, tileStartY, tileStopX, tileStopY)

        brushHelper.placeTile(room, tileStartX, tileStartY, backingSlice, layer)
        brushHelper.placeTile(room, tileStartX + deltaX, tileStartY + deltaY, selection.item, layer)
    end

    return needsChanges
end

function tiles.rotateSelection(room, layer, selection, direction)
    local matrix = selection.item
    local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, selection)
    local backingSlice = backingMatrices[layer]:getSlice(tileStartX, tileStartY, tileStopX, tileStopY)

    local rotated = matrix:rotate(direction)
    local width, height = rotated:size()

    brushHelper.placeTile(room, tileStartX, tileStartY, backingSlice, layer)
    brushHelper.placeTile(room, tileStartX, tileStartY, rotated, layer)

    selection.width, selection.height = width * 8, height * 8
end

function tiles.deleteSelection(room, layer, selection)
    local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, selection)

    deleteArea(room, layer, tileStartX, tileStartY, tileStopX, tileStopY)

    return true
end

function tiles.flipSelection(room, layer, selection, horizontal, vertical)
    local matrix = selection.item
    local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, selection)

    matrix:flip(horizontal, vertical)
    brushHelper.placeTile(room, tileStartX, tileStartY, matrix, layer)
end

function tiles.getSelectionFromRectangle(room, layer, rectangle)
    local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, rectangle, true)
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
        -- The slice we get from restoring the matrix will have whitespace trimmed off
        -- We need to add that back to get "0" instead of " "

        local rectangle = utils.rectangle(item.x * 8 - 8, item.y * 8 - 8, item.width * 8, item.height * 8)
        local matrixSlice = tilesStruct.tileStringToMatrix(item.tiles)
        local sliceWidth, sliceHeight = matrixSlice:size()
        local item = matrixLib.filled("0", item.width, item.height)

        item:setSlice(1, 1, sliceWidth, sliceHeight, matrixSlice)

        item.x = rectangle.x
        item.y = rectangle.y

        return rectangle, item
    end
end

local function updateBackingMatrix(room, layer, selections)
    local matrix = utils.deepcopy(room[layer].matrix)

    for _, selection in ipairs(selections) do
        if selection.layer == layer then
            local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, selection)

            matrix:setSlice(tileStartX, tileStartY, tileStopX, tileStopY, "0")
        end
    end

    backingMatrices[layer] = matrix
end

function tiles.selectionsChanged(selections)
    local room = loadedState.getSelectedRoom()

    if room then
        updateBackingMatrix(room, "tilesFg", selections)
        updateBackingMatrix(room, "tilesBg", selections)
    end
end

return tiles