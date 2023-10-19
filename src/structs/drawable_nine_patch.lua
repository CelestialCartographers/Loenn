local utils = require("utils")
local drawing = require("utils.drawing")
local atlases = require("atlases")
local drawableSprite = require("structs.drawable_sprite")
local matrixLib = require("utils.matrix")

local drawableNinePatch = {}

local drawableNinePatchMt = {}
drawableNinePatchMt.__index = {}

function drawableNinePatchMt.__index:getSpriteSize(sprite)
    if self.useRealSize then
        return sprite.meta.realWidth, sprite.meta.realHeight
    end

    return sprite.meta.width, sprite.meta.height
end

function drawableNinePatchMt.__index:cacheNinePatchMatrix()
    local sprite = drawableSprite.fromTexture(self.texture, {})

    if sprite and sprite.meta then
        if not sprite.meta.ninePatchMatrix then
            local hideOverflow = self.hideOverflow
            local realSize = self.useRealSize

            local tileWidth, tileHeight = self.tileWidth, self.tileHeight
            local spriteWidth, spriteHeight = self:getSpriteSize(sprite)
            local widthInTiles, heightInTiles = math.ceil(spriteWidth / tileWidth), math.ceil(spriteHeight / tileHeight)

            local matrix = matrixLib.filled(nil, widthInTiles, heightInTiles)

            for x = 1, widthInTiles do
                for y = 1, heightInTiles do
                    matrix:set(x, y, sprite:getRelativeQuad((x - 1) * tileWidth, (y - 1) * tileHeight, tileWidth, tileHeight, hideOverflow, realSize))
                end
            end

            sprite.meta.ninePatchMatrix = matrix

            return matrix

        else
            return sprite.meta.ninePatchMatrix
        end
    end
end

function drawableNinePatchMt.__index:getMatrix()
    return self:cacheNinePatchMatrix()
end

local function getMatrixSprite(atlas, texture, x, y, matrix, quadX, quadY, color)
    local sprite = drawableSprite.fromTexture(texture, {x = x, y = y, atlas = atlas})

    sprite:setJustification(0.0, 0.0)
    sprite.quad = matrix:get(quadX, quadY)

    if color then
        sprite:setColor(color)
    end

    return sprite
end

local function getRelativeQuadSprite(atlas, texture, x, y, quadX, quadY, quadWidth, quadHeight, hideOverflow, realSize, color)
    local sprite = drawableSprite.fromTexture(texture, {x = x, y = y, atlas = atlas})

    sprite:setJustification(0.0, 0.0)
    sprite:useRelativeQuad(quadX, quadY, quadWidth, quadHeight, hideOverflow, realSize)

    if color then
        sprite:setColor(color)
    end

    return sprite
end

function drawableNinePatchMt.__index:addCornerQuads(sprites, atlas, texture, x, y, width, height, matrix, spriteWidth, spriteHeight)
    local borderLeft, borderRight, borderTop, borderBottom = self.borderLeft, self.borderRight, self.borderTop, self.borderBottom
    local offsetX = self.drawWidth - borderRight
    local offsetY = self.drawHeight - borderBottom
    local hideOverflow = self.hideOverflow
    local realSize = self.useRealSize
    local color = self.color

    -- Top Left
    if width > 0 and height > 0 and borderLeft > 0 and borderTop > 0 then
        table.insert(sprites, getRelativeQuadSprite(atlas, texture, x, y, 0, 0, borderLeft, borderTop, hideOverflow, realSize, color))
    end

    -- Top Right
    if width > borderLeft and height >= 0 and borderRight > 0 and borderTop > 0 then
        table.insert(sprites, getRelativeQuadSprite(atlas, texture, x + offsetX, y, spriteWidth - borderRight, 0, borderRight, borderTop, hideOverflow, realSize, color))
    end

    -- Bottom Left
    if width > 0 and height > borderBottom then
        table.insert(sprites, getRelativeQuadSprite(atlas, texture, x, y + offsetY, 0, spriteHeight - borderBottom, borderLeft, borderBottom, hideOverflow, realSize, color))
    end

    -- Bottom Right
    if width > borderRight and height > borderBottom then
        table.insert(sprites, getRelativeQuadSprite(atlas, texture, x + offsetX, y + offsetY, spriteWidth - borderRight, spriteHeight - borderBottom, borderLeft, borderBottom, hideOverflow, realSize, color))
    end
end

function drawableNinePatchMt.__index:addEdgeQuads(sprites, atlas, texture, x, y, width, height, matrix, spriteWidth, spriteHeight)
    local borderLeft, borderRight, borderTop, borderBottom = self.borderLeft, self.borderRight, self.borderTop, self.borderBottom
    local oppositeOffsetX = width - borderRight
    local oppositeOffsetY = height - borderBottom
    local repeatMode = self.borderMode
    local hideOverflow = self.hideOverflow
    local realSize = self.useRealSize
    local color = self.color

    if repeatMode == "random" then
        local matrixWidth, matrixHeight = matrix:size()
        local tileWidth, tileHeight = self.tileWidth, self.tileHeight
        local widthInTiles, heightInTiles = math.ceil(width / tileWidth), math.ceil(height / tileHeight)

        -- Vertical
        for ty = 2, heightInTiles - 1 do
            local offsetY = (ty - 1) * tileHeight

            table.insert(sprites, getMatrixSprite(atlas, texture, x, y + offsetY, matrix, 1, math.random(2, matrixHeight - 1), color))
            table.insert(sprites, getMatrixSprite(atlas, texture, x + oppositeOffsetX, y + offsetY, matrix, matrixWidth, math.random(2, matrixHeight - 1), color))
        end

        -- Horizontal
        for tx = 2, widthInTiles - 1 do
            local offsetX = (tx - 1) * tileWidth

            table.insert(sprites, getMatrixSprite(atlas, texture, x + offsetX, y, matrix, math.random(2, matrixWidth - 1), 1, color))
            table.insert(sprites, getMatrixSprite(atlas, texture, x + offsetX, y + oppositeOffsetY, matrix, math.random(2, matrixHeight - 1), matrixHeight, color))
        end

    elseif repeatMode == "repeat" then
        local widthNoBorder, heightNoBorder = spriteWidth - borderLeft - borderRight, spriteHeight - borderTop - borderBottom
        local processedX, processedY = borderLeft, borderTop

        -- Vertical
        while processedY < height - borderRight do
            local quadHeight = math.min(height - borderBottom - processedY, heightNoBorder)
            local spriteLeft = getRelativeQuadSprite(atlas, texture, x, y + processedY, 0, borderTop, borderLeft, quadHeight, hideOverflow, realSize, color)
            local spriteRight = getRelativeQuadSprite(atlas, texture, x + oppositeOffsetX, y + processedY, spriteWidth - borderRight, borderBottom, borderRight, quadHeight, hideOverflow, realSize, color)

            table.insert(sprites, spriteLeft)
            table.insert(sprites, spriteRight)

            processedY += heightNoBorder
        end

        -- Horizontal
        while processedX < width - borderBottom do
            local quadWidth = math.min(width - borderRight - processedX, widthNoBorder)
            local spriteTop = getRelativeQuadSprite(atlas, texture, x + processedX, y, borderLeft, 0, quadWidth, borderTop, hideOverflow, realSize, color)
            local spriteBottom = getRelativeQuadSprite(atlas, texture, x + processedX, y + oppositeOffsetY, borderRight, spriteHeight - borderBottom, quadWidth, borderBottom, hideOverflow, realSize, color)

            table.insert(sprites, spriteTop)
            table.insert(sprites, spriteBottom)

            processedX += widthNoBorder
        end
    end
end

function drawableNinePatchMt.__index:addMiddleQuads(sprites, atlas, texture, x, y, width, height, matrix, spriteWidth, spriteHeight)
    local repeatMode = self.fillMode
    local color = self.color

    if repeatMode == "random" then
        local matrixWidth, matrixHeight = matrix:size()
        local tileWidth, tileHeight = self.tileWidth, self.tileHeight
        local widthInTiles, heightInTiles = math.ceil(width / tileWidth), math.ceil(height / tileHeight)

        for ty = 2, heightInTiles - 1 do
            for tx = 2, widthInTiles - 1 do
                local offsetX = (tx - 1) * tileWidth
                local offsetY = (ty - 1) * tileHeight

                table.insert(sprites, getMatrixSprite(atlas, texture, x + offsetX, y + offsetY, matrix, math.random(2, matrixWidth - 1), math.random(2, matrixHeight - 1), color))
            end
        end

    elseif repeatMode == "repeat" then
        local borderLeft, borderRight, borderTop, borderBottom = self.borderLeft, self.borderRight, self.borderTop, self.borderBottom
        local oppositeOffsetX = width - borderRight
        local oppositeOffsetY = height - borderBottom
        local widthNoBorder, heightNoBorder = spriteWidth - borderLeft - borderRight, spriteHeight - borderTop - borderBottom
        local processedX, processedY = borderLeft, borderTop

        local hideOverflow = self.hideOverflow
        local realSize = self.useRealSize

        while processedY < height - borderBottom do
            while processedX < width - borderRight do
                local quadWidth = math.min(width - borderRight - processedX, widthNoBorder)
                local quadHeight = math.min(height - borderBottom - processedY, heightNoBorder)
                local sprite = getRelativeQuadSprite(atlas, texture, x + processedX, y + processedY, borderLeft, borderTop, quadWidth, quadHeight, hideOverflow, realSize, color)

                table.insert(sprites, sprite)

                processedX += widthNoBorder
            end

            processedX = borderLeft
            processedY += heightNoBorder
        end
    end
end

function drawableNinePatchMt.__index:getDrawableSprite()
    local sprites = {}

    local matrix = self:getMatrix()
    local texture = self.texture
    local atlas = self.atlas
    local x, y = self.drawX, self.drawY
    local width, height = self.drawWidth, self.drawHeight
    local dummySprite = drawableSprite.fromTexture(self.texture, {atlas = self.atlas})
    local spriteWidth, spriteHeight = self:getSpriteSize(dummySprite)

    if not matrix then
        return sprites
    end

    local drawBorder = self.mode == "border" or self.mode == "fill"
    local drawMiddle = self.mode == "fill"

    if drawBorder then
        self:addCornerQuads(sprites, atlas, texture, x, y, width, height, matrix, spriteWidth, spriteHeight)
        self:addEdgeQuads(sprites, atlas, texture, x, y, width, height, matrix, spriteWidth, spriteHeight)
    end

    if drawMiddle then
        self:addMiddleQuads(sprites, atlas, texture, x, y, width, height, matrix, spriteWidth, spriteHeight)
    end

    return sprites
end

function drawableNinePatchMt.__index:draw()
    local sprites = self:getDrawableSprite()

    for _, sprite in ipairs(sprites) do
        sprite:draw()
    end
end

function drawableNinePatchMt.__index:setColor(color)
    local tableColor = utils.getColor(color)

    if tableColor then
        self.color = tableColor
    end
end

function drawableNinePatch.fromTexture(texture, options, drawX, drawY, drawWidth, drawHeight)
    local ninePatch = {
        _type = "drawableNinePatch"
    }

    options = options or {}

    if type(options) == "string" then
        options = {
            mode = options
        }
    end

    local atlas = options.atlas or "Gameplay"
    local spriteMeta = atlases.getResource(texture, atlas)

    if not spriteMeta then
        return
    end

    ninePatch.atlas = atlas
    ninePatch.texture = texture
    ninePatch.useRealSize = options.useRealSize or false
    ninePatch.hideOverflow = options.hideOverflow or true
    ninePatch.mode = options.mode or "fill"
    ninePatch.borderMode = options.borderMode or "repeat"
    ninePatch.fillMode = options.fillMode or "repeat"
    ninePatch.color = utils.getColor(options.color)

    ninePatch.drawX = drawX or 0
    ninePatch.drawY = drawY or 0
    ninePatch.drawWidth = drawWidth or 0
    ninePatch.drawHeight = drawHeight or 0

    ninePatch.tileSize = options.tileSize or 8
    ninePatch.tileWidth = options.tileWidth or ninePatch.tileSize
    ninePatch.tileHeight = options.tileHeight or ninePatch.tileSize
    ninePatch.borderLeft = options.borderLeft or options.border or ninePatch.tileWidth
    ninePatch.borderRight = options.borderRight or options.border or ninePatch.tileWidth
    ninePatch.borderTop = options.borderTop or options.border or ninePatch.tileHeight
    ninePatch.borderBottom = options.borderBottom or options.border or ninePatch.tileHeight

    return setmetatable(ninePatch, drawableNinePatchMt)
end

return drawableNinePatch