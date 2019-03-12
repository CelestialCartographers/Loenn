local viewportHandler = require("viewport_handler")
local tasks = require("task")
local mapcoder = require("mapcoder")

local mapStruct = require("structs/map")

local state = {}

-- TODO - Invalidate map rendering tasks and cache
function state.loadMap(filename)
    tasks.newTask(
        function()
            viewportHandler.disable()
            mapcoder.decodeFile(filename)
        end,
        function(task)
            state.map = mapStruct.decode(task.result)
            viewportHandler.enable()
        end
    )
end

function state.selectRoom(room)
    state.selectedRoom = room
end

function state.getSelectedRoomName()
    return state.selectedRoom.name
end

-- The currently loaded map
state.map = nil

-- The currently selected room
state.selectedRoom = nil

-- The viewport for the map renderer
state.viewport = viewportHandler.viewport

return state