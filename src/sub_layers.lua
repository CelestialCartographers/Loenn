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

function subLayers.getShouldLayerRender(layer, subLayer)
    subLayer = subLayer or -1

    local groupVisible = loadedState.getLayerVisible(layer)
    local groupForcedVisible = loadedState.getLayerForceRendered(layer)

    if subLayer == -1 then
        return groupVisible or groupForcedVisible
    end

    local subLayerName = subLayers.formatLayerName(layer, subLayer)

    if groupVisible then
        -- Check if visible or selected
        return loadedState.getLayerShouldRender(subLayerName)

    else
        -- Check if selected
        return loadedState.getLayerForceRendered(subLayerName)
    end
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
    subLayer = subLayer or -1

    local layerName = subLayers.formatLayerName(layer, subLayer)

    if subLayer ~= -1 then
        -- Force main layer and the sub layer
        local layers = {layerName, layer}

        return loadedState.setLayerForceRender(layer, layers, currentValue, otherValue)
    end

    return loadedState.setLayerForceRender(layer, layerName, currentValue, otherValue)
end

function subLayers.getLayerName(layer, subLayer)
    local layerName = subLayers.formatLayerName(layer, subLayer)

    return loadedState.getLayerName(layerName)
end

function subLayers.setLayerName(layer, subLayer, name)
    local layerName = subLayers.formatLayerName(layer, subLayer)

    return loadedState.setLayerName(layerName, name)
end

return subLayers