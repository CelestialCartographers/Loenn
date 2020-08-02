local state = require("loaded_state")
local celesteRender = require("celeste_render")

local tool = {}

tool._type = "tool"
tool.name = "Selection"
tool.image = nil

tool.layer = "entities"

function tool.keypressed(key, scancode, isrepeat)
    local room = state.getSelectedRoom()

    local ox = key == "a" and -8 or key == "d" and 8 or 0
    local oy = key == "w" and -8 or key == "s" and 8 or 0

    if room and ox ~= 0 or oy ~= 0 then
        for i, entity <- room.entities do
            entity.x += ox
            entity.y += oy
        end

        -- TODO - Redraw more efficiently
        celesteRender.invalidateRoomCache(room, tool.layer)
        celesteRender.invalidateRoomCache(room, "complete")
        celesteRender.forceRoomBatchRender(room, state.viewport)
    end
end

return tool