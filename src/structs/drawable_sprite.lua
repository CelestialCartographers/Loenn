local atlases = require("atlases")
local utils = require("utils")
local drawing = require("drawing")

local drawableSpriteStruct = {}

local drawableSpriteMt = {}
drawableSpriteMt.__index = {}

function drawableSpriteMt.__index:setJustification(justificationX, justificationY)
    self.justificationX = justificationX
    self.justificationY = justificationY

    return self
end

function drawableSpriteMt.__index:setPosition(x, y)
    self.x = x
    self.y = y

    return self
end

function drawableSpriteMt.__index:addPosition(x, y)
    self.x += x
    self.y += y

    return self
end

function drawableSpriteMt.__index:setScale(scaleX, scaleY)
    self.scaleX = scaleX
    self.scaleY = scaleY

    return self
end

function drawableSpriteMt.__index:setOffset(offsetX, offsetY)
    self.offsetX = offsetX
    self.offsetY = offsetY

    return self
end

local function setColor(target, color)
    local colorType = type(color)

    if colorType == "string" then
        local success, r, g, b = utils.parseHexColor(color)

        if success then
            target.color = {r, g, b}
        end

        return success

    elseif colorType == "table" and (#color == 3 or #color == 4) then
        target.color = color

        return true
    end

    return false
end

function drawableSpriteMt.__index:setColor(color)
    return setColor(self, color)
end

-- TODO - Handle rotation
-- TODO - Verify that scales are correct
function drawableSpriteMt.__index:getRectangleRaw()
    local width = self.meta.width
    local height = self.meta.height

    local realWidth = self.meta.realWidth
    local realHeight = self.meta.realHeight

    local offsetX = self.meta.offsetX
    local offsetY = self.meta.offsetY

    local drawX = math.floor(self.x - (realWidth * self.justificationX + offsetX) * self.scaleX)
    local drawY = math.floor(self.y - (realWidth * self.justificationY + offsetY) * self.scaleY)

    drawX += (self.scaleX < 0 and width * self.scaleX or 0)
    drawY += (self.scaleY < 0 and height * self.scaleY or 0)

    return drawX, drawY, width * math.abs(self.scaleX), height * math.abs(self.scaleY)
end

function drawableSpriteMt.__index:getRectangle()
    return utils.rectangle(self:getRectangleRaw())
end

function drawableSpriteMt.__index:drawRectangle(mode, color)
    mode = mode or "fill"

    if color then
        local r, g, b, a = love.graphics.getColor()

        love.graphics.setColor(color)
        love.graphics.rectangle(mode, self:getRectangleRaw())
        love.graphics.setColor(r, g, b, a)

    else
        love.graphics.rectangle(mode, self:getRectangleRaw())
    end
end

function drawableSpriteMt.__index:draw()
    local offsetX = self.offsetX or ((self.justificationX or 0.0) * self.meta.realWidth + self.meta.offsetX)
    local offsetY = self.offsetY or ((self.justificationY or 0.0) * self.meta.realHeight + self.meta.offsetY)

    if self.color and type(self.color) == "table" then
        drawing.callKeepOriginalColor(function()
            love.graphics.setColor(self.color)
            love.graphics.draw(self.meta.image, self.quad, self.x, self.y, self.rotation, self.scaleX, self.scaleY, offsetX, offsetY)
        end)

    else
        love.graphics.draw(self.meta.image, self.quad, self.x, self.y, self.rotation, self.scaleX, self.scaleY, offsetX, offsetY)
    end
end

function drawableSpriteStruct.spriteFromTexture(texture, data)
    data = data or {}

    local atlas = data.atlas or "gameplay"
    local spriteMeta = atlases[atlas][texture]

    local drawableSprite = {
        _type = "drawableSprite"
    }

    drawableSprite.x = data.x or 0
    drawableSprite.y = data.y or 0

    drawableSprite.justificationX = data.justificationX or 0.5
    drawableSprite.justificationY = data.justificationY or 0.5

    drawableSprite.scaleX = data.sx or 1
    drawableSprite.scaleY = data.sy or 1

    drawableSprite.rotation = data.r or 0

    drawableSprite.depth = data.depth

    drawableSprite.meta = spriteMeta
    drawableSprite.quad = spriteMeta and spriteMeta.quad or nil

    setColor(drawableSprite, data.color)

    return setmetatable(drawableSprite, drawableSpriteMt)
end

return drawableSpriteStruct