local configs = require("configs")
local sceneHandler = require("scene_handler")

local sanitizer = {}

function sanitizer.beforeSave(filename, state)
    if configs.editor.sortRoomsOnSave then
        local map = state.side.map

        table.sort(map.rooms, function(lhs, rhs)
            return lhs.name < rhs.name
        end)

        -- TODO - Only if order changed
        sceneHandler.sendEvent("editorRoomOrderChanged", map)
    end
end

return sanitizer