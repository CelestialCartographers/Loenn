local startup = require("initial_startup")
local sceneHandler = require("scene_handler")
local filesystem = require("filesystem")
local threadHandler = require("thread_handler")
local drawing = require("drawing")

local startupScene = {}

local drawnOnce = false
local startedDialog = false

local messageThreadsSupported = [[
Please select Celeste.exe in the dialog or drag the file into the window.
If you drag Celeste.exe in you will to manually close the dialog.
]]

local messageThreadsNotSupported = [[
Please select Celeste.exe or Celeste.app in the dialog.
]]

startupScene.name = "Startup"
startupScene._dialogChannel, startupScene._dialogThread = nil
startupScene._nextScene = "Loading"
startupScene._message = filesystem.supportWindowsInThreads and messageThreadsSupported or messageThreadsNotSupported

-- Save the path to config and then change to the loading scene
local function saveGotoLoading(path)
    startup.savePath(path)

    if startupScene._dialogThread and startupScene._dialogThread:isRunning() then
        threadHandler.release(startupScene._dialogChannel)
    end

    sceneHandler.changeScene(startupScene._nextScene)
end

local function checkDialog(path)
    if startupScene._dialogThread and path == false then
        love.window.close()

        return
    end

    if startup.verifyCelesteDir(path) then
        saveGotoLoading(path)

    else
        startupScene._dialogChannel, startupScene._dialogThread = filesystem.openDialog(nil, nil, checkDialog)
    end
end

function startupScene:firstEnter()
    if not startup.requiresInit() then
        sceneHandler.changeScene(startupScene._nextScene)
    end
end

function startupScene:filedropped(file)
    if startup.verifyCelesteDir(file:getFilename()) then
        saveGotoLoading(file:getFilename())
    end
end

function startupScene:directorydropped(path)
    if startup.verifyCelesteDir(path) then
        saveGotoLoading(path)
    end
end

function startupScene:draw()
    local r, g, b, a = love.graphics.getColor()

    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    drawing.printCenteredText(startupScene._message, 0, 0, love.graphics.getWidth(), love.graphics.getHeight(), love.graphics.getFont(), 4)
    love.graphics.setColor(r, g, b, a)

    drawnOnce = true
end

function startupScene:update(dt)
    if drawnOnce and not startedDialog then
        local found, path = startup.findCelesteDirectory()

        if found and startup.verifyCelesteDir(path) then
            saveGotoLoading(path)

        else
            checkDialog(path)
        end

        startedDialog = true
    end
end

return startupScene