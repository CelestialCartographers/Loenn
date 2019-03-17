local atlases = require("atlases")

local drawableSpriteStruct = {}

local drawableSpriteMt = {}
drawableSpriteMt.__index = {}

function drawableSpriteMt.__index.setJustification(self, jx, jy)
    self.jx = jx
    self.jy = jy

    return self
end

function drawableSpriteMt.__index.setPosition(self, x, y)
    self.x = x
    self.y = y

    return self
end

function drawableSpriteMt.__index.addPosition(self, x, y)
    self.x += x
    self.y += y

    return self
end

function drawableSpriteMt.__index.setScale(self, scaleX, scaleY)
    self.scaleX = scaleX
    self.scaleY = scaleY

    return self
end

function drawableSpriteMt.__index.setOffset(self, offsetX, offsetY)
    self.offsetX = offsetX
    self.offsetY = offsetY

    return self
end

function drawableSpriteStruct.spriteFromTexture(texture, data)
    local data = data or {}
    local atlas = data.atlas or "gameplay"
    local spriteMeta = atlases[atlas][texture]

    local drawableSprite = {
        _type = "drawableSprite"
    }

    drawableSprite.x = data.x or 0
    drawableSprite.y = data.y or 0

    drawableSprite.jx = data.jx or 0.5
    drawableSprite.jy = data.jy or 0.5

    drawableSprite.scaleX = data.sx or 1
    drawableSprite.scaleY = data.sy or 1

    drawableSprite.rotation = data.r or 0

    drawableSprite.depth = data.depth
    drawableSprite.color = data.color

    drawableSprite.meta = spriteMeta
    drawableSprite.quad = spriteMeta.quad

    return setmetatable(drawableSprite, drawableSpriteMt)
end

return drawableSpriteStruct