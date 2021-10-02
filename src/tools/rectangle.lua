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

local tool = {}

tool._type = "tool"
tool.name = "rectangle"
tool.group = "brush"
tool.image = nil

tool.mode = "line"
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

local snapshotValue = nil
local snapshotHasChanged = false

local function handleActionClick(x, y, force)
    local room = state.getSelectedRoom()

    if room then
        local px, py = viewportHandler.getRoomCoordindates(room, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        if lastTileX ~= tx + 1 or lastTileY ~= ty + 1 or force then
            brushHelper.placeTile(room, tx + 1, ty + 1, tool.material, tool.layer)

            lastTileX, lastTileY = tx + 1, ty + 1
            snapshotHasChanged = true
        end

        lastClickX, lastClickY = x, y
    end
end

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

            snapshotHasChanged = true
        end
    end
end

local function handleCloneClick(x, y)
    local room = state.getSelectedRoom()

    if room then
        local px, py = viewportHandler.getRoomCoordindates(room, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        local material = brushHelper.getTile(room, tx + 1, ty + 1, tool.layer)

        if material ~= tool.material then
            tool.material = material

            toolUtils.sendMaterialEvent(tool, tool.layer, material)
        end
    end
end

local function getTileSnapshotValue()
    local room = state.getSelectedRoom()

    return brushHelper.getRoomSnapshotValue(room, tool.layer)
end

local function startTileSnapshot()
    snapshotValue = getTileSnapshotValue()
    snapshotHasChanged = false
end

local function stopTileSnapshot()
    if snapshotValue and snapshotHasChanged then
        local room = state.getSelectedRoom()
        local afterSnapshotValue = getTileSnapshotValue()

        if afterSnapshotValue then
            local snapshot = snapshotUtils.roomTilesSnapshot(room, tool.layer, "Brush", snapshotValue, afterSnapshotValue)

            history.addSnapshot(snapshot)
        end
    end
end

local function updateMaterialLookup()
    tool.materialsLookup = brushHelper.getMaterialLookup(tool.layer)
end

function tool.getMaterials()
    local paths = brushHelper.getValidTiles(tool.layer)
    local placements = {}

    for displayName, id in pairs(tool.materialsLookup) do
        table.insert(placements, {
            name = id,
            displayName = displayName
        })
    end

    return placements
end

function tool.setMaterial(material)
    local paths = brushHelper.getValidTiles(tool.layer)
    local target = nil

    if paths[material] then
        target = material

    else
        target = tool.materialsLookup[material]
    end

    if target and target ~= tool.material then
        tool.material = target

        toolUtils.sendMaterialEvent(tool, tool.layer, target)
    end
end

function tool.setLayer(layer)
    tool.layer = layer

    updateMaterialLookup()
    toolUtils.sendLayerEvent(tool, layer)
end

function tool.mouseclicked(x, y, button, istouch, pressed)
    local actionButton = configs.editor.toolActionButton
    local cloneButton = configs.editor.objectCloneButton

    if button == actionButton then
        handleActionClick(x, y)

    elseif button == cloneButton then
        handleCloneClick(x, y)
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
            dragX, dragY = tx, ty
        end
    end
end

function tool.mousepressed(x, y, button, istouch, pressed)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        startTileSnapshot()

        local room = state.getSelectedRoom()

        if room then
            local px, py = viewportHandler.getRoomCoordindates(room, x, y)
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
        stopTileSnapshot()

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
            end)
        end)
    end
end

return tool