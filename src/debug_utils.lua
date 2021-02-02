local entities = require("entities")
local triggers = require("triggers")
local celesteRender = require("celeste_render")
local toolHandler = require("tool_handler")
local sceneHandler = require("scene_handler")
local languageRegistry = require("language_registry")
local tasks = require("task")
local utils = require("utils")

local hasProfile, profile = utils.tryrequire("profile.profile", false)
local origYield = coroutine.yield

local debugUtils = {}

function debugUtils.reloadEntities()
    print("! Reloading entities")

    entities.initDefaultRegistry()

    entities.loadInternalEntities()
    entities.loadExternalEntities()
end

function debugUtils.reloadTriggers()
    print("! Reloading triggers")

    triggers.initDefaultRegistry()

    triggers.loadInternalTriggers()
    triggers.loadExternalTriggers()
end

function debugUtils.reloadTools()
    print("! Reloading tools")

    toolHandler.unloadTools()

    toolHandler.loadInternalTools()
    toolHandler.loadExternalTools()
end

function debugUtils.reloadScenes()
    print("! Reloading scenes")

    local scene = sceneHandler.getCurrentScene()

    sceneHandler.clearLoadedScenes()

    sceneHandler.loadInternalScenes()
    sceneHandler.loadExternalScenes()

    if scene then
        sceneHandler.changeScene(scene.name)
    end
end

function debugUtils.reloadLanguageFiles()
    print("! Reloading language files")

    languageRegistry.unloadFiles()

    languageRegistry.loadInternalFiles()
    languageRegistry.loadExternalFiles()
end

function debugUtils.reloadUI()
    -- Unimplemented
    -- UI branch can choose to change this function
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
    debugUtils.reloadTriggers()
    debugUtils.reloadTools()
    debugUtils.reloadScenes()
    debugUtils.redrawMap()
    debugUtils.reloadUI()
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
    local rounds = options.rounds or 1

    if not yieldsAlreadyDisabled and (options.disableYields or options.disableYields == nil) then
        debugUtils.disableYields()
    end


    local res

    profile.reset()
    profile.start()


    for i = 1, rounds do
        res = f(...)
    end

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