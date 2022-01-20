local layerHandlers = require("layer_handlers")
local utils = require("utils")
local keyboardHelper = require("utils.keyboard")
local configs = require("configs")
local state = require("loaded_state")

local placementUtils = {}

function placementUtils.getPlacements(layer)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.getPlacements then
        return handler.getPlacements(layer)
    end

    return {}
end

function placementUtils.getDrawable(layer, name, room, data)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.getDrawable then
        return handler.getDrawable(name, nil, room, data, nil)
    end

    return nil
end

local idLayers = {"entities", "triggers"}

-- Add unique ID to trigger/entity
function placementUtils.finalizePlacement(room, layer, item)
    if layer == "entities" or layer == "triggers" then
        local ids = {}

        for _, targetLayer in ipairs(idLayers) do
            for _, targetRoom in ipairs(state.map.rooms) do
                if targetRoom[targetLayer] then
                    for _, target in ipairs(targetRoom[layer]) do
                        if target._id then
                            ids[target._id] = true
                        end
                    end
                end
            end
        end

        for id = 0, math.huge do
            if not ids[id] then
                item._id = id

                return
            end
        end
    end
end

function placementUtils.getGridSize(precise)
    precise = precise ~= false and keyboardHelper.modifierHeld(configs.editor.precisionModifier)

    return precise and 1 or 8
end

function placementUtils.getGridPosition(x, y, precise, addHalf)
    x = x or 0
    y = y or 0

    precise = precise ~= false and keyboardHelper.modifierHeld(configs.editor.precisionModifier)

    if precise then
        return x, y

    else
        local gridSize = placementUtils.getGridSize(precise)
        local halfSize = math.floor(gridSize / 2)

        if addHalf ~= false then
            return math.floor((x + halfSize) / gridSize) * gridSize, math.floor((y + halfSize) / gridSize) * gridSize

        else
            return math.floor(x / gridSize) * gridSize, math.floor(y / gridSize) * gridSize
        end
    end
end

function placementUtils.placeItem(room, layer, item)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.placeItem then
        placementUtils.finalizePlacement(room, layer, item)

        return handler.placeItem(room, layer, item)
    end

    return false
end

function placementUtils.cloneItem(room, layer, item)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.cloneItem then
        return handler.cloneItem(room, layer, item)
    end

    return false
end

function placementUtils.canResize(room, layer, target)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.canResize then
        return handler.canResize(room, layer, target)
    end

    return false, false
end

function placementUtils.minimumSize(room, layer, target)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.minimumSize then
        return handler.minimumSize(room, layer, target)
    end

    return nil, nil
end

function placementUtils.nodeLimits(room, layer, target)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.nodeLimits then
        return handler.nodeLimits(room, layer, target)
    end

    return 0, 0
end

return placementUtils