local editorScene = {}

local configs = require("configs")

editorScene.name = "Editor"

editorScene._displayWipe = true

function editorScene:firstEnter()
    self.viewerState = require("loaded_state")
    self.celesteRender = require("celeste_render")
    self.fonts = require("fonts")

    local inputDevice = require("input_device")
    local standardHotkeys = require("standard_hotkeys")

    local viewportHandler = require("viewport_handler")
    local hotkeyHandler = require("hotkey_handler")
    local userInterfaceDevice = require("ui.ui_device")
    local mapLoaderDevice = require("input_devices.map_loader")
    local roomResizeDevice = require("input_devices.room_resizer")
    local toolHandlerDevice = require("input_devices.tool_device")
    local quitHandlerDevice = require("input_devices.prevent_quit")

    inputDevice.newInputDevice(self.inputDevices, userInterfaceDevice)
    inputDevice.newInputDevice(self.inputDevices, viewportHandler.device)
    inputDevice.newInputDevice(self.inputDevices, hotkeyHandler.createHotkeyDevice(standardHotkeys))
    inputDevice.newInputDevice(self.inputDevices, mapLoaderDevice)
    inputDevice.newInputDevice(self.inputDevices, roomResizeDevice)
    inputDevice.newInputDevice(self.inputDevices, toolHandlerDevice)
    inputDevice.newInputDevice(self.inputDevices, quitHandlerDevice)
end

function editorScene:draw()
    if self.viewerState.map then
        love.graphics.setLineWidth(1)
        self.celesteRender.drawMap(self.viewerState)

        if configs.editor.displayFPS then
            love.graphics.printf("FPS: " .. tostring(love.timer.getFPS()), 20, 40, self.viewerState.viewport.width, "left", 0, self.fonts.fontScale, self.fonts.fontScale)
        end
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