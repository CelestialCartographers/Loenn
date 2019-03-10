local atlases = require("atlases")

local drawableSpriteHandler = {}

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

function drawableSpriteMt.__index.setScale(self, sx, sy)
    self.sx = sx
    self.sy = sy

    return self
end

function drawableSpriteHandler.spriteFromTexture(texture, data)
    local atlas = data.atlas or "gameplay"
    local spriteMeta = atlases[atlas][texture]

    local drawableSprite = {
        _type = "drawableSprite"
    }

    drawableSprite.x = data.x or 0
    drawableSprite.y = data.y or 0

    drawableSprite.jx = data.jx or 0.5
    drawableSprite.jy = data.jy or 0.5

    drawableSprite.sx = data.sx or 1
    drawableSprite.sy = data.sy or 1

    drawableSprite.r = data.r or 0

    drawableSprite.depth = data.depth
    drawableSprite.color = data.color

    drawableSprite.meta = spriteMeta

    return setmetatable(drawableSprite, drawableSpriteMt)
end

return drawableSpriteHandler