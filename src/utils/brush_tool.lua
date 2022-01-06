-- For more tool specific helpers than brush helper, which is the more general way to work with changing tiles

local viewportHandler = require("viewport_handler")
local toolUtils = require("tool_utils")
local state = require("loaded_state")
local brushHelper = require("brushes")
local history = require("history")
local snapshotUtils = require("snapshot_utils")

local brushToolUtils = {}

function brushToolUtils.getPlacements(tool)
    local materialsLookup = tool.materialsLookup or brushHelper.getMaterialLookup(tool.layer)
    local paths = brushHelper.getValidTiles(tool.layer)
    local placements = {}

    for displayName, id in pairs(materialsLookup) do
        table.insert(placements, {
            name = id,
            displayName = displayName
        })
    end

    return placements
end

function brushToolUtils.setLayer(tool, layer)
    tool.layer = layer

    tool.materialsLookup = brushHelper.getMaterialLookup(layer)
    toolUtils.sendLayerEvent(tool, layer)

    local persistenceMaterial = toolUtils.getPersistenceMaterial(tool.name, layer)

    if persistenceMaterial then
        tool.setMaterial(persistenceMaterial)
    end
end

function brushToolUtils.setMaterial(tool, material)
    local paths = brushHelper.getValidTiles(tool.layer)
    local target

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

-- Place material over current hovered tile
function brushToolUtils.handleActionClick(tool, x, y, force)
    local room = state.getSelectedRoom()

    if room then
        local px, py = viewportHandler.getRoomCoordindates(room, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        if tool.lastTileX ~= tx + 1 or tool.lastTileY ~= ty + 1 or force then
            brushHelper.placeTile(room, tx + 1, ty + 1, tool.material, tool.layer)
            brushToolUtils.toolMadeChanges(tool)

            tool.lastTileX, tool.lastTileY = tx + 1, ty + 1
        end

        tool.lastX, tool.lastY = x, y
    end
end

-- Set material to current hovered tile
function brushToolUtils.handleCloneClick(tool, x, y)
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

function brushToolUtils.getTileSnapshotValue(tool)
    local room = state.getSelectedRoom()

    return brushHelper.getRoomSnapshotValue(room, tool.layer)
end

function brushToolUtils.startTileSnapshot(tool)
    tool.snapshotValue = brushToolUtils.getTileSnapshotValue(tool)
    tool.snapshotHasChanged = false
end

function brushToolUtils.stopTileSnapshot(tool)
    if tool.snapshotValue and tool.snapshotHasChanged then
        local room = state.getSelectedRoom()
        local afterSnapshotValue = brushToolUtils.getTileSnapshotValue(tool)

        if afterSnapshotValue then
            local snapshot = snapshotUtils.roomTilesSnapshot(room, tool.layer, "Brush", tool.snapshotValue, afterSnapshotValue)

            history.addSnapshot(snapshot)
        end
    end
end

function brushToolUtils.toolMadeChanges(tool)
    tool.snapshotHasChanged = true
end

return brushToolUtils