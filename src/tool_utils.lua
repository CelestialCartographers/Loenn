local state = require("loaded_state")
local viewportHandler = require("viewport_handler")
local celesteRender = require("celeste_render")
local sceneHandler = require("scene_handler")
local utils = require("utils")
local persistence = require("persistence")

local toolUtils = {}

function toolUtils.getCursorPositionInRoom(x, y)
    local room = state.getSelectedRoom()
    local px, py = nil, nil

    if room then
        px, py = viewportHandler.getRoomCoordindates(room, x, y)
    end

    return px, py
end

-- TODO - Redraw more efficiently
function toolUtils.redrawTargetLayer(room, layer)
    if type(layer) == "table" then
        for _, l in ipairs(layer) do
            celesteRender.invalidateRoomCache(room, l)
        end

    else
        celesteRender.invalidateRoomCache(room, layer)
    end

    celesteRender.invalidateRoomCache(room, "complete")
    celesteRender.forceRoomBatchRender(room, state.viewport)
end

function toolUtils.getPersistenceKey(...)
    return "tool" .. table.concat(utils.titleCase@({...}))
end

function toolUtils.getPersistenceValue(...)
    return persistence[toolUtils.getPersistenceKey(...)]
end

function toolUtils.getPersistenceMode(toolName)
    return toolUtils.getPersistenceValue(toolName, "mode")
end

function toolUtils.getPersistenceLayer(toolName)
    return toolUtils.getPersistenceValue(toolName, "layer")
end

function toolUtils.getPersistenceMaterial(toolName, layer)
    return toolUtils.getPersistenceValue(toolName, layer, "material")
end

function toolUtils.getPersistenceSearch(toolName, layer)
    return toolUtils.getPersistenceValue(toolName, layer, "search")
end

function toolUtils.sendToolEvent(tool)
    sceneHandler.sendEvent("editorToolChanged", tool)
end

function toolUtils.sendToolModeEvent(tool, mode)
    sceneHandler.sendEvent("editorToolModeChanged", tool, mode)
end

function toolUtils.sendLayerEvent(tool, layer)
    sceneHandler.sendEvent("editorToolLayerChanged", tool, layer)
end

function toolUtils.sendMaterialEvent(tool, layer, material)
    sceneHandler.sendEvent("editorToolMaterialChanged", tool, layer, material)
end

return toolUtils