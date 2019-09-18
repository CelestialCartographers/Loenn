local viewportHandler = require("viewport_handler")
local tasks = require("task")
local mapcoder = require("mapcoder")
local celesteRender = require("celeste_render")
local sceneHandler = require("scene_handler")

local sideStruct = require("structs/side")

local state = {}

-- TODO - Check for changes and warn users when we aren't just a map viewer
function state.loadFile(filename)
    sceneHandler.changeScene("Loading")

    tasks.newTask(
        (-> filename and mapcoder.decodeFile(filename)),
        function(task)
            if task.result then
                celesteRender.invalidateRoomCache()
                celesteRender.clearBatchingTasks()

                state.side = sideStruct.decode(task.result)
                state.map = state.side.map
                state.selectedRoom = state.map and state.map.rooms[1]

                sceneHandler.changeScene("Editor")

            else
                -- TODO - Toast the user
            end
        end
    )
end

function state.saveFile(filename)
    tasks.newTask(
        (-> filename and mapcoder.encodeFile(filename, sideStruct.encode(state.side))),
        function(task)
            if task.result then
                -- Success

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