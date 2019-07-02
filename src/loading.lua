local fonts = require("fonts")
local utils = require("utils")

local loading = {}

loading.spriteSheet = love.graphics.newImage("assets/loading-256.png")
loading.quadSize = 256
loading.quads = {}
 
for y = 0, loading.spriteSheet:getHeight() - loading.quadSize, loading.quadSize do
    for x = 0, loading.spriteSheet:getWidth() - loading.quadSize, loading.quadSize do
        table.insert(loading.quads, love.graphics.newQuad(x, y, loading.quadSize, loading.quadSize, loading.spriteSheet:getDimensions()))
    end
end
 
loading.duration = 1
loading.currentTime = 0

loading.text = "Loading"
loading.alignment = "left"
loading.textScale = fonts.fontScale * 2
loading.textOffsetX = (fonts.font:getWidth(loading.text .. "..") * loading.textScale) / 2
loading.textOffsetY = loading.quadSize / 2

function loading:drawLoadScreen(viewport)
    local currentQuad = utils.mod1(math.floor(self.currentTime / self.duration * #self.quads) + 1, #self.quads)

    local dots = string.rep(".", currentQuad - 1)

    love.graphics.printf(loading.text .. dots, viewport.width / 2 - loading.textOffsetX, viewport.height / 2 + loading.textOffsetY, viewport.width, loading.alignment, 0, loading.textScale)
    love.graphics.draw(self.spriteSheet, self.quads[currentQuad], (viewport.width - self.quadSize) / 2, (viewport.height - self.quadSize) / 2, 0, 1)
end

function loading:update(dt)
    self.currentTime = self.currentTime + dt
    if self.currentTime >= self.duration then
        self.currentTime = self.currentTime - self.duration
    end
end

return loading