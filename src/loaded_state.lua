local viewportHandler = require("viewport_handler")
local tasks = require("utils.tasks")
local mapcoder = require("mapcoder")
local celesteRender = require("celeste_render")
local sceneHandler = require("scene_handler")
local filesystem = require("utils.filesystem")
local fileLocations = require("file_locations")
local utils = require("utils")
local history = require("history")
local persistence = require("persistence")
local meta = require("meta")

local sideStruct = require("structs.side")

local state = {}

local function getWindowTitle(side)
    local name = sideStruct.getMapName(side)

    return string.format("%s - %s", meta.title, name)
end

local function updateSideState(side, roomName, filename, eventName)
    eventName = eventName or "editorMapLoaded"

    celesteRender.invalidateRoomCache()
    celesteRender.clearBatchingTasks()

    state.filename = filename
    state.side = side
    state.map = state.side.map

    celesteRender.loadCustomTilesetAutotiler(state)

    history.reset()

    local initialRoom = state.map and state.map.rooms[1]

    if roomName then
        local roomByName = state.getRoomByName(roomName)

        if roomByName then
            initialRoom = roomByName
        end
    end

    state.selectItem(initialRoom)

    persistence.lastLoadedFilename = filename
    persistence.lastSelectedRoomName = state.selectedItem and state.selectedItem.name

    love.window.setTitle(getWindowTitle(side))

    sceneHandler.changeScene("Editor")
    sceneHandler.sendEvent(eventName, filename)
end

-- Updates state filename and flags history with no changes
function state.defaultSaveCallback(filename)
    state.filename = filename
    history.madeChanges = false
end

function state.loadFile(filename, roomName)
    if not filename then
        return
    end

    if history.madeChanges then
        sceneHandler.sendEvent("editorLoadWithChanges", state.filename, filename)

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
                        updateSideState(decodeTask.result, roomName, filename, "editorMapLoaded")
                    end
                )

            else
                sceneHandler.changeScene("Editor")

                sceneHandler.sendEvent("editorMapLoadFailed", filename)
            end
        end
    )
end

function state.saveFile(filename, callback, addExtIfMissing)
    if filename and state.side then
        if addExtIfMissing ~= false and filesystem.fileExtension(filename) ~= "bin" then
            filename ..= ".bin"
        end

        if callback ~= false then
            callback = callback or state.defaultSaveCallback
        end

        filesystem.mkpath(filesystem.dirname(filename))

        tasks.newTask(
            (-> sideStruct.encodeTaskable(state.side)),
            function(encodeTask)
                if encodeTask.result then
                    tasks.newTask(
                        (-> mapcoder.encodeFile(filename, encodeTask.result)),
                        function(binTask)
                            if binTask.done and binTask.success then
                                if callback then
                                    callback(filename)
                                end

                                sceneHandler.sendEvent("editorMapSaved", filename)

                            else
                                sceneHandler.sendEvent("editorMapSaveFailed", filename)
                            end
                        end
                    )

                else
                    sceneHandler.sendEvent("editorMapSaveFailed", filename)
                end
            end
        )
    end
end

function state.selectItem(item, add)
    local itemType = utils.typeof(item)
    local previousItem = state.selectedItem
    local previousItemType = state.selectedItemType

    if itemType == "room" then
        persistence.lastSelectedRoomName = item.name
    end

    if add then
        if state.selectedItemType ~= "table" then
            state.selectedItem = {
                [state.selectedItem] = state.selectedItemType
            }

            state.selectedItemType = "table"
        end

        if not state.selectedItem[item] then
            state.selectedItem[item] = itemType

            sceneHandler.sendEvent("editorMapTargetChanged", state.selectedItem, state.selectedItemType, previousItem, previousItemType, add)
        end

    else
        state.selectedItem = item
        state.selectedItemType = itemType

        sceneHandler.sendEvent("editorMapTargetChanged", state.selectedItem, state.selectedItemType, previousItem, previousItemType, add)
    end
end

function state.getSelectedRoom()
    return state.selectedItemType == "room" and state.selectedItem or false
end

function state.getSelectedFiller()
    return state.selectedItemType == "filler" and state.selectedItem or false
end

function state.getSelectedItem()
    return state.selectedItem, state.selectedItemType
end

function state.isItemSelected(item)
    if state.selectedItem == item then
        return true

    elseif state.selectedItemType == "table" then
        return not not state.selectedItemType[item]
    end

    return false
end

function state.openMap()
    local targetDirectory = fileLocations.getCelesteDir()

    if state.filename and filesystem.isFile(state.filename) then
        targetDirectory = filesystem.dirname(state.filename)
    end

    filesystem.openDialog(targetDirectory, "bin", state.loadFile)
end

function state.newMap()
    if history.madeChanges then
        sceneHandler.sendEvent("editorNewMapWithChanges")

        return
    end

    local newSide = sideStruct.decode({})

    updateSideState(newSide, nil, nil, "editorMapNew")
end

function state.saveAsCurrentMap(callback, addExtIfMissing)
    if state.side then
        filesystem.saveDialog(state.filename, "bin", function(filename)
            state.saveFile(filename, callback, addExtIfMissing)
        end)
    end
end

function state.saveCurrentMap(callback, addExtIfMissing)
    if state.side then
        if state.filename then
            state.saveFile(state.filename, callback, addExtIfMissing)

        else
            state.saveAsCurrentMap(callback, addExtIfMissing)
        end
    end
end

function state.getRoomByName(name)
    local rooms = state.map and state.map.rooms or {}
    local nameWithLvl = "lvl_" .. name

    for i, room in ipairs(rooms) do
        if room.name == name or room.name == nameWithLvl then
            return room, i
        end
    end
end

function state.getLayerVisible(layer)
    local info = state.layerInformation[layer]

    if info then
        if info.visible == nil then
            return true
        end

        return info.visible
    end

    return true
end

function state.setLayerVisible(layer, visible, silent)
    local info = state.layerInformation[layer]

    if not info then
        info = {}
        state.layerInformation[layer] = info
    end

    info.visible = visible

    if silent ~= false then
        -- Clear target canvas and complete cache for all rooms
        celesteRender.invalidateRoomCache(nil, {"canvas", "complete"})

        -- Redraw any visible rooms
        local selectedItem, selectedItemType = state.getSelectedItem()

        celesteRender.clearBatchingTasks()
        celesteRender.forceRedrawVisibleRooms(state.map.rooms, state, selectedItem, selectedItemType)
    end
end

-- The currently loaded map
state.map = nil

-- The currently selected item (room or filler)
state.selectedItem = nil
state.selectedItemType = nil
state.selectedRooms = {}

-- The viewport for the map renderer
state.viewport = viewportHandler.viewport

-- Rendering information about layers
state.layerInformation = {}

return state