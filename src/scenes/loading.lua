local fonts = require("fonts")
local utils = require("utils")

local loadingScene = {}

loadingScene.name = "Loading"

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

    self.text = "Loading"
    self.alignment = "left"
    self.textScale = fonts.fontScale * 2
    self.textOffsetX = (fonts.font:getWidth(self.text .. "..") * self.textScale) / 2
    self.textOffsetY = self.quadSize / 2
end

function loadingScene:firstEnter()
    local tasks = require("task")

    local entities = require("entities")
    local atlases = require("atlases")
    local toolHandler = require("tool_handler")

    local fileLocations = require("file_locations")
    local viewerState = require("loaded_state")

    -- Load internal modules such as tools/entities/triggers etc
    tasks.newTask(
        function()
            entities.loadInternalEntities()
            toolHandler.loadInternalTools()
        end
    )

    atlases.initCelesteAtlasesTask()

    local mapFile = utils.joinpath(fileLocations.getCelesteDir(), "Content", "Maps", "7-Summit.bin")
    viewerState.loadFile(mapFile)
end

function loadingScene:draw()
    local windowWidth, windowHeight = love.graphics.getWidth(), love.graphics.getHeight()

    local currentQuad = utils.mod1(math.floor(self.currentTime / self.duration * #self.quads) + 1, #self.quads)
    local dots = string.rep(".", currentQuad - 1)

    love.graphics.printf(self.text .. dots, windowWidth / 2 - self.textOffsetX, windowHeight / 2 + self.textOffsetY, windowWidth, self.alignment, 0, self.textScale)
    love.graphics.draw(self.spriteSheet, self.quads[currentQuad], (windowWidth - self.quadSize) / 2, (windowHeight - self.quadSize) / 2, 0, 1)
end

function loadingScene:update(dt)
    self.currentTime = self.currentTime + dt
    if self.currentTime >= self.duration then
        self.currentTime = self.currentTime - self.duration
    end
end

return loadingScene