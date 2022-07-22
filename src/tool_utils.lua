local state = require("loaded_state")
local viewportHandler = require("viewport_handler")
local celesteRender = require("celeste_render")
local sceneHandler = require("scene_handler")
local utils = require("utils")
local persistence = require("persistence")
local configs = require("configs")

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
    celesteRender.forceRoomBatchRender(room, state)
end

function toolUtils.getPersistenceKey(...)
    return "tool" .. table.concat(utils.titleCase@({...}))
end

function toolUtils.getPersistenceValue(...)
    return persistence[toolUtils.getPersistenceKey(...)]
end

function toolUtils.setPersistenceValue(value, ...)
    persistence[toolUtils.getPersistenceKey(...)] = value
end

function toolUtils.getToolPersistenceIdentifier(tool)
    if configs.editor.toolsPersistUsingGroup then
        -- Use group is it exists on the tool, name otherwise
        return tool.group or tool.name
    end

    return tool.name
end

function toolUtils.getPersistenceMode(tool)
    return toolUtils.getPersistenceValue(toolUtils.getToolPersistenceIdentifier(tool), "mode")
end

function toolUtils.getPersistenceLayer(tool)
    return toolUtils.getPersistenceValue(toolUtils.getToolPersistenceIdentifier(tool), "layer")
end

function toolUtils.getPersistenceMaterial(tool, layer)
    return toolUtils.getPersistenceValue(toolUtils.getToolPersistenceIdentifier(tool), layer, "material")
end

function toolUtils.getPersistenceSearch(tool, layer)
    return toolUtils.getPersistenceValue(toolUtils.getToolPersistenceIdentifier(tool), layer, "search")
end

function toolUtils.setPersistenceMode(tool, mode)
    return toolUtils.setPersistenceValue(mode, toolUtils.getToolPersistenceIdentifier(tool), "mode")
end

function toolUtils.setPersistenceLayer(tool, layer)
    return toolUtils.setPersistenceValue(layer, toolUtils.getToolPersistenceIdentifier(tool), "layer")
end

function toolUtils.setPersistenceMaterial(tool, layer, material)
    return toolUtils.setPersistenceValue(material, toolUtils.getToolPersistenceIdentifier(tool), layer, "material")
end

function toolUtils.setPersistenceSearch(tool, layer, search)
    return toolUtils.setPersistenceValue(search, toolUtils.getToolPersistenceIdentifier(tool), layer, "search")
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