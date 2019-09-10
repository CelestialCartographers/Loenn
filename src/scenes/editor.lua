local utils = require("utils")

local editorScene = {}

editorScene.name = "Editor"

function editorScene:firstEnter()
    local giraffe = require("giraffe")
    local testWindow = require("windows/test_window")

    giraffe.init() -- TODO - Move this out later

    local group = giraffe.group({
        x = 0,
        y = 0,
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
        _enabled = true
    })

    local win1 = utils.deepcopy(testWindow)
    local win2 = utils.deepcopy(testWindow)
    local win3 = utils.deepcopy(testWindow)

    win1.x = 200
    win2.x = 300
    win2.y += 50
    win3.x = 10
    win3.y = 10

    win1.title = "Window 1"
    win2.title = "Window 2"
    win3.title = "Sub Window 1"
    
    win3.width = 100
    win3.height = 100

    -- TODO - Investigate bug with adding widgets after making it a window
    table.insert(win2.widgets, giraffe.window(win3))

    table.insert(group.widgets, giraffe.window(win1))
    table.insert(group.widgets, giraffe.window(win2))


    self.viewerState = require("loaded_state")
    self.celesteRender = require("celeste_render")
    self.fonts = require("fonts")

    local inputDevice = require("input_device")
    local standardHotkeys = require("standard_hotkeys")

    local viewportHandler = require("viewport_handler")
    local hotkeyHandler = require("hotkey_handler")
    local mapLoaderDevice = require("input_devices/map_loader")
    local toolHandlerDevice = require("input_devices/tool_device")

    inputDevice.newInputDevice(self.inputDevices, group)
    inputDevice.newInputDevice(self.inputDevices, viewportHandler.device)
    inputDevice.newInputDevice(self.inputDevices, hotkeyHandler.createHotkeyDevice(standardHotkeys))
    inputDevice.newInputDevice(self.inputDevices, mapLoaderDevice)
    inputDevice.newInputDevice(self.inputDevices, toolHandlerDevice)
end

function editorScene:draw()
    if self.viewerState.map then
        self.celesteRender.drawMap(self.viewerState)

        love.graphics.printf("FPS: " .. tostring(love.timer.getFPS()), 20, 40, self.viewerState.viewport.width, "left", 0, self.fonts.fontScale, self.fonts.fontScale)
        love.graphics.printf("Room: " .. self.viewerState.selectedRoom.name, 20, 80, self.viewerState.viewport.width, "left", 0, self.fonts.fontScale, self.fonts.fontScale)
    end

    self:propagateEvent("draw")
end

function editorScene:update(dt)
    if self.viewerState.map then
        -- TODO - Find some sane values for this
        self.celesteRender.processTasks(self.viewerState, 1 / 60, math.huge, 1 / 240, math.huge)
    end

    self:propagateEvent("update", dt)
end

return editorScene