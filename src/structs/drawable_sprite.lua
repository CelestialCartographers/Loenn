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
    local tableColor = utils.getColor(color)

    if tableColor then
        target.color = tableColor
    end

    return tableColor ~= nil
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

    local offsetX = self.offsetX or self.meta.offsetX
    local offsetY = self.offsetY or self.meta.offsetY

    local drawX = math.floor(self.x - (realWidth * self.justificationX + offsetX) * self.scaleX)
    local drawY = math.floor(self.y - (realHeight * self.justificationY + offsetY) * self.scaleY)

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
        drawing.callKeepOriginalColor(function()
            love.graphics.setColor(color)
            love.graphics.rectangle(mode, self:getRectangleRaw())
        end)

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

function drawableSpriteStruct.spriteFromMeta(meta, data)
    data = data or {}

    local drawableSprite = {
        _type = "drawableSprite"
    }

    drawableSprite.x = data.x or 0
    drawableSprite.y = data.y or 0

    drawableSprite.justificationX = data.jx or data.justificationX or 0.5
    drawableSprite.justificationY = data.jy or data.justificationY or 0.5

    drawableSprite.scaleX = data.sx or data.scaleX or 1
    drawableSprite.scaleY = data.sy or data.scaleY or 1

    drawableSprite.rotation = data.r or data.rotation or 0

    drawableSprite.depth = data.depth

    drawableSprite.meta = meta
    drawableSprite.quad = meta and meta.quad or nil

    setColor(drawableSprite, data.color)

    return setmetatable(drawableSprite, drawableSpriteMt)
end

function drawableSpriteStruct.spriteFromTexture(texture, data)
    local atlas = data and data.atlas or "gameplay"
    local spriteMeta = atlases[atlas][texture]

    return drawableSpriteStruct.spriteFromMeta(spriteMeta, data)
end

return drawableSpriteStruct