-- TODO - Consider making the "cursor" rectangle display the tile and how it would connect
-- TODO - Implement Lönn's Lönn brush, successor to Ahorn's Ahorn brush

local state = require("loaded_state")
local viewportHandler = require("viewport_handler")
local configs = require("configs")
local colors = require("consts.colors")
local drawing = require("utils.drawing")
local utils = require("utils")
local toolUtils = require("tool_utils")
local matrixLib = require("utils.matrix")
local brushHelper = require("brushes")
local brushToolUtils = require("utils.brush_tool")

local tool = {}

tool._type = "tool"
tool.name = "brush"
tool.group = "brush"
tool.image = nil

tool.mode = "pencil"
tool.modes = {
    "pencil",
    "dither",
    -- "loenn"
}

tool.layer = "tilesFg"
tool.validLayers = {
    "tilesFg",
    "tilesBg"
}

tool.material = "0"
tool.materialsLookup = {}

local points = {}
local added = {}
local pointsConnectedLines

local lastMouseX, lastMouseY = -1, -1
local startX, startY = nil, nil

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
        if tool.mode == "pencil" then
            brushToolUtils.handleActionClick(tool, x, y)
        elseif tool.mode == "dither" then
            local room = state.getSelectedRoom()

            if room then
                local px, py = viewportHandler.getRoomCoordindates(room, x, y)
                local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

                brushToolUtils.startTileSnapshot(tool)
                brushHelper.placeTile(room, tx + 1, ty + 1, tool.material, tool.layer)
                brushHelper.placeTile(room, tx + 2, ty + 2, tool.material, tool.layer)
                brushToolUtils.toolMadeChanges(tool)
                brushToolUtils.stopTileSnapshot(tool)

                tool.lastTileX, tool.lastTileY = tx + 1, ty + 1
                tool.lastMaterial = tool.material

                tool.lastX, tool.lastY = x, y
            end
        elseif tool.mode == "loenn" then
            -- TODO
            return {}
        end
    elseif button == cloneButton then
        brushToolUtils.handleCloneClick(tool, x, y)
    end
end

local function addPoint(x, y, roomSize)
    if not roomSize then
        local room = state.getSelectedRoom()
        local tilesMatrix = room[tool.layer].matrix
        local roomHeight
        roomSize = tilesMatrix:size()
    end
    local roomWidth, roomHeight = roomSize

    local index = x + y * roomWidth

    if not added[index] then
        table.insert(points, {x, y})
        added[index] = true
    end
end

local function addPoints(x, y)
    local room = state.getSelectedRoom()
    local tilesMatrix = room[tool.layer].matrix
    local roomWidth, roomHeight = tilesMatrix:size()

    if tool.mode == "pencil" then
        addPoint(x, y, roomWidth)
    elseif tool.mode == "dither" then
        if startX and startY then
            local dx, dy = x - startX, y - startY
            dx, dy = 2 * math.floor(dx / 2), 2 * math.floor(dy / 2)
            x, y = startX + dx, startY + dy
        end
        addPoint(x, y, roomWidth)
        addPoint(x + 1, y + 1, roomWidth)
    elseif tool.mode == "loenn" then
        -- TODO
        return {}
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    local actionButton = configs.editor.toolActionButton
    local room = state.getSelectedRoom()

    if room then
        local px, py = viewportHandler.getRoomCoordindates(room, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        lastMouseX, lastMouseY = tx, ty

        if love.mouse.isDown(actionButton) then
            addPoints(tx, ty)
            pointsConnectedLines = brushToolUtils.connectEdgesFromPoints(points)
        end
    end
end

function tool.mousepressed(x, y, button, istouch, pressed)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        brushToolUtils.startTileSnapshot(tool)

        local room = state.getSelectedRoom()

        if room then
            local px, py = viewportHandler.getRoomCoordindates(room, x, y)
            local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

            startX, startY = tx, ty
            lastMouseX, lastMouseY = tx, ty

            addPoints(tx, ty)
            pointsConnectedLines = brushToolUtils.connectEdgesFromPoints(points)
        end
    end
end

function tool.mousereleased(x, y, button)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        local room = state.getSelectedRoom()

        if room then
            local tilesMatrix = room[tool.layer].matrix
            local roomWidth, roomHeight = tilesMatrix:size()

            local matrix = matrixLib.filled(" ", roomWidth, roomHeight)

            if #points > 0 then
                for _, point in ipairs(points) do
                    matrix:set(point[1] + 1, point[2] + 1, tool.material)
                end

                brushHelper.placeTile(room, 1, 1, matrix, tool.layer)
                brushToolUtils.toolMadeChanges(tool)
            end
        end

        brushToolUtils.stopTileSnapshot(tool)

        points = {}
        added = {}
        pointsConnectedLines = nil
        startX, startY = nil, nil
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
                elseif tool.mode == "pencil" then
                    love.graphics.rectangle("line", lastMouseX * 8, lastMouseY * 8, 8, 8)
                elseif tool.mode == "dither" then
                    love.graphics.rectangle("line", lastMouseX * 8, lastMouseY * 8, 8, 8)
                    love.graphics.rectangle("line", lastMouseX * 8 + 8, lastMouseY * 8 + 8, 8, 8)
                elseif tool.mode == "loenn" then
                    -- TODO
                end
            end)
        end)
    end
end

return tool
