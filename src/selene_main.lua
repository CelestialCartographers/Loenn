-- love.load() is not called again, put stuff here.

love.window.setTitle("Lönn Demo")

love.keyboard.setKeyRepeat(true)

love.graphics.setDefaultFilter("nearest", "nearest", 1)
love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

require("input_handler")
require("filesystem_mount_workaround")

local celesteRender = require("celeste_render")
local fileLocations = require("file_locations")
local fonts = require("fonts")
local loading = require("loading")
local tasks = require("task")
local entities = require("entities")
local viewerState = require("loaded_state")
local viewportHandler = require("viewport_handler")

local inputDevice = require("input_device")
local mapLoaderDevice = require("input_devices/map_loader")
local toolHandlerDevice = require("input_devices/tool_handler")

inputDevice.newInputDevice(viewportHandler.device)

inputDevice.newInputDevice(mapLoaderDevice)
inputDevice.newInputDevice(toolHandlerDevice)

love.graphics.setFont(fonts.font)

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
        love.graphics.printf("Room: " .. viewerState.selectedRoom.name, 20, 80, viewport.width, "left", 0, fonts.fontScale, fonts.fontScale)

    else
        loading:drawLoadScreen(viewport)
    end
end

function love.update(dt)
    tasks.processTasks(1 / 144)
    
    if viewerState.map then
        -- TODO - Find some sane values for this
        celesteRender.processTasks(1 / 20, 20)

    else
        loading:update(dt)
    end
end