local layerHandlers = require("layer_handlers")
local utils = require("utils")
local sceneHandler = require("scene_handler")
local toolUtils = require("tool_utils")

local selectionUtils = {}

function selectionUtils.selectionTargetLayers(selectionTargets)
    local layers = {}

    for _, target in ipairs(selectionTargets) do
        layers[target.layer] = true
    end

    return table.keys(layers)
end

function selectionUtils.redrawTargetLayers(room, selectionTargets)
    local targetLayers = selectionUtils.selectionTargetLayers(selectionTargets)

    toolUtils.redrawTargetLayer(room, targetLayers)
end

function selectionUtils.getSelectionsForItem(room, layer, item, rectangles)
    rectangles = rectangles or {}

    local handler = layerHandlers.getHandler(layer)
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

function selectionUtils.getLayerSelectionsForRoom(room, layer, rectangles)
    rectanles = rectangles or {}

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

function selectionUtils.getSelectionsForRoomInRectangle(room, layer, rectangle)
    local selected = {}

    if room and rectangle then
        local rectangles = selectionUtils.getSelectionsForRoom(room, layer)

        for _, selection in ipairs(rectangles) do
            if utils.aabbCheck(rectangle, selection) then
                table.insert(selected, selection)
            end
        end
    end

    return selected
end

function selectionUtils.getContextSelections(room, layer, x, y, selections)
    local previewTargets

    local rectangle = utils.rectangle(x - 1, y - 1, 3, 3)
    local hoveredSelections = selectionUtils.getSelectionsForRoomInRectangle(room, layer, rectangle)

    selectionUtils.orderSelectionsByScore(hoveredSelections)

    if #hoveredSelections > 0 then
        if selections and #selections > 0 then
            -- Make sure we are at hovering one of the selections
            local hoveringFromSelections = false

            for _, hovered in ipairs(hoveredSelections) do
                for _, selection in ipairs(selections) do
                    if hovered.item == selection.item then
                        hoveringFromSelections = true

                        break
                    end
                end

                if hoveringFromSelections then
                    break
                end
            end

            if hoveringFromSelections then
                previewTargets = table.shallowcopy(selections)
            end

        else
            if #hoveredSelections > 0 then
                previewTargets = {hoveredSelections[1]}
            end
        end
    end

    return previewTargets
end

function selectionUtils.sendContextMenuEvent(selections)
    if selections and #selections > 0 then
        sceneHandler.sendEvent("editorSelectionContextMenu", selections)
    end
end

return selectionUtils