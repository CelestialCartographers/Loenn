-- love.load() is not called again, put stuff here.

local meta = require("meta")

love.window.setTitle(meta.title)

love.keyboard.setKeyRepeat(true)

love.graphics.setDefaultFilter("nearest", "nearest", 1)
love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

-- Set up configs for first run
local startup = require("initial_startup")
startup:init()

local inputHandler = require("input_handler")
require("love_filesystem_unsandboxing")

local utils = require("utils")
local celesteRender = require("celeste_render")
local fileLocations = require("file_locations")
local fonts = require("fonts")
local loading = require("loading")
local tasks = require("task")
local entities = require("entities")
local viewerState = require("loaded_state")
local viewportHandler = require("viewport_handler")
local hotkeyHandler = require("hotkey_handler")
local standardHotkeys = require("standard_hotkeys")
local configs = require("configs")

local inputDevice = require("input_device")
local mapLoaderDevice = require("input_devices/map_loader")
local toolHandlerDevice = require("input_devices/tool_device")
local toolHandler = require("tool_handler")

inputDevice.newInputDevice(viewportHandler.device)
inputDevice.newInputDevice(hotkeyHandler.createHotkeyDevice(standardHotkeys))

inputDevice.newInputDevice(mapLoaderDevice)
inputDevice.newInputDevice(toolHandlerDevice)

love.graphics.setFont(fonts.font)

-- Load internal modules such as tools/entities/triggers etc
tasks.newTask(
    function()
        entities.loadInternalEntities()
        toolHandler.loadInternalTools()
    end
)

local mapFile = utils.joinpath(fileLocations.getCelesteDir(), "Content", "Maps", "7-Summit.bin")

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

    inputHandler.draw()
end

function love.update(dt)
    tasks.processTasks(1 / 144)
    inputHandler.update(dt)
    
    if viewerState.map then
        -- TODO - Find some sane values for this
        celesteRender.processTasks(viewerState, 1 / 60, math.huge, 1 / 240, math.huge)

    else
        loading:update(dt)
    end
end