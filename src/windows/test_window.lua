local theme = require("giraffe.theme")
local giraffe = require("giraffe")
local widgetHandler = require("giraffe.widget_handler")

local window = {}

local column = {}

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

column.widgets = {
    giraffe.button({
        width = 100,
        height = 100,

        content = "Foobar", --love.graphics.newImage("assetsTesting/hardened_clay_stained_purple.png"),

        pressed = function(self, x, y)
            local parent = widgetHandler.getParentWidget(widgetHandler.getParentWidget(widgetHandler.getParentWidget(self)))
            print(":O", x, y, rawget(parent or {}, "title"))
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
        width = 100,
        height = 100,

        content = "D:",

        update = function(self, dt)
            self.content = self._focused and ":)" or "FOCUS ME :("
        end,

        pressed = function(self, x, y)
            print("D:", x, y)
        end
    }),
    giraffe.textfield({
        width = 100,
        height = 100,

        content = {""},
        multiLine = true
    }),
    giraffe.label({
        text = "Test Label :)"
    }),
    giraffe.label({
        text = "{#FF7777}Colored {#77FF77}Text {#7777FF}:o",
        plaintext = false
    }),
    giraffe.image({
        image = "assets/logo-256.png"
    }),
}

window.widgets = {giraffe.column(column)}

return window