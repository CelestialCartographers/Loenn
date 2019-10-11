local sceneStruct = require("structs.scene")
local utils = require("utils")

local sceneHandler = {}

sceneHandler.scenes = {}
sceneHandler.currentScene = nil

sceneHandler.wipeRemaining = 0
sceneHandler.wipeDuration = 0
sceneHandler.wipeRenderedOnce = false
sceneHandler.wipeFinished = false
sceneHandler.defaultWipeDuration = 0.6

function sceneHandler.defaultStencil()
    local p = 1 - sceneHandler.wipeRemaining / sceneHandler.wipeDuration
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()

    local radius = math.sqrt((width / 2)^2 + (height / 2)^2) * p

    love.graphics.circle("fill", width / 2, height / 2, radius)
end

function sceneHandler.defaultWipe(total, remaining, draw)
   love.graphics.stencil(sceneHandler.defaultStencil, "replace")
   love.graphics.setStencilTest("equal", 1)
 
   local res = draw()
 
   love.graphics.setStencilTest()

   return res
end

function sceneHandler.sendEvent(event, ...)
    local args = {...}
    local scene = sceneHandler.getCurrentScene()

    if not scene then
        return false
    end

    scene[event](scene, unpack(args))

    return true
end

function sceneHandler.draw()
    if not sceneHandler.wipeFinished and sceneHandler.getCurrentScene() and sceneHandler.getCurrentScene()._displayWipe then
        sceneHandler.wipeRenderedOnce = true
        sceneHandler.wipeFinished = sceneHandler.wipeRemaining == 0

        return sceneHandler.defaultWipe(sceneHandler.wipeRemaining, sceneHandler.wipeDuration, function() return sceneHandler.sendEvent("draw") end)

    else
        return sceneHandler.sendEvent("draw")
    end
end

function sceneHandler.update(dt)
    if sceneHandler.wipeRenderedOnce then
        sceneHandler.wipeRemaining = math.max(0, sceneHandler.wipeRemaining - dt)
    end

    return sceneHandler.sendEvent("update", dt)
end

-- Use inputsceneMt if no other metatable is already set for the scene
function sceneHandler.addScene(scene)
    local scenes = sceneHandler.scenes

    if utils.typeof(scene) ~= "scene" then
        scene = sceneStruct.create(scene)
    end

    scenes[scene.name] = scene
    scene:loaded()

    return scene
end

function sceneHandler.getScene(name)
    return sceneHandler.scenes[name]
end

function sceneHandler.getCurrentScene()
    return sceneHandler.scenes[sceneHandler.currentScene]
end

function sceneHandler.changeScene(name)
    local prevName = sceneHandler.currentScene

    if prevName == name or not sceneHandler.scenes[name] then
        return false
    end

    local prevScene = sceneHandler.scenes[prevName]
    local newScene = sceneHandler.scenes[name]

    if prevScene then
        prevScene:exit(name)
    end

    sceneHandler.currentScene = name

    if not newScene._firstEnter then
        newScene._firstEnter = true

        newScene:firstEnter(prevName)
    end

    newScene:enter(prevName)

    sceneHandler.wipeDuration = sceneHandler.defaultWipeDuration
    sceneHandler.wipeRemaining = sceneHandler.wipeDuration
    sceneHandler.wipeRenderedOnce = false
    sceneHandler.wipeFinished = false

    return true
end

function sceneHandler.addSceneFromFilename(fn)
    local pathNoExt = utils.stripExtension(fn)
    local filenameNoExt = utils.filename(pathNoExt, "/")

    local handler = utils.rerequire(pathNoExt)
    local name = handler.name or filenameNoExt

    print("! Registered scene '" .. name .. "'")

    sceneHandler.addScene(handler)
end

-- TODO - Santize user paths
function sceneHandler.loadInternalScenes(path)
    path = path or "scenes"

    for i, file <- love.filesystem.getDirectoryItems(path) do
        -- Always use Linux paths here
        sceneHandler.addSceneFromFilename(utils.joinpath(path, file):gsub("\\", "/"))
    end
end

return sceneHandler