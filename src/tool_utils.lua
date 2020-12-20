local state = require("loaded_state")
local viewportHandler = require("viewport_handler")
local celesteRender = require("celeste_render")

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

return toolUtils