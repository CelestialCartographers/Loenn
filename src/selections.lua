local layerHandlers = require("layer_handlers")
local utils = require("utils")
local sceneHandler = require("scene_handler")
local toolUtils = require("tool_utils")
local tiles = require("tiles")
local subLayers = require("sub_layers")
local snapshot = require("structs.snapshot")
local snapshotUtils = require("snapshot_utils")
local selectionItemUtils = require("selection_item_utils")
local toolHandler = require("tools")

local selectionUtils = {}

-- Higher is better
local layerSortingPriority = {
    entities = 4,
    triggers = 4,
    decalsFg = 4,
    decalsBg = 3,
    tilesFg = 2,
    tilesBg = 1,
}

function selectionUtils.selectionTargetLayers(selectionTargets, includeTiles)
    local layers = {}

    includeTiles = includeTiles == nil or includeTiles

    for _, target in ipairs(selectionTargets) do
        if includeTiles or not tiles.tileLayers[target.layer] then
            layers[target.layer] = true
        end
    end

    return table.keys(layers)
end

function selectionUtils.redrawTargetLayers(room, selectionTargets)
    local targetLayers = selectionUtils.selectionTargetLayers(selectionTargets, false)

    toolUtils.redrawTargetLayer(room, targetLayers)
end

function selectionUtils.getSelectionsForItem(room, layer, item, rectangles)
    rectangles = rectangles or {}

    local handler = layerHandlers.getHandler(layer)

    if not handler or not handler.getSelection then
        return rectangles
    end

    local main, nodes = handler.getSelection(room, item)

    if main then
        main.item = item
        main.node = 0
        main.layer = layer

        table.insert(rectangles, main)
    end

    if nodes then
        for j, node in ipairs(nodes) do
            node.item = item
            node.node = j
            node.layer = layer

            table.insert(rectangles, node)
        end
    end

    return rectangles
end

function selectionUtils.updateSelectionRectangles(room, selections)
    local seenItemsSelections = {}

    for _, selection in ipairs(selections) do
        local layer = selection.layer
        local item = selection.item
        local node = selection.node

        if not seenItemsSelections[item] then
            seenItemsSelections[item] = selectionUtils.getSelectionsForItem(room, layer, item)
        end

        -- Main selection is node 0, offset by 1
        local itemSelections = seenItemsSelections[item]
        local targetSelection = itemSelections[node + 1]

        if targetSelection then
            selection.x = targetSelection.x
            selection.y = targetSelection.y

            selection.width = targetSelection.width
            selection.height = targetSelection.height
        end
    end
end

function selectionUtils.getLayerSelectionsForRoom(room, layer, subLayer, rectangles)
    rectangles = rectangles or {}

    local handler = layerHandlers.getHandler(layer)

    if room and handler and handler.getSelection then
        local items = handler.getRoomItems and handler.getRoomItems(room, layer)

        if items then
            for _, item in ipairs(items) do
                local processItem = true

                if handler.selectionFilterPredicate then
                    processItem = handler.selectionFilterPredicate(room, layer, subLayer, item)
                end

                if processItem then
                    selectionUtils.getSelectionsForItem(room, layer, item, rectangles)
                end
            end
        end
    end

    return rectangles
end

function selectionUtils.getSelectionsForRoom(room, layer, subLayer)
    local rectangles = {}

    if type(layer) == "table" then
        for _, l in ipairs(layer) do
            -- TODO This sublayer is technically wrong, figure out a solution?
            -- Using -1 for now, meaning all sublayers
            selectionUtils.getLayerSelectionsForRoom(room, l, -1, rectangles)
        end

    else
        selectionUtils.getLayerSelectionsForRoom(room, layer, subLayer, rectangles)
    end

    return rectangles
end

-- Sorts by priority, then selection area
-- Smaller area is better
function selectionUtils.orderSelectionsByScore(selections)
    table.sort(selections, function(lhs, rhs)
        local lhsPriority = layerSortingPriority[lhs.layer] or 1
        local rhsPriority = layerSortingPriority[rhs.layer] or 1

        if lhsPriority ~= rhsPriority then
            return lhsPriority > rhsPriority
        end

        return lhs.width * lhs.height < rhs.width * rhs.height
    end)

    return selections
end

local function addTileSelection(layer, room, rectangle, selected)
    if tiles.tileLayers[layer] then
        local selection = tiles.getSelectionFromRectangle(room, layer, rectangle)

        if selection then
            table.insert(selected, selection)
        end
    end
end

function selectionUtils.getSelectionsForRoomInRectangle(room, layer, subLayer, rectangle)
    local selected = {}

    if not room or not rectangle then
        return selected
    end

    -- Handle tile selections
    utils.callIterateFirstIfTable(addTileSelection, layer, room, rectangle, selected)

    -- All other selections
    local rectangles = selectionUtils.getSelectionsForRoom(room, layer, subLayer)

    for _, selection in ipairs(rectangles) do
        if utils.aabbCheck(rectangle, selection) then
            table.insert(selected, selection)
        end
    end

    return selected
end

function selectionUtils.getContextSelections(room, layer, subLayer, x, y, selections)
    local selectionTargets

    local rectangle = utils.rectangle(x - 1, y - 1, 3, 3)
    local hoveredSelections = selectionUtils.getSelectionsForRoomInRectangle(room, layer, subLayer, rectangle)
    local bestSelection

    selectionUtils.orderSelectionsByScore(hoveredSelections)

    if #hoveredSelections > 0 then
        if selections and #selections > 0 then
            -- Make sure we are at hovering one of the selections
            local hoveringFromSelections = false

            for _, hovered in ipairs(hoveredSelections) do
                for _, selection in ipairs(selections) do
                    if hovered.item == selection.item then
                        hoveringFromSelections = true
                        bestSelection = hovered

                        break
                    end
                end

                if hoveringFromSelections then
                    break
                end
            end

            if hoveringFromSelections then
                selectionTargets = table.shallowcopy(selections)
            end

        else
            if #hoveredSelections > 0 then
                selectionTargets = {hoveredSelections[1]}
                bestSelection = hoveredSelections[1]
            end
        end
    end

    return selectionTargets, bestSelection
end

function selectionUtils.sendContextMenuEvent(selections, bestSelection, room)
    if selections and #selections > 0 then
        sceneHandler.sendEvent("editorSelectionContextMenu", selections, bestSelection, room)
    end
end

function selectionUtils.deleteItems(room, targets)
    local relevantLayers = selectionUtils.selectionTargetLayers(targets)
    local snapshot, madeChanges, selectionsBefore = snapshotUtils.roomLayersSnapshot(function()
        local madeChanges = false
        local selectionsBefore = utils.deepcopy(targets)

        for i = #targets, 1, -1 do
            local item = targets[i]
            local deleted = selectionItemUtils.deleteSelection(room, item.layer, item)

            if deleted then
                madeChanges = true

                table.remove(targets, i)
            end
        end

        return madeChanges, selectionsBefore
    end, room, relevantLayers, "Selection Deleted")

    return snapshot, madeChanges
end

local function subLayerInfoSnapshot(layer, subLayer)
    local originalName = subLayers.getLayerName(layer, subLayer)

    local function forward()
        subLayers.setLayerName(layer, subLayer, nil)
        sceneHandler.sendEvent("editorLayerDeleted", layer, subLayer)
        toolHandler.setLayer(layer, -1)
    end

    local function backward()
        subLayers.setLayerName(layer, subLayer, originalName)
        sceneHandler.sendEvent("editorLayerAdded", layer, subLayer)
        toolHandler.setLayer(layer, subLayer)
    end

    return snapshot.create("Delete sub layer", {}, backward, forward)
end

function selectionUtils.deleteSubLayer(map, layer, subLayer)
    local snapshots = {}
    local relevantRooms = {}

    for _, room in ipairs(map.rooms) do
        local relevantItems = selectionUtils.getLayerSelectionsForRoom(room, layer, subLayer)
        local snapshot, madeChanges = selectionUtils.deleteItems(room, relevantItems)

        if madeChanges then
            table.insert(relevantRooms, room)
            table.insert(snapshots, snapshot)
        end
    end

    if #snapshots > 0 then
        -- We also need a snapshot to remove/restore the layer information
        local layerInfoSnapshot = subLayerInfoSnapshot(layer, subLayer)

        table.insert(snapshots, layerInfoSnapshot)

        return snapshotUtils.multiSnapshot("Deleted Group", snapshots), relevantRooms
    end
end

return selectionUtils
