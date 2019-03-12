-- love.load() is not called again, put stuff here.

love.window.setTitle("Lönn Demo")

love.keyboard.setKeyRepeat(true)

love.graphics.setDefaultFilter("nearest", "nearest", 1)
love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

require("input_handler")

local celesteRender = require("celeste_render")
local fileLocations = require("file_locations")
local fonts = require("fonts")
local tasks = require("task")
local entities = require("entities")
local viewerState = require("loaded_state")
local viewportHandler = require("viewport_handler")

local inputDevice = require("input_device")
local mapLoaderDevice = require("input_devices/map_loader")

inputDevice.newInputDevice(viewportHandler.device)
inputDevice.newInputDevice(mapLoaderDevice)

love.graphics.setFont(fonts.font)

-- TODO - Make task "group" for loading things

tasks.newTask(
    function()
        entities.loadInternalEntities()
    end
)

local mapFile = fileLocations.getResourceDir() .. "/Maps/7-Summit.bin"

viewerState.loadMap(mapFile)

function love.draw()
    local viewport = viewerState.viewport

    if viewerState.map then
        celesteRender.drawMap(viewerState)

        love.graphics.printf("FPS: " .. tostring(love.timer.getFPS()), 20, 40, viewport.width, "left", 0, fonts.fontScale, fonts.fontScale)

    else
        love.graphics.printf("Loading...", viewport.width / 2, viewport.height / 2, viewport.width, "left", love.timer.getTime(), fonts.fontScale * 2, fonts.fontScale * 2)
    end
end

function love.update()
    if viewerState.map then
        tasks.processTasks(math.huge, 1)

    else
        tasks.processTasks(1 / 144)
    end
end