local viewportHandler = require("viewport_handler")
local tasks = require("task")
local mapcoder = require("mapcoder")
local celesteRender = require("celeste_render")
local sceneHandler = require("scene_handler")

local mapStruct = require("structs/map")

local state = {}

-- TODO - Check for changes and warn users when we aren't just a map viewer
function state.loadMap(filename)
    sceneHandler.changeScene("Loading")

    tasks.newTask(
        (-> filename and mapcoder.decodeFile(filename)),
        function(task)
            if task.result then
                celesteRender.invalidateRoomCache()
                celesteRender.clearBatchingTasks()

                state.map = mapStruct.decode(task.result)
                state.selectedRoom = state.map and state.map.rooms[1]

                sceneHandler.changeScene("Editor")

            else
                -- TODO - Toast the user
            end
        end
    )
end

function state.selectRoom(room)
    state.selectedRoom = room
end

function state.getSelectedRoom()
    return state.selectedRoom
end

-- The currently loaded map
state.map = nil

-- The currently selected room
state.selectedRoom = nil

-- The viewport for the map renderer
state.viewport = viewportHandler.viewport

return state