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

local function restoreMinimizedMatrix(tiles, width, height)
    local restoredMatrix = tilesStruct.tileStringToMatrix(tiles)
    local restoredWidth, restoredHeight = restoredMatrix:size()
    local matrix = matrixLib.filled("0", width, height)

    matrix:setSlice(1, 1, restoredWidth, restoredHeight, restoredMatrix)

    return matrix
end

-- Use minimized string
-- This might still use too much memory, but it is a start
function tiles.getRoomTileSnapshotValue(room, layer)
    if room and room[layer] then
        local matrix = room[layer].matrix
        local tiles = tilesStruct.matrixToTileStringMinimized(matrix)
        local width, height = matrix:size()

        return {
            tiles = tiles,
            width = width,
            height = height
        }
    end
end

-- The slice we get from restoring the matrix will have whitespace trimmed off
-- We need to add that back to get "0" instead of " "
function tiles.restoreRoomSnapshotValue(snapshotValue)
    if snapshotValue then
        local tiles = snapshotValue.tiles
        local width, height = snapshotValue.width, snapshotValue.height

        return restoreMinimizedMatrix(tiles, width, height)
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
        brushHelper.placeTile(room, tileStartX + deltaX, tileStartY + deltaY, selection.item, layer)
    end

    return needsChanges
end

function tiles.rotateSelection(room, layer, selection, direction)
    local matrix = selection.item
    local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, selection)

    local rotated = matrix:rotate(direction)
    local width, height = rotated:size()

    brushHelper.placeTile(room, tileStartX, tileStartY, rotated, layer)

    selection.width, selection.height = width * 8, height * 8

    return true
end

function tiles.deleteSelection(room, layer, selection)
    local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, selection)

    deleteArea(room, layer, tileStartX, tileStartY, tileStopX, tileStopY)

    return true
end

function tiles.areaFlipSelection(room, layer, selection, horizontal, vertical, area)
    local matrix = selection.item
    local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, selection)
    local tileWidth = tileStopX - tileStartX + 1
    local tileHeight = tileStopY - tileStartY + 1
    local areaStartX, areaStartY, areaStopX, areaStopY = getRectanglePoints(room, area)
    local areaWidth = areaStopX - areaStartX + 1
    local areaHeight = areaStopY - areaStartY + 1

    if horizontal then
        tileStartX = 2 * areaStartX + areaWidth - tileStartX - tileWidth
        selection.x = 2 * area.x + area.width - selection.width - selection.x
    end

    if vertical then
        tileStartY = 2 * areaStartY + areaHeight - tileStartY - tileHeight
        selection.y = 2 * area.y + area.height - selection.height - selection.y
    end

    matrix:flip(horizontal, vertical)
    brushHelper.placeTile(room, tileStartX, tileStartY, matrix, layer)

    return true
end

function tiles.flipSelection(room, layer, selection, horizontal, vertical)
    local matrix = selection.item
    local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, selection)

    matrix:flip(horizontal, vertical)
    brushHelper.placeTile(room, tileStartX, tileStartY, matrix, layer)

    return true
end

function tiles.getSelectionFromRectangle(room, layer, rectangle)
    local tileStartX, tileStartY, tileStopX, tileStopY = getRectanglePoints(room, rectangle, true)
    local selection = getSelectionRectangle(tileStartX, tileStartY, tileStopX, tileStopY)
    local matrix = room[layer].matrix

    if selection then
        selection.item = matrix:getSlice(tileStartX, tileStartY, tileStopX, tileStopY, "0")
        selection.layer = layer
        selection.node = 0

        selection.item.x = selection.x
        selection.item.y = selection.y
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
        local item = restoreMinimizedMatrix(item.tiles, item.width, item.height)

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
        for _, layer in ipairs(tiles.tileLayers) do
            updateBackingMatrix(room, layer, selections)
        end
    end
end

local function restoreBackingAreas(room, layer, targets, matrices)
    local backingMatrix = matrices and matrices[layer] or backingMatrices[layer]

    for _, target in ipairs(targets) do
        if target.layer == layer then
            local startX, startY, stopX, stopY = getRectanglePoints(room, target)
            local slice = backingMatrix:getSlice(startX, startY, stopX, stopY)

            brushHelper.placeTile(room, startX, startY, slice, layer)
        end
    end
end

-- Prepare for tile based changes in needed
function tiles.beforeSelectionChanges(room, targets, matrices)
    for _, layer in ipairs(tiles.tileLayers) do
        if room and backingMatrices[layer] then
            restoreBackingAreas(room, layer, targets, matrices)
        end
    end
end

function tiles.getBackingMatrices(targets)
    return table.shallowcopy(backingMatrices)
end

return tiles