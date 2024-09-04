local loadedState = require("loaded_state")

local subLayers = {}

-- Parse layer name with sublayer baked in
function subLayers.parseLayerName(layerName)
    local layer, subLayerString = string.match(layerName, "(%w*)_(-?%d*)")

    if layer then
        return layer, tonumber(subLayerString)
    end

    return layerName, -1
end

function subLayers.formatLayerName(layer, subLayer)
    if subLayer and subLayer ~= -1 then
        return string.format("%s_%s", layer, subLayer)
    end

    return layer
end

function subLayers.getLayerVisible(layer, subLayer)
    local layerName = subLayers.formatLayerName(layer, subLayer or -1)

    return loadedState.getLayerVisible(layerName)
end

function subLayers.setLayerVisible(layer, subLayer, visible, silent)
    local layerName = subLayers.formatLayerName(layer, subLayer or -1)

    return loadedState.setLayerVisible(layerName, visible, silent)
end

function subLayers.setLayerForceRender(layer, subLayer, currentValue, otherValue)
    local layerName = subLayers.formatLayerName(layer, subLayer or -1)

    return loadedState.setLayerForceRender(layerName, currentValue, otherValue)
end

return subLayers