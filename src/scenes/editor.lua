local editorScene = {}

editorScene.name = "Editor"

editorScene._displayWipe = true

function editorScene:firstEnter()
    self.viewerState = require("loaded_state")
    self.celesteRender = require("celeste_render")
    self.fonts = require("fonts")

    local inputDevice = require("input_device")
    local standardHotkeys = require("standard_hotkeys")

    local ui = require("ui")
    local uie = require("ui.elements")
    local uiu = require("ui.utils")

    --[[
    uiu.hook(uie.__label.__default, {
        calcWidth = (orig, ... -> orig(...) * 3),
        calcHeight = (orig, ... -> orig(...) * 3),

        draw = function(orig, self, ...)
            love.graphics.setColor(self.style.color)
            love.graphics.draw(self._text, self.screenX, self.screenY, 0, 3, 3)
        end,
    })
    --]]
    uie.__label.__default.style.font = love.graphics.newFont(16)

    local root = uie.group({
        uie.row():with({
            style = {
                focusedBG = { 0.4, 0.4, 0.4, 0.25 },
                unfocusedBG = { 0.2, 0.2, 0.2, 0.3 }
            },
            onDrag = uiu.nop,
            root = true
        }):with(uiu.fillWidth),

        uie.window("Windowception",
            uie.scrollbox(
                uie.group({
                    uie.window("Child 1", uie.column({ uie.label("Oh no") })):with({ x = 10, y = 10}),
                    uie.window("Child 2", uie.column({ uie.label("Oh no two") })):with({ x = 30, y = 30})
                }):with({ width = 200, height = 400 })
            ):with({ width = 200, height = 200 })
        ):with({ x = 50, y = 100 }),

        uie.window("Hello, World!",
            uie.column({
                uie.label("This is a one-line label."),
                
                -- Labels use Löve2D Text objects under the hood.
                uie.label({ { 1, 1, 1 }, "This is a ", { 1, 0, 0 }, "colored", { 0, 1, 1 }, " label."}),

                -- Multi-line labels aren't subjected to the parent element's spacing property.
                uie.label("This is a two-line label.\nThe following label is updated dynamically."),

                -- Dynamically updated label.
                uie.label():as("info"),

                uie.button("This is a button.", function(btn)
                    if btn.counter == nil then
                        btn.counter = 0
                    end
                    btn.counter = btn.counter + 1
                    btn.text = "Pressed " .. tostring(btn.counter) .. " time" .. (btn.counter == 1 and "" or "s")
                end),

                uie.button("Disabled"):with({ enabled = false }),

                uie.button("Useless"),

                uie.label("Select an item from the list below."):as("selected"),
                uie.list(uiu.map(uiu.listRange(1, 3), function(i)
                    return { text = string.format("Item %i!", i), data = i }
                end), function(list, item)
                    list.parent._selected.text = "Selected " .. tostring(item)
                end)

            })
        ):with({ x = 200, y = 50 }):as("test"),
    }):with({
        style = {
            bg = { bg = {} },
            padding = 0,
            spacing = 0,
            radius = 0
        },
        clip = false,
        cacheable = false
    })
    
    ui.init(root, false)
    inputDevice.newInputDevice(self.inputDevices, ui)

    self.ui = ui

    local viewportHandler = require("viewport_handler")
    local hotkeyHandler = require("hotkey_handler")
    local mapLoaderDevice = require("input_devices.map_loader")
    local toolHandlerDevice = require("input_devices.tool_device")

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