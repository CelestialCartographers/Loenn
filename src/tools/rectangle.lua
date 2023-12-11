-- TODO - Consider making the "cursor" rectangle display the tile and how it would connect

local state = require("loaded_state")
local viewportHandler = require("viewport_handler")
local configs = require("configs")
local matrixLib = require("utils.matrix")
local colors = require("consts.colors")
local drawing = require("utils.drawing")
local utils = require("utils")
local toolUtils = require("tool_utils")
local brushHelper = require("brushes")
local brushToolUtils = require("utils.brush_tool")

local tool = {}

tool._type = "tool"
tool.name = "rectangle"
tool.group = "brush"
tool.image = nil

tool.mode = "fill"
tool.modes = {
    "fill",
    "line"
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

local function handleDragFinished()
    local room = state.getSelectedRoom()

    if room and startX and startY and dragX and dragY then
        local tiles = room[tool.layer]
        local tilesMatrix = tiles.matrix
        local roomWidth, roomHeight = tiles.matrix:size()

        local brushStartX, brushStartY = math.min(startX, dragX), math.min(startY, dragY)
        local brushStopX, brushStopY = math.max(startX, dragX), math.max(startY, dragY)

        -- Clamp inside room
        -- Make sure the line mode doesn't push the borders into the room
        brushStartX, brushStartY = math.max(brushStartX, -1), math.max(brushStartY, -1)
        brushStopX, brushStopY = math.min(brushStopX, roomWidth), math.min(brushStopY, roomHeight)

        local width, height = brushStopX - brushStartX + 1, brushStopY - brushStartY + 1
        local matrix = matrixLib.filled(tool.material, width, height)

        if width > 0 and height > 0 then
            if tool.mode == "line" then
                for x = 2, width - 1 do
                    for y = 2, height - 1 do
                        matrix:set(x, y, " ")
                    end
                end
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
    end
end

function tool.draw()
    local room = state.getSelectedRoom()

    if room  then
        local brushX, brushY = lastMouseX, lastMouseY
        local width, height = 1, 1

        if startX and startY and dragX and dragY then
            brushX, brushY = math.min(startX, dragX), math.min(startY, dragY)
            width, height = math.abs(startX - dragX) + 1, math.abs(startY - dragY) + 1
        end

        viewportHandler.drawRelativeTo(room.x, room.y, function()
            drawing.callKeepOriginalColor(function()
                love.graphics.setColor(colors.brushColor)
                love.graphics.rectangle("line", brushX * 8, brushY * 8, width * 8, height * 8)

                -- Draw inner rectangle to indicate line mode
                -- Only needed if the selected area is large enough
                if tool.mode == "line" and width > 2 and height > 2 then
                    love.graphics.rectangle("line", brushX * 8 + 8, brushY * 8 + 8, width * 8 - 16, height * 8 - 16)
                end
            end)
        end)
    end
end

function tool.editorMapTargetChanged()
    brushToolUtils.clearTileSnapshot(tool)
end

return tool