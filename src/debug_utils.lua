local entities = require("entities")
local celesteRender = require("celeste_render")
local toolHandler = require("tool_handler")
local sceneHandler = require("scene_handler")

local debugUtils = {}

-- TODO - Reload external entities when supported in entities.lua
function debugUtils.reloadEntities()
    print("! Reloading entities")

    entities.initDefaultRegistry()
    entities.loadInternalEntities()
end

function debugUtils.reloadTools()
    print("! Reloading tools")

    toolHandler.currentTool = nil
    toolHandler.currentToolName = nil

    toolHandler.loadInternalTools()
end

function debugUtils.reloadScenes()
    print("! Reloading scenes")

    local scene = sceneHandler.getCurrentScene()

    sceneHandler.loadInternalScenes()

    if scene then
        sceneHandler.currentScene = nil
        scene:exit()
        sceneHandler.changeScene(scene.name)
    end
end

function debugUtils.redrawMap()
    print("! Redrawing map")

    celesteRender.invalidateRoomCache()
    celesteRender.clearBatchingTasks()
end

-- TODO - Add as more hotswapping becomes available
function debugUtils.reloadEverything()
    print("! Reloading everything")

    debugUtils.reloadEntities()
    debugUtils.reloadTools()
    debugUtils.reloadScenes()
    debugUtils.redrawMap()
end

function debugUtils.debug()
    debug.debug()
end

return debugUtils