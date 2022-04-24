local editorScene = {}

local config = require("utils.config")
local persistence = require("persistence")
local configs = require("configs")
local mods = require("mods")
local history = require("history")
local sceneHandler = require("scene_handler")
local drawing = require("utils.drawing")
local languageRegistry = require("language_registry")

editorScene.name = "Editor"

editorScene._displayWipe = true

local function checkForUncleanStartup()
    -- Program didn't close down as expected
    -- Could be a hard crash or killed process
    if persistence.currentlyRunning then
        sceneHandler.sendEvent("editorUncleanStartup")
    end
end

local function updateRunningStatus(status)
    persistence.currentlyRunning = status

    config.writeConfig(persistence, true)
end

function editorScene:enter()
    local viewportHandler = require("viewport_handler")

    viewportHandler.updateSize()

    self:propagateEvent("enter")
end

function editorScene:firstEnter()
    self.viewerState = require("loaded_state")
    self.celesteRender = require("celeste_render")
    self.fonts = require("fonts")

    local backups = require("backups")
    local inputDevice = require("input_device")
    local standardHotkeys = require("standard_hotkeys")
    local updater = require("updater")
    local hotkeyHandler = require("hotkey_handler")

    local viewportHandler = require("viewport_handler")
    local hotkeyDevice = hotkeyHandler.createHotkeyDevice(standardHotkeys)
    local backupDevice = backups.createBackupDevice()
    local userInterfaceDevice = require("ui.ui_device")
    local mapLoaderDevice = require("input_devices.map_loader")
    local roomResizeDevice = require("input_devices.room_resizer")
    local toolHandlerDevice = require("input_devices.tool_device")
    local windowDataDevice = require("input_devices.window_persister")
    local graphicsDevice = require("input_devices.graphics_device")

    inputDevice.newInputDevice(self.inputDevices, userInterfaceDevice)
    inputDevice.newInputDevice(self.inputDevices, viewportHandler.device)
    inputDevice.newInputDevice(self.inputDevices, hotkeyDevice)
    inputDevice.newInputDevice(self.inputDevices, backupDevice)
    inputDevice.newInputDevice(self.inputDevices, mapLoaderDevice)
    inputDevice.newInputDevice(self.inputDevices, roomResizeDevice)
    inputDevice.newInputDevice(self.inputDevices, toolHandlerDevice)
    inputDevice.newInputDevice(self.inputDevices, windowDataDevice)
    inputDevice.newInputDevice(self.inputDevices, graphicsDevice)

    updater.startupUpdateCheck()
    checkForUncleanStartup()
    updateRunningStatus(true)
end

function editorScene:quit()
    if history.madeChanges then
        sceneHandler.sendEvent("editorQuitWithChanges")

        return true
    end

    updateRunningStatus(false)
    mods.writeModPersistences()
end

function editorScene:draw()
    if self.viewerState.map then
        love.graphics.setLineWidth(1)
        self.celesteRender.drawMap(self.viewerState)

        if configs.editor.displayFPS then
            love.graphics.printf("FPS: " .. tostring(love.timer.getFPS()), 20, 40, self.viewerState.viewport.width, "left", 0, self.fonts.fontScale, self.fonts.fontScale)
        end

    else
        local windowWidth, windowHeight = self.viewerState.viewport.width, self.viewerState.viewport.height
        local language = languageRegistry.getLanguage()
        local message = tostring(language.scenes.editor.no_map_loaded)

        drawing.printCenteredText(message, 0, 0, windowWidth, windowHeight, self.fonts.font, self.fonts.fontScale * 2)
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

function editorScene:editorMapTargetChanged(item, itemType, previousItem, previousItemType)
    if previousItemType == "room" then
        -- Create a new canvas for the previous selected room and rerender it instantly
        -- If we let it be lazily rerendered it will cause flashes after a few frames
        -- Should not be done if the map target changed because of deletion, check that previous item exists still

        local map = self.viewerState.map
        local shouldForceRedraw = false

        if map and map.rooms then
            for _, room in ipairs(map.rooms) do
                if room.name == previousItem.name then
                    shouldForceRedraw = true
                end
            end
        end

        if shouldForceRedraw then
            self.celesteRender.forceRedrawRoom(previousItem, self.viewerState.viewport, false)
        end
    end

    self:propagateEvent("editorMapTargetChanged", item, itemType, previousItem, previousItemType)
end

return editorScene