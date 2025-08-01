local fonts = require("fonts")
local utils = require("utils")
local languageRegistry = require("language_registry")
local persistence = require("persistence")
local viewportHandler = require("viewport_handler")

local loadingScene = {}

loadingScene.name = "Loading"

function loadingScene:setText(text)
    self.text = tostring(text)
    self.alignment = "left"
    self.textScale = fonts.fontScale * 2
    self.textOffsetX = (fonts.font:getWidth(self.text .. "..") * self.textScale) / 2
    self.textOffsetY = self.quadSize / 2
end

function loadingScene:loaded()
    self.spriteSheet = love.graphics.newImage("assets/loading-256.png")
    self.quadSize = 256
    self.quads = {}

    for y = 0, self.spriteSheet:getHeight() - self.quadSize, self.quadSize do
        for x = 0, self.spriteSheet:getWidth() - self.quadSize, self.quadSize do
            table.insert(self.quads, love.graphics.newQuad(x, y, self.quadSize, self.quadSize, self.spriteSheet:getDimensions()))
        end
    end

    self.duration = 1
    self.currentTime = 0
end

function loadingScene:firstEnter()
    local tasks = require("utils.tasks")

    local sandboxUtils = require("utils.sandbox")
    local language = languageRegistry.getLanguage()

    local sceneHandler = require("scene_handler")
    local toolHandler = require("tools")
    local entities = require("entities")
    local triggers = require("triggers")
    local effects = require("effects")
    local libraries = require("libraries")
    local saveSanitizers = require("save_sanitizers")

    local atlases = require("atlases")

    local configs = require("configs")
    local defaultConfig = require("default_config")
    local mods = require("mods")

    local launchArguments = require("launch_arguments")

    local fileLocations = require("file_locations")
    local viewerState = require("loaded_state")

    local userInterfaceDevice = require("ui.ui_device")

    self:setText(language.scenes.loading.loading)

    -- Microbenchmark to estimate instructions per second
    sandboxUtils.calcIpsAndHookInterval()

    -- Load assets and entity, trigger, effect etc modules
    tasks.newTask(
        function()
            atlases.loadCelesteAtlases()

            mods.mountMods()

            -- Internal scenes are already loaded, how else would we be here
            sceneHandler.loadExternalScenes()

            languageRegistry.loadExternalFiles()
            languageRegistry.setFallbackLanguage(defaultConfig.general.language)

            libraries.loadInternalLibraries()
            libraries.loadExternalLibraries()

            entities.loadInternalEntities()
            entities.loadExternalEntities()

            triggers.loadInternalTriggers()
            triggers.loadExternalTriggers()

            effects.loadInternalEffects()
            effects.loadExternalEffects()

            toolHandler.loadInternalTools()
            toolHandler.loadExternalTools()

            saveSanitizers.loadInternalSanitizers()
            saveSanitizers.loadExternalSanitizers()

            if userInterfaceDevice.initializeDevice then
                userInterfaceDevice.initializeDevice()
            end

            -- This can take a while depending on the amount of installed mods
            -- By default it is lazy loaded
            if not configs.editor.lazyLoadExternalAtlases then
                atlases.loadExternalAtlases()
            end
        end
    )

    local defaultMapFilename = utils.joinpath(fileLocations.getCelesteDir(), "Content", "Maps", "7-Summit.bin")
    local initialFilename = launchArguments.parsed.initialFilename
    local lastMapFilename = persistence.lastLoadedFilename
    local lastRoomName = persistence.lastSelectedRoomName
    local targetFilename = initialFilename or lastMapFilename or defaultMapFilename

    viewerState.loadFile(targetFilename, lastRoomName)
    viewportHandler.cameraFromPersistence()
    viewerState.initFromPersistence()
end

function loadingScene:draw()
    -- Scenes metatable will make this seem like a function, make sure its actually set
    if type(self.text) == "string" then
        local windowWidth, windowHeight = love.graphics.getWidth(), love.graphics.getHeight()

        local currentQuad = utils.mod1(math.floor(self.currentTime / self.duration * #self.quads) + 1, #self.quads)
        local dots = string.rep(".", currentQuad - 1)

        love.graphics.printf(self.text .. dots, windowWidth / 2 - self.textOffsetX, windowHeight / 2 + self.textOffsetY, windowWidth, self.alignment, 0, self.textScale)
        love.graphics.draw(self.spriteSheet, self.quads[currentQuad], (windowWidth - self.quadSize) / 2, (windowHeight - self.quadSize) / 2, 0, 1)
    end
end

function loadingScene:update(dt)
    self.currentTime = self.currentTime + dt
    while self.currentTime >= self.duration do
        self.currentTime = self.currentTime - self.duration
    end
end

return loadingScene