-- love.load() is not called again, put stuff here.

love.window.setTitle("Lönn Demo")
love.keyboard.setKeyRepeat(true)
love.graphics.setDefaultFilter("nearest", "nearest", 1)

local mapcoder = require("mapcoder")
local celesteRender = require("celeste_render")
local inputHandler = require("input_handler")
local viewportHandler = require("viewport_handler")

viewportHandler.addDevice()

local mapFile = "E:/Games/Celeste/Content/Maps/0-Intro.bin"
local map = mapcoder.decodeFile(mapFile)

function love.draw()
    local viewport = viewportHandler.getViewport()

    celesteRender.drawMap(map)

    love.graphics.print("FPS " .. tostring(love.timer.getFPS()), 20, 40)
    love.graphics.print("Viewport " .. tostring(viewport.x) .. ", " .. tostring(viewport.y) .. ", " .. tostring(viewport.scale), 20, 60)
end