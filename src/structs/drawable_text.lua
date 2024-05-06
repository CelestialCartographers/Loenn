local drawing = require("utils.drawing")

local drawableText = {}
local drawableTextMt = {}
drawableTextMt.__index = {}

function drawableTextMt.__index:draw()
    if self.width and self.height then
        drawing.printCenteredText(self.text, self.x, self.y, self.width, self.height, self.font, self.fontSize)

    else
        local previousFont

        if self.font then
            previousFont = love.graphics.getFont()

            love.graphics.setFont(self.font)
        end

        love.graphics.print(self.text, self.x, self.y, 0, self.fontSize, self.fontSize, 0, 0)

        if self.font then
            love.graphics.setFont(previousFont)
        end
    end
end

function drawableTextMt.__index:addToBatch(batch)
    if self.width and self.height then
        drawing.addCenteredText(batch, self.text, self.x, self.y, self.width, self.height, self.font, self.fontSize)

    else
        batch:add(self.text, self.x, self.y, 0, self.fontSize, self.fontSize, 0, 0)
    end
end

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

    return setmetatable(drawable, drawableTextMt)
end

return drawableText