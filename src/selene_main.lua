-- love.load() is not called again, put stuff here.

love.window.setTitle("Lönn Demo")
love.keyboard.setKeyRepeat(true)
love.graphics.setDefaultFilter("nearest", "nearest", 1)

local mapcoder = require("mapcoder")
local celesteRender = require("celeste_render")
local inputHandler = require("input_handler")
local viewportHandler = require("viewport_handler")
local fileLocations = require("file_locations")
local fonts = require("fonts")
local tasks = require("task")

love.graphics.setFont(fonts.font)

viewportHandler.addDevice()

local mapFile = fileLocations.getResourceDir() .. "/Maps/6-Reflection.bin"
local map = tasks.newTask(function() mapcoder.decodeFile(mapFile) end)

function love.draw()
    local viewport = viewportHandler.getViewport()

    celesteRender.drawMap(map)

    love.graphics.printf("FPS: " .. tostring(love.timer.getFPS()), 20, 40, 1080, "left", 0, fonts.fontScale, fonts.fontScale)
    love.graphics.printf("Viewport: " .. tostring(viewport.x) .. " " .. tostring(viewport.y) .. " " .. tostring(viewport.scale), 20, 80, viewport.width, "left", 0, fonts.fontScale, fonts.fontScale)
end

function love.update()
    -- TODO - Put in saner default
    tasks.processTasks(1 / 200)
end