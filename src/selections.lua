local layerHandlers = require("layer_handlers")
local utils = require("utils")
local sceneHandler = require("scene_handler")
local toolUtils = require("tool_utils")
local tiles = require("tiles")

local selectionUtils = {}

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

function selectionUtils.getLayerSelectionsForRoom(room, layer, rectangles)
    rectangles = rectangles or {}

    local handler = layerHandlers.getHandler(layer)

    if room and handler and handler.getSelection then
        local items = handler.getRoomItems and handler.getRoomItems(room, layer)

        if items then
            for i, item in ipairs(items) do
                selectionUtils.getSelectionsForItem(room, layer, item, rectangles)
            end
        end
    end

    return rectangles
end

function selectionUtils.getSelectionsForRoom(room, layer)
    local rectangles = {}

    if type(layer) == "table" then
        for _, l in ipairs(layer) do
            selectionUtils.getLayerSelectionsForRoom(room, l, rectangles)
        end

    else
        selectionUtils.getLayerSelectionsForRoom(room, layer, rectangles)
    end

    return rectangles
end

-- Sort by area, smaller first
function selectionUtils.orderSelectionsByScore(selections)
    table.sort(selections, function(lhs, rhs)
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

function selectionUtils.getSelectionsForRoomInRectangle(room, layer, rectangle)
    local selected = {}

    if not room or not rectangle then
        return selected
    end

    -- Handle tile selections
    utils.callIterateFirstIfTable(addTileSelection, layer, room, rectangle, selected)

    -- All other selections
    local rectangles = selectionUtils.getSelectionsForRoom(room, layer)

    for _, selection in ipairs(rectangles) do
        if utils.aabbCheck(rectangle, selection) then
            table.insert(selected, selection)
        end
    end

    return selected
end

function selectionUtils.getContextSelections(room, layer, x, y, selections)
    local selectionTargets

    local rectangle = utils.rectangle(x - 1, y - 1, 3, 3)
    local hoveredSelections = selectionUtils.getSelectionsForRoomInRectangle(room, layer, rectangle)
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

function selectionUtils.sendContextMenuEvent(selections, bestSelection)
    if selections and #selections > 0 then
        sceneHandler.sendEvent("editorSelectionContextMenu", selections, bestSelection)
    end
end

return selectionUtils