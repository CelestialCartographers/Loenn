local atlases = require("atlases")
local utils = require("utils")
local drawing = require("utils.drawing")

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

function drawableSpriteMt.__index:setAlpha(alpha)
    local r, g, b = unpack(self.color or {})
    local newColor = {r or 1, g or 1, b or 1, alpha}

    return setColor(self, newColor)
end

-- TODO - Verify that scales are correct
function drawableSpriteMt.__index:getRectangleRaw()
    local x = self.x
    local y = self.y

    local width = self.meta.width
    local height = self.meta.height

    local realWidth = self.meta.realWidth
    local realHeight = self.meta.realHeight

    local offsetX = self.offsetX or self.meta.offsetX
    local offsetY = self.offsetY or self.meta.offsetY

    local justificationX = self.justificationX
    local justificationY = self.justificationY

    local rotation = self.rotation

    local scaleX = self.scaleX
    local scaleY = self.scaleY

    local drawX = math.floor(x - (realWidth * justificationX + offsetX) * scaleX)
    local drawY = math.floor(y - (realHeight * justificationY + offsetY) * scaleY)

    drawX += (scaleX < 0 and width * scaleX or 0)
    drawY += (scaleY < 0 and height * scaleY or 0)

    local drawWidth = width * math.abs(scaleX)
    local drawHeight = height * math.abs(scaleY)

    if rotation and rotation ~= 0 then
        -- Shorthand for each corner
        -- Remove x and y before rotation, otherwise we rotate around the wrong origin
        local tlx, tly = drawX - x, drawY - y
        local trx, try = drawX - x + drawWidth, drawY - y
        local blx, bly = drawX - x, drawY - y + drawHeight
        local brx, bry = drawX - x + drawWidth, drawY - y + drawHeight

        -- Apply rotation
        tlx, tly = utils.rotate(tlx, tly, rotation)
        trx, try = utils.rotate(trx, try, rotation)
        blx, bly = utils.rotate(blx, bly, rotation)
        brx, bry = utils.rotate(brx, bry, rotation)

        -- Find the best point for top left and bottom right
        local bestTlx, bestTly = math.min(tlx, trx, blx, brx), math.min(tly, try, bly, bry)
        local bestBrx, bestBry = math.max(tlx, trx, blx, brx), math.max(tly, try, bly, bry)

        drawX, drawY = utils.round(x + bestTlx), utils.round(y + bestTly)
        drawWidth, drawHeight = utils.round(bestBrx - bestTlx), utils.round(bestBry - bestTly)
    end

    return drawX, drawY, drawWidth, drawHeight
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
    local offsetX = self.offsetX or math.floor((self.justificationX or 0.0) * self.meta.realWidth + self.meta.offsetX)
    local offsetY = self.offsetY or math.floor((self.justificationY or 0.0) * self.meta.realHeight + self.meta.offsetY)

    local layer = self.meta.layer

    if self.color and type(self.color) == "table" then
        drawing.callKeepOriginalColor(function()
            love.graphics.setColor(self.color)

            if layer then
                love.graphics.drawLayer(self.meta.image, layer, self.quad, self.x, self.y, self.rotation, self.scaleX, self.scaleY, offsetX, offsetY)

            else
                love.graphics.draw(self.meta.image, self.quad, self.x, self.y, self.rotation, self.scaleX, self.scaleY, offsetX, offsetY)
            end
        end)

    else
        if layer then
            love.graphics.drawLayer(self.meta.image, layer, self.quad, self.x, self.y, self.rotation, self.scaleX, self.scaleY, offsetX, offsetY)

        else
            love.graphics.draw(self.meta.image, self.quad, self.x, self.y, self.rotation, self.scaleX, self.scaleY, offsetX, offsetY)
        end
    end
end

function drawableSpriteMt.__index:getRelativeQuad(x, y, width, height, hideOverflow, realSize)
    local imageMeta = self.meta

    if imageMeta then
        local quadTable

        if type(x) == "table" then
            quadTable = x
            x, y, width, height = x[1], x[2], x[3], x[4]
            hideOverflow = y
            realSize = width

        else
            quadTable = {x, y, width, height}
        end

        if not imageMeta.quadCache then
            imageMeta.quadCache = {}
        end

        -- Get value with false as default, then change it to the quad
        -- Otherwise we are just creating the quad every single request
        local quadCache = imageMeta.quadCache
        local value = utils.getPath(quadCache, quadTable, false, true)

        if value then
            return unpack(value)

        else
            local quad, offsetX, offsetY = drawing.getRelativeQuad(imageMeta, x, y, width, height, hideOverflow, realSize)

            quadCache[x][y][width][height] = {quad, offsetX, offsetY}

            return quad, offsetX, offsetY
        end
    end
end

function drawableSpriteMt.__index:useRelativeQuad(x, y, width, height, hideOverflow, realSize)
    local quad, offsetX, offsetY = self:getRelativeQuad(x, y, width, height, hideOverflow, realSize)

    self.quad = quad
    self.offsetX = (self.offsetX or 0) + offsetX
    self.offsetY = (self.offsetY or 0) + offsetY
end

function drawableSpriteStruct.fromMeta(meta, data)
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
    drawableSprite.quad = data.quad or meta and meta.quad

    if data.color then
        setColor(drawableSprite, data.color)
    end

    return setmetatable(drawableSprite, drawableSpriteMt)
end

function drawableSpriteStruct.fromTexture(texture, data)
    local atlas = data and data.atlas or "Gameplay"
    local spriteMeta = atlases.getResource(texture, atlas)

    if spriteMeta then
        return drawableSpriteStruct.fromMeta(spriteMeta, data)
    end
end

function drawableSpriteStruct.fromInternalTexture(texture, data)
    return drawableSpriteStruct.fromTexture(atlases.addInternalPrefix(texture), data)
end

return drawableSpriteStruct