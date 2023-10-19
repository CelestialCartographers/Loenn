-- For more tool specific helpers than brush helper, which is the more general way to work with changing tiles

local viewportHandler = require("viewport_handler")
local toolUtils = require("tool_utils")
local state = require("loaded_state")
local brushHelper = require("brushes")
local history = require("history")
local snapshotUtils = require("snapshot_utils")
local matrixLib = require("utils.matrix")
local tiles = require("tiles")

local brushToolUtils = {}

function brushToolUtils.getPlacements(tool)
    local materialsLookup = tool.materialsLookup or brushHelper.getMaterialLookup(tool.layer)
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

    local persistenceMaterial = toolUtils.getPersistenceMaterial(tool, layer)

    if persistenceMaterial then
        tool.setMaterial(persistenceMaterial)
    end
end

function brushToolUtils.setMaterial(tool, material)
    local validTiles = brushHelper.getValidTiles(tool.layer)
    local target

    if validTiles[material] then
        target = material
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
        local px, py = viewportHandler.getRoomCoordinates(room, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        if tool.lastMaterial ~= tool.material or tool.lastTileX ~= tx + 1 or tool.lastTileY ~= ty + 1 or force then
            brushHelper.placeTile(room, tx + 1, ty + 1, tool.material, tool.layer)
            brushToolUtils.toolMadeChanges(tool)

            tool.lastTileX, tool.lastTileY = tx + 1, ty + 1
            tool.lastMaterial = tool.material
        end

        tool.lastX, tool.lastY = x, y
    end
end

-- Set material to current hovered tile
function brushToolUtils.handleCloneClick(tool, x, y)
    local room = state.getSelectedRoom()

    if room then
        local px, py = viewportHandler.getRoomCoordinates(room, x, y)
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

    return tiles.getRoomTileSnapshotValue(room, tool.layer)
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

function brushToolUtils.connectEdges(edges)
    local trees = table.shallowcopy(edges)
    local base = 1

    while true do
        local baseTree = trees[base]

        if not baseTree then
            break
        end

        local madeChanges = false
        local baseStartX, baseStartY = baseTree[1], baseTree[2]
        local baseStopX, baseStopY = baseTree[#baseTree - 1], baseTree[#baseTree]

        for target = #trees, base + 1, -1 do
            local targetTree = trees[target]
            local targetStartX, targetStartY = targetTree[1], targetTree[2]
            local targetStopX, targetStopY = targetTree[#targetTree - 1], targetTree[#targetTree]

            if baseStopX == targetStartX and baseStopY == targetStartY then
                madeChanges = true

                for i = 3, #targetTree do
                    table.insert(baseTree, targetTree[i])
                end

                table.remove(trees, target)

            elseif baseStopX == targetStopX and baseStopY == targetStopY then
                madeChanges = true

                for i = #targetTree - 3, 1, -2 do
                    table.insert(baseTree, targetTree[i])
                    table.insert(baseTree, targetTree[i + 1])
                end

                table.remove(trees, target)
            end

            if madeChanges then
                break
            end
        end

        if not madeChanges then
            base += 1
        end
    end

    return trees
end

function brushToolUtils.getPointEdges(points)
    if #points == 0 then
        return {}
    end

    local edges = {}

    -- Figure out a fitting matrix size
    local tlx, tly = math.huge, math.huge
    local brx, bry = 0, 0

    for _, point in ipairs(points) do
        tlx, tly = math.min(tlx, point[1]), math.min(tly, point[2])
        brx, bry = math.max(brx, point[1]), math.max(bry, point[2])
    end

    local width, height = brx - tlx + 1, bry - tly + 1
    local pointMatrix = matrixLib.filled(false, width, height)

    for _, point in ipairs(points) do
        pointMatrix:set(point[1] - tlx + 1, point[2] - tly + 1, true)
    end

    -- Offsets for the edge points
    local ox, oy = tlx - 1, tly - 1

    for x = 1, width do
        for y = 1, height do
            local target = pointMatrix:get(x, y)

            if target then
                local up = pointMatrix:get(x, y - 1, false)
                local down = pointMatrix:get(x, y + 1, false)
                local left = pointMatrix:get(x - 1, y, false)
                local right = pointMatrix:get(x + 1, y, false)

                if not up then
                    table.insert(edges, {ox + x, oy + y, ox + x + 1, oy + y})
                end

                if not down then
                    table.insert(edges, {ox + x, oy + y + 1, ox + x + 1, oy + y + 1})
                end

                if not left then
                    table.insert(edges, {ox + x, oy + y, ox + x, oy + y + 1})
                end

                if not right then
                    table.insert(edges, {ox + x + 1, oy + y, ox + x + 1, oy + y + 1})
                end
            end
        end
    end

    return edges
end

function brushToolUtils.connectEdgesFromPoints(points)
    return brushToolUtils.connectEdges(brushToolUtils.getPointEdges(points))
end

function brushToolUtils.drawConnectedLines(lines, offsetX, offsetY, gridSize)
    if not lines then
        return
    end

    gridSize = gridSize or 8
    offsetX, offsetY = offsetX or 0, offsetY or 0

    for _, line in ipairs(lines) do
        if gridSize > 1 or offsetX ~= 0 or offsetY ~= 0 then
            local newLine = {}

            for i = 1, #line, 2 do
                newLine[i] = line[i] * gridSize + offsetX
                newLine[i + 1] = line[i + 1] * gridSize + offsetY
            end

            line = newLine
        end

        love.graphics.line(line)
    end
end

function brushToolUtils.drawConnectedPoints(points, offsetX, offsetY, gridSize)
    local connectedLines = brushToolUtils.connectEdgesFromPoints(points)

    brushToolUtils.drawConnectedLines(connectedLines, offsetX, offsetY, gridSize)
end

return brushToolUtils