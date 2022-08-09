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
tool.name = "line"
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

local function handleDragFinished()
    local room = state.getSelectedRoom()

    if room and startX and startY and dragX and dragY then
        local tiles = room[tool.layer]
        local tilesMatrix = tiles.matrix
        local roomWidth, roomHeight = tilesMatrix:size()

        local brushStartX, brushStartY = math.min(startX, dragX), math.min(startY, dragY)
        local brushStopX, brushStopY = math.max(startX, dragX), math.max(startY, dragY)

        local width, height = brushStopX - brushStartX + 1, brushStopY - brushStartY + 1
        local matrix = matrixLib.filled(" ", width, height)

        if #points > 0 then
            for _, point in ipairs(points) do
                local x, y = point[1] - brushStartX + 1, point[2] - brushStartY + 1

                matrix:set(x, y, tool.material)
            end

            brushHelper.placeTile(room, brushStartX + 1, brushStartY + 1, matrix, tool.layer)
            brushToolUtils.toolMadeChanges(tool)
        end
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
        brushToolUtils.handleActionClick(tool, x, y)

    elseif button == cloneButton then
        brushToolUtils.handleCloneClick(tool, x, y)
    end
end

local function updatePoints()
    if startX and startY and dragX and dragY then
        local line = lineStruct.create(startX, startY, dragX, dragY)

        points = line:getPoints()
        pointsConnectedLines = brushToolUtils.connectEdgesFromPoints(points)
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    local actionButton = configs.editor.toolActionButton
    local room = state.getSelectedRoom()

    if room then
        local px, py = viewportHandler.getRoomCoordinates(room, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        lastMouseX, lastMouseY = tx, ty

        if love.mouse.isDown(actionButton) then
            dragX, dragY = tx, ty
        end

        updatePoints()
    end
end

function tool.mousepressed(x, y, button, istouch, pressed)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        brushToolUtils.startTileSnapshot(tool)

        local room = state.getSelectedRoom()

        if room then
            local px, py = viewportHandler.getRoomCoordinates(room, x, y)
            local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

            startX, startY = tx, ty
            dragX, dragY = tx, ty

            updatePoints()
        end
    end
end

function tool.mousereleased(x, y, button)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        handleDragFinished()
        brushToolUtils.stopTileSnapshot(tool)

        startX, startY = nil, nil
        dragX, dragY = nil, nil
        points = {}
        pointsConnectedLines = nil
    end
end

function tool.draw()
    local room = state.getSelectedRoom()

    if room then
        viewportHandler.drawRelativeTo(room.x, room.y, function()
            drawing.callKeepOriginalColor(function()
                love.graphics.setColor(colors.brushColor)

                if #points > 0 then
                    brushToolUtils.drawConnectedLines(pointsConnectedLines)

                else
                    love.graphics.rectangle("line", lastMouseX * 8, lastMouseY * 8, 8, 8)
                end
            end)
        end)
    end
end

return tool