local sceneStruct = require("structs.scene")
local utils = require("utils")

local sceneHandler = {}

sceneHandler.scenes = {}
sceneHandler.currentScene = nil

function sceneHandler.sendEvent(event, ...)
    local args = {...}
    local name = sceneHandler.currentScene
    local scene = sceneHandler.scenes[name]

    if not scene then
        return false
    end

    scene[event](scene, unpack(args))

    return true
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