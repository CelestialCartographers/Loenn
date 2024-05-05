local drawing = require("utils.drawing")

local drawableText = {}

function drawableText.fromText(text, x, y, width, height, font, fontSize)
    local drawable = {
        _type = "drawableText"
    }

    drawable.text = text

    drawable.x = x
    drawable.y = y

    drawable.width = width
    drawable.height = height

    drawable.font = font or love.graphics.getFont()
    drawable.fontSize = fontSize

    function drawable.draw(self)
        drawing.printCenteredText(self.text, self.x, self.y, self.width, self.height, self.font, self.fontSize)
    end

    return drawable
end

return drawableText