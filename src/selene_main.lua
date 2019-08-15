-- love.load() is not called again, put stuff here.

local meta = require("meta")

love.window.setTitle(meta.title)

love.keyboard.setKeyRepeat(true)

love.graphics.setDefaultFilter("nearest", "nearest", 1)
love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

-- Set up configs for first run
local startup = require("initial_startup")
startup:init()

local sceneHandler = require("scene_handler")
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
local atlases = require("atlases")

local inputDevice = require("input_device")
local mapLoaderDevice = require("input_devices/map_loader")
local toolHandlerDevice = require("input_devices/tool_device")
local toolHandler = require("tool_handler")


sceneHandler.loadInternalScenes()
sceneHandler.changeScene("Loading")

love.graphics.setFont(fonts.font)

-- Load internal modules such as tools/entities/triggers etc
tasks.newTask(
    function()
        entities.loadInternalEntities()
        toolHandler.loadInternalTools()
    end
)

atlases.initCelesteAtlasesTask()

local mapFile = utils.joinpath(fileLocations.getCelesteDir(), "Content", "Maps", "7-Summit.bin")
viewerState.loadMap(mapFile)

function love.draw()
    sceneHandler.sendEvent("draw")
end

function love.update(dt)
    tasks.processTasks(1 / 16)

    sceneHandler.sendEvent("update", dt)
end