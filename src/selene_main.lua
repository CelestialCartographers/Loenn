-- love.load() is not called again, put stuff here.

local meta = require("meta")

love.window.setTitle(meta.title)

love.keyboard.setKeyRepeat(true)

love.graphics.setDefaultFilter("nearest", "nearest", 1)
love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

local fonts = require("fonts")
love.graphics.setFont(fonts.font)

local sceneHandler = require("scene_handler")
local threadHandler = require("thread_handler")

local tasks = require("task")

require("love_filesystem_unsandboxing")
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
end

function love.quit()
    sceneHandler.quit()
end