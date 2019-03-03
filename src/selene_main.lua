-- love.load() is not called again, put stuff here.

local utils = require("utils")
local serialization = require("serialization")

local mapcoder = require("mapcoder")
local celesteRender = require("celeste_render")

love.window.setTitle("Lönn Demo")

local mapFile = "E:/Games/Celeste/Content/Maps/0-Intro.bin"
local map = mapcoder.decodeFile(mapFile)

function love.draw()
    love.graphics.print("FPS " .. tostring(love.timer.getFPS()), 20, 40)

    celesteRender.drawMap(map)
end