local viewportHandler = require("viewport_handler")
local tasks = require("task")
local mapcoder = require("mapcoder")
local celesteRender = require("celeste_render")
local sceneHandler = require("scene_handler")
local filesystem = require("filesystem")
local fileLocations = require("file_locations")

local sideStruct = require("structs.side")

local state = {}

-- TODO - Check for changes and warn users when we aren't just a map viewer
-- TODO - Make and use a tasked version of sideStruct decode
function state.loadFile(filename)
    if not filename then
        return
    end

    sceneHandler.changeScene("Loading")

    tasks.newTask(
        (-> filename and mapcoder.decodeFile(filename)),
        function(binTask)
            if binTask.result then
                tasks.newTask(
                    (-> sideStruct.decodeTaskable(binTask.result)),
                    function(decodeTask)
                        celesteRender.invalidateRoomCache()
                        celesteRender.clearBatchingTasks()

                        state.filename = filename
                        state.side = decodeTask.result
                        state.map = state.side.map
                        state.selectedRoom = state.map and state.map.rooms[1]

                        sceneHandler.changeScene("Editor")
                    end
                )

            else
                sceneHandler.changeScene("Editor")

                -- TODO - Toast the user, failed to load
            end
        end
    )
end

-- TODO - Make and use a tasked version of sideStruct encode
function state.saveFile(filename)
    if filename and state.side then
        tasks.newTask(
            (-> sideStruct.encodeTaskable(state.side)),
            function(encodeTask)
                if encodeTask.result then
                    tasks.newTask(
                        (-> mapcoder.encodeFile(filename, encodeTask.result)),
                        function(binTask)
                            if binTask.done and binTask.success then
                                state.filename = filename

                            else
                                -- TODO - Toast the user, failed to save
                            end
                        end
                    )

                else
                    -- TODO - Toast the user, failed to save
                end
            end
        )
    end
end

function state.selectRoom(room)
    state.selectedRoom = room
end

function state.getSelectedRoom()
    return state.selectedRoom
end

function state.openMap()
    filesystem.openDialog(fileLocations.getCelesteDir(), nil, state.loadFile)
end

function state.saveAsCurrentMap()
    if state.side then
        filesystem.saveDialog(state.filename, nil, state.saveFile)
    end
end

function state.saveCurrentMap()
    if state.side then
        if state.filename then
            state.saveFile(state.filename)

        else
            state.saveAsCurrentMap()
        end
    end
end

-- The currently loaded map
state.map = nil

-- The currently selected room
state.selectedRoom = nil

-- The viewport for the map renderer
state.viewport = viewportHandler.viewport

return state