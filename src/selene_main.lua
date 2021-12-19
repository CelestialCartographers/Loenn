-- love.load() is not called again, put stuff here.

local logging = require("logging")
local meta = require("meta")

love.window.setTitle(meta.title)

love.keyboard.setKeyRepeat(true)

love.graphics.setDefaultFilter("nearest", "nearest", 1)
love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

local fonts = require("fonts")
love.graphics.setFont(fonts.font)

local sceneHandler = require("scene_handler")
local threadHandler = require("utils.threads")

local tasks = require("utils.tasks")

require("lib.love_filesystem_unsandboxing")
require("input_handler")

sceneHandler.loadInternalScenes()
sceneHandler.changeScene("Startup")

function love.draw()
    sceneHandler.draw()
end

function love.update(dt)
    tasks.processTasks(1 / 32)

    sceneHandler.update(dt)
    threadHandler.update(dt)
    logging.update(dt)
end

local originalErrorHandler = love.errorhandler or love.errhand

function love.errorhandler(message)
    logging.error(debug.traceback(message))

    return originalErrorHandler(message)
end