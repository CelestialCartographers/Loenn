require("lua_setup")

local launchArguments = require("launch_arguments")

-- Set up launch argument parsing
launchArguments.updateArguments(arg)

local meta = require("meta")
local configs = require("configs")
local persistence = require("persistence")

local function getWindowSize()
    local width, height = 1280, 720

    if configs.general.persistWindowSize then
        width = persistence.windowWidth or width
        height = persistence.windowHeight or height
    end

    return width, height
end

local function getWindowFullscreen()
    local fullscreen, fullscreenType = false, "desktop"

    if configs.general.persistWindowFullscreen then
        fullscreen = persistence.windowFullscreen or fullscreen
        fullscreenType = persistence.windowFullscreenType or fullscreenType
    end

    return fullscreen, fullscreenType
end

local function getWindowPosition()
    local x, y

    if configs.general.persistWindowPosition then
        x, y = persistence.windowX, persistence.windowY
    end

    return x, y
end

local function getWindowDisplay()
    local index = 1

    if configs.general.persistWindowPosition then
        index = persistence.windowDisplay
    end

    return index
end

function love.conf(t)
    local width, height = getWindowSize()
    local fullscreen, fullscreenType = getWindowFullscreen()
    local windowX, windowY = getWindowPosition()
    local windowDisplay = getWindowDisplay()

    t.console = true
    t.version = "11.0"

    t.window.resizable = true

    t.window.minwidth = math.min(1080, width)
    t.window.width = width
    t.window.minheight = math.min(720, height)
    t.window.height = height

    t.window.fullscreen = fullscreen
    t.window.fullscreentype = fullscreenType

    t.window.x = windowX
    t.window.y = windowY
    t.window.display = windowDisplay

    t.window.title = meta.title
    t.window.icon = "assets/logo-256.png"

    t.window.vsync = configs.graphics.vsync

    -- Not used
    t.modules.audio = false
    t.modules.physics = false
    t.modules.sound = false
    t.modules.video = false
end