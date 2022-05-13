local startup = require("initial_startup")
local sceneHandler = require("scene_handler")
local filesystem = require("utils.filesystem")
local threadHandler = require("utils.threads")
local drawing = require("utils.drawing")
local languageRegistry = require("language_registry")
local configs = require("configs")

local startupScene = {}

local drawnOnce = false
local drawnInfo = false
local startedDialog = false

startupScene.name = "Startup"
startupScene._alreadyConfigured = false
startupScene._performedGameScan = false
startupScene._dialogChannel = nil
startupScene._dialogThread = nil
startupScene._nextScene = "Loading"
startupScene._messageKey = filesystem.supportWindowsInThreads and "threads_supported" or "threads_not_supported"

-- Save the path to config and then change to the loading scene
local function saveGotoLoading(path)
    startup.savePath(path)

    startupScene._alreadyConfigured = true

    if startupScene._dialogThread and startupScene._dialogThread:isRunning() then
        threadHandler.release(startupScene._dialogChannel)
    end

    sceneHandler.changeScene(startupScene._nextScene)
end

local function checkDialog(path)
    if not path then
        love.window.close()

        return
    end

    local cleanPath = startup.cleanupPath(path)

    if startup.verifyCelesteDir(cleanPath) then
        saveGotoLoading(cleanPath)

    else
        if drawnInfo then
            startupScene._dialogChannel, startupScene._dialogThread = filesystem.openDialog(nil, nil, checkDialog)
            startedDialog = true
        end
    end
end

function startupScene:firstEnter()
    -- Load language file for all other scenes
    languageRegistry.loadInternalFiles()
    languageRegistry.setLanguage(configs.general.language)

    -- Skip this scene if Celeste directory is already configured
    if not startup.requiresInit() then
        self._alreadyConfigured = true

        sceneHandler.changeScene(self._nextScene)

        return
    end

    local language = languageRegistry.getLanguage()

    self._message = tostring(language.scenes.startup[self._messageKey])
end

function startupScene:filedropped(file)
    local cleanPath = startup.cleanupPath(file:getFilename())

    if startup.verifyCelesteDir(cleanPath) then
        saveGotoLoading(cleanPath)
    end
end

function startupScene:directorydropped(path)
    local cleanPath = startup.cleanupDirPath(path)

    if startup.verifyCelesteDir(cleanPath) then
        saveGotoLoading(cleanPath)
    end
end

function startupScene:draw()
    if not self._alreadyConfigured and self._performedGameScan then
        drawing.callKeepOriginalColor(function()
            drawnInfo = true

            drawing.printCenteredText(self._message, 0, 0, love.graphics.getWidth(), love.graphics.getHeight(), love.graphics.getFont(), 4)
        end)
    end

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

        self._performedGameScan = true
    end
end

return startupScene