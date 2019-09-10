local theme = require("giraffe.theme")
local windowStruct = require("giraffe.window")
local giraffe = require("giraffe")

local window = {}

window.title = "Window Test!"

window.x = 200
window.y = 200

window.width = 400
window.height = 300

window.theme = {
    body = {
        background = love.graphics.newImage("assetsTesting/hardened_clay_stained_light_blue.png"),
        backgroundImageMode = "tiling",
    },
    title = {
        background = love.graphics.newImage("assetsTesting/hardened_clay_stained_purple.png"),
        backgroundImageMode = "tiling"
    }
}

window.widgets = {
    giraffe.button({
        x = 10,
        y = 10,

        width = 100,
        height = 100,

        content = "Foobar", --love.graphics.newImage("assetsTesting/hardened_clay_stained_purple.png"),

        pressed = function(self, x, y)
            print(":O", x, y)
        end,

        update = function(self)
            self.content = self._hovered and "Hi mouse :)" or "Come back D:"
        end,

        resize = function(self, width, height)
            self.width = width / 2
            self:updateRectangle()
        end
    }),
    giraffe.button({
        x = 10,
        y = 120,

        width = 100,
        height = 100,

        content = "D:",

        update = function(self, dt)
            self.content = self._focused and ":)" or "FOCUS ME :("
        end,

        pressed = function(self, x, y)
            print("D:", x, y)
        end
    })
}

window.image = love.graphics.newImage("assets/logo-256.png")

return window