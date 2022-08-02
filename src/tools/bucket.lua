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

local function floodFill(matrix, x, y)
    local result = {}
    local roomWidth, roomHeight = matrix:size()

    local tlx, tly, brx, bry = math.huge, math.huge, 0, 0
    local processed
    local targetedTiles

    if x >= 1 and x <= roomWidth and y >= 1 and y <= roomHeight then
        processed = matrixLib.filled(false, roomWidth, roomHeight)
        targetedTiles = matrixLib.filled(false, roomWidth, roomHeight)

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

                    tlx = math.min(targetX, tlx)
                    tly = math.min(targetX, tlx)
                    brx = math.max(targetX, brx)
                    bry = math.max(targetY, brx)

                    targetedTiles:set(targetX, targetY, true)
                end
            end
        end
    end

    return result, targetedTiles, tlx, tly, brx, bry
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

        points, currentFloodMatrix = floodFill(tilesMatrix, x, y)
        pointsConnectedLines = brushToolUtils.connectEdgesFromPoints(points)
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

        if #points > 0 then
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

                brushToolUtils.drawConnectedLines(pointsConnectedLines, -8, -8)
            end)
        end)
    end
end

return tool