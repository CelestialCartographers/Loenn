local viewportHandler = require("viewport_handler")
local tasks = require("task")
local mapcoder = require("mapcoder")
local celesteRender = require("celeste_render")

local mapStruct = require("structs/map")

local state = {}

-- TODO - Check for changes and warn users when we aren't just a map viewer
function state.loadMap(filename)
    celesteRender.invalidateRoomCache()
    celesteRender.clearBatchingTasks()

    state.map = nil

    tasks.newTask(
        (-> mapcoder.decodeFile(filename)),
        function(task)
            state.map = mapStruct.decode(task.result)
            state.selectedRoom = state.map and state.map.rooms[1]
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