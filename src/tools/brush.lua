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

local tool = {}

tool._type = "tool"
tool.name = "brush"
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
local lastX, lastY = -1, -1

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

        lastX, lastY = x, y
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

    if love.mouse.isDown(actionButton) then
        handleActionClick(x, y)
    end
end

function tool.mousepressed(x, y, button, istouch, pressed)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        startTileSnapshot()
    end
end

function tool.mousereleased(x, y, button)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        stopTileSnapshot()
    end
end

function tool.draw()
    local room = state.getSelectedRoom()

    if room then
        local px, py = viewportHandler.getRoomCoordindates(room)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        viewportHandler.drawRelativeTo(room.x, room.y, function()
            drawing.callKeepOriginalColor(function()
                love.graphics.setColor(colors.brushColor)
                love.graphics.rectangle("line", tx * 8, ty * 8, 8, 8)
            end)
        end)
    end
end

return tool