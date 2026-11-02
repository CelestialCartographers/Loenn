-- TODO - Consider making the "cursor" rectangle display the tile and how it would connect

local state = require("loaded_state")
local viewportHandler = require("viewport_handler")
local configs = require("configs")
local brushHelper = require("brushes")
local colors = require("consts.colors")
local drawing = require("utils.drawing")
local utils = require("utils")
local snapshotUtils = require("snapshot_utils")
local history = require("history")
local toolUtils = require("tool_utils")
local matrixLib = require("utils.matrix")
local lineStruct = require("structs.line")
local brushToolUtils = require("utils.brush_tool")

local tool = {}

tool._type = "tool"
tool.name = "bucket"
tool.group = "brush"
tool.image = nil

tool.mode = "region"
tool.modes = {
    "region",
    "room"
}

tool.layer = "tilesFg"
tool.validLayers = {
    "tilesFg",
    "tilesBg"
}

tool.material = "0"
tool.materialsLookup = {}

local lastTileX, lastTileY = -1, -1
local lastClickX, lastClickY = -1, -1
local lastMouseX, lastMouseY = -1, -1
local startX, startY
local dragX, dragY
local points = {}
local pointsConnectedLines
local currentFloodMatrix

local function floodFill(matrix, x, y, targetedTiles, processed)
    local result = {}
    local roomWidth, roomHeight = matrix:size()

    if x >= 1 and x <= roomWidth and y >= 1 and y <= roomHeight then
        processed = processed or matrixLib.filled(false, roomWidth, roomHeight)
        targetedTiles = targetedTiles or matrixLib.filled(false, roomWidth, roomHeight)

        local material = matrix:get(x, y)
        local needsProcessing = {{x, y}}

        while #needsProcessing > 0 do
            local targetX, targetY = unpack(table.remove(needsProcessing))

            if not processed:get(targetX, targetY) then
                local targetMaterial = matrix:get(targetX, targetY)

                processed:set(targetX, targetY, true)

                if material == targetMaterial then
                    table.insert(result, {targetX, targetY})

                    table.insert(needsProcessing, {targetX + 1, targetY})
                    table.insert(needsProcessing, {targetX - 1, targetY})
                    table.insert(needsProcessing, {targetX, targetY + 1})
                    table.insert(needsProcessing, {targetX, targetY - 1})

                    targetedTiles:set(targetX, targetY, true)
                end
            end
        end
    end

    return result, targetedTiles, processed
end

local function updatePoints(x, y)
    local room = state.getSelectedRoom()

    if room and x and y then
        -- Part of the same flooded region
        if currentFloodMatrix and currentFloodMatrix:get(x, y) then
            return
        end

        local tiles = room[tool.layer]
        local tilesMatrix = tiles.matrix

        if tool.mode == "region" then
            points, currentFloodMatrix = floodFill(tilesMatrix, x, y)
            pointsConnectedLines = {brushToolUtils.connectEdgesFromPoints(points)}

        elseif tool.mode == "room" then
            -- Naive approach to mark all points and connection regions
            -- Attempt flood fill at all points where we haven't already gone over with a flood fill
            local targetMaterial = tilesMatrix:get(x, y)
            local width, height = tilesMatrix:size()
            local processed = matrixLib.filled(false, width, height)

            currentFloodMatrix = matrixLib.filled(false, width, height)
            points = {}
            pointsConnectedLines = {}

            for roomX = 1, width do
                for roomY = 1, height do
                    if targetMaterial == tilesMatrix:get(roomX, roomY) and not processed:get(roomX, roomY) then
                        local newPoints = floodFill(tilesMatrix, roomX, roomY, currentFloodMatrix, processed)

                        table.insert(pointsConnectedLines, brushToolUtils.connectEdgesFromPoints(newPoints))

                        for _, point in ipairs(newPoints) do
                            table.insert(points, point)
                        end
                    end
                end
            end
        end
    end
end

local function handleActionClick(x, y, force)
    local room = state.getSelectedRoom()

    if room then
        local px, py = viewportHandler.getRoomCoordinates(room, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        local tiles = room[tool.layer]
        local tilesMatrix = tiles.matrix
        local roomWidth, roomHeight = tilesMatrix:size()
        local matrix = matrixLib.filled(" ", roomWidth, roomHeight)

        if points and #points > 0 then
            for _, point in ipairs(points) do
                matrix:set(point[1], point[2], tool.material)
            end

            brushHelper.placeTile(room, 1, 1, matrix, tool.layer)
            brushToolUtils.toolMadeChanges(tool)
        end

        points, currentFloodMatrix = nil, nil
        pointsConnectedLines = nil

        updatePoints(tx + 1, ty + 1)
    end
end

function tool.getMaterials()
    return brushToolUtils.getPlacements(tool)
end

function tool.setMaterial(material)
    brushToolUtils.setMaterial(tool, material)
end

function tool.setLayer(layer)
    brushToolUtils.setLayer(tool, layer)
end

function tool.mouseclicked(x, y, button, istouch, pressed)
    local actionButton = configs.editor.toolActionButton
    local cloneButton = configs.editor.objectCloneButton

    if button == actionButton then
        handleActionClick(x, y)

    elseif button == cloneButton then
        brushToolUtils.handleCloneClick(tool, x, y)
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    local actionButton = configs.editor.toolActionButton
    local room = state.getSelectedRoom()

    if room then
        local px, py = viewportHandler.getRoomCoordinates(room, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        if lastMouseX ~= tx or lastMouseY ~= ty then
            updatePoints(tx + 1, ty + 1)
        end

        lastMouseX, lastMouseY = tx + 1, ty + 1
    end
end

function tool.mousepressed(x, y, button, istouch, pressed)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        local room = state.getSelectedRoom()

        brushToolUtils.startTileSnapshot(tool)
    end
end

function tool.mousereleased(x, y, button)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        local room = state.getSelectedRoom()

        if room then
            handleActionClick(x, y)
        end

        brushToolUtils.stopTileSnapshot(tool)
    end
end

function tool.draw()
    local room = state.getSelectedRoom()

    if room then
        viewportHandler.drawRelativeTo(room.x, room.y, function()
            drawing.callKeepOriginalColor(function()
                love.graphics.setColor(colors.brushColor)

                for _, previewConnectedLines in ipairs(pointsConnectedLines or {}) do
                    brushToolUtils.drawConnectedLines(previewConnectedLines, -8, -8)
                end
            end)
        end)
    end
end

function tool.editorMapTargetChanged()
    brushToolUtils.clearTileSnapshot(tool)
end

return tool