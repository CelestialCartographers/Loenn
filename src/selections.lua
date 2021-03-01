local layerHandlers = require("layer_handlers")
local utils = require("utils")
local sceneHandler = require("scene_handler")

local selectionUtils = {}

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

function selectionUtils.getSelectionsForRoom(room, layer)
    local rectangles = {}
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

    if selections and #selections > 0 then
        previewTargets = utils.deepcopy(selections)

    else
        local rectangle = utils.rectangle(x - 1, y - 1, 3, 3)
        local hoveredSelections = selectionUtils.getSelectionsForRoomInRectangle(room, layer, rectangle)

        if #hoveredSelections > 0 then
            selectionUtils.orderSelectionsByScore(hoveredSelections)

            previewTargets = {hoveredSelections[1]}
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