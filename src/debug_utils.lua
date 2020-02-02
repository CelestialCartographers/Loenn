local entities = require("entities")
local celesteRender = require("celeste_render")
local toolHandler = require("tool_handler")
local sceneHandler = require("scene_handler")
local tasks = require("task")
local utils = require("utils")

local hasProfile, profile = utils.tryrequire("profile.profile", false)
local origYield = coroutine.yield

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
        scene._firstEnter = nil
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

function debugUtils.disableYields()
    coroutine.yield = function() end
    tasks.yield = coroutine.yield
end

function debugUtils.enableYields()
    coroutine.yield = origYield
    tasks.yield = coroutine.yield
end

function debugUtils.profile(f, options, ...)
    if not hasProfile then
        return "Profile library not available"
    end

    options = options or {}

    local yieldsAlreadyDisabled = coroutine.yield ~= origYield

    if not yieldsAlreadyDisabled and (options.disableYields or options.disableYields == nil) then
        debugUtils.disableYields()
    end

    profile.reset()
    profile.start()

    local res = f(...)

    profile.stop()

    if not yieldsAlreadyDisabled and (options.disableYields or options.disableYields == nil) then
        debugUtils.enableYields()
    end

    local report = profile.report(options.rows or 50)

    if options.filename then
        local fh = io.open(options.filename, "wb")

        if fh then
            fh:write(report)
            fh:close()
        end
    end

    return report, res
end

function debugUtils.timeIt(f, options, ...)
    options = options or {}

    local start = love.timer.getTime()
    local rounds = options.rounds or 1000 

    for i = 1, rounds do
        f(...)
    end

    local timeTaken = love.timer.getTime() - start

    return timeTaken, timeTaken / rounds
end

return debugUtils