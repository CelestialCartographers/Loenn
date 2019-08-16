local theme = require("giraffe.theme")

local window = {}

window.title = "Window Test!"

window.x = 200
window.y = 200

window.width = 400
window.height = 300

window.theme = {
    window = {
        --background = {0.7, 0.7, 0.7},
        background = love.graphics.newImage("assetsTest/bswallpaper.png"),
        backgroundImageMode = "stretch",

        titleBackground = love.graphics.newImage("assetsTest/hardened_clay_stained_purple.png"),
        titleBackgroundImageMode = "tiling"
    }
}

function window:loaded()
    self.image = love.graphics.newImage("assetsTest/logo-256.png")
end

function window:draw()
    love.graphics.draw(self.image, -20, -20)
    love.graphics.setColor(1.0, 0.7, 0.7)
    love.graphics.print(self._thingActive and "Hello there thing" or "Hello", 20, 256, 0, 4, 4)
end

function window:update(dt)
    --print(self.x, self.y, self.width, self.height, dt)
end

function window:mousepressed(x, y, button, istouch, presses)
    print(self.title, "mousepressed", x, y, button)
end

function window:mousemoved(x, y, dx, dy)
    self._thingActive = x > 20 and x < 100
end

return window