local entityHandler = require("entities")
local entity = require "src.defaults.viewer.entity"
local utils = require "src.giraffe.giraffe.utils"

local selections = {}

selections.layerHandlers = {
    entities = entityHandler
}

selections.layerGetItems = {}

function selections.getSelectionsForRoom(layer, room)
    local rectangles = {}

    local handler = selections.layerHandlers[layer]

    if room and handler and handler.getSelection then
        local items = handler.getRoomItems and handler.getRoomItems(room, layer)

        if items then
            for i, item in ipairs(items) do
                local main, nodes = handler.getSelection(room, item)

                if main then
                    main.item = item
                    main.node = 0

                    table.insert(rectangles, main)
                end

                if nodes then
                    for j, node in ipairs(nodes) do
                        main.item = item
                        node.node = j

                        table.insert(rectangles, main)
                    end
                end
            end
        end
    end

    return rectangles
end

function selections.getSelectionsForRoomInRectangle(layer, room, rectangle)
    local selected = {}

    if room and rectangle then
        local rectangles = selections.getSelectionsForRoom(layer, room)

        for _, selection in ipairs(rectangles) do
            if utils.aabbCheck(rectangle, selection) then
                table.insert(selected, selection)
            end
        end
    end

    return selected
end

return selections