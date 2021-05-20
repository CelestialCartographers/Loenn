local utils = require("utils")
local drawing = require("drawing")
local drawableSprite = require("structs.drawable_sprite")
local matrixLib = require("matrix")

local drawableNinePatch = {}

local drawableNinePatchMt = {}
drawableNinePatchMt.__index = {}

function drawableNinePatchMt.__index:cacheNinePatchMatrix()
    local sprite = drawableSprite.spriteFromTexture(self.texture, {})

    if sprite and sprite.meta then
        if not sprite.meta.ninePatchMatrix then
            local tileWidth, tileHeight = self.tileWidth, self.tileHeight
            local spriteWidth, spriteHeight = sprite.meta.width, sprite.meta.height
            local widthInTiles, heightInTiles = math.ceil(spriteWidth / tileWidth), math.ceil(spriteHeight / tileHeight)

            local matrix = matrixLib.filled(nil, widthInTiles, heightInTiles)

            for x = 1, widthInTiles do
                for y = 1, heightInTiles do
                    matrix:set(x, y, sprite:getRelativeQuad((x - 1) * tileWidth, (y - 1) * tileHeight, tileWidth, tileHeight))
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

local function getMatrixSprite(texture, x, y, matrix, quadX, quadY)
    local sprite = drawableSprite.spriteFromTexture(texture, {x = x, y = y})

    sprite:setJustification(0.0, 0.0)
    sprite.quad = matrix:get(quadX, quadY)

    return sprite
end

local function getRelativeQuadSprite(texture, x, y, quadX, quadY, quadWidth, quadHeight)
    local sprite = drawableSprite.spriteFromTexture(texture, {x = x, y = y})

    sprite:setJustification(0.0, 0.0)
    sprite:useRelativeQuad(quadX, quadY, quadWidth, quadHeight)

    return sprite
end

function drawableNinePatchMt.__index:addCornerQuads(sprites, texture, x, y, width, height, matrix, spriteWidth, spriteHeight)
    local borderLeft, borderRight, borderTop, borderBottom = self.borderLeft, self.borderRight, self.borderTop, self.borderBottom
    local offsetX = self.drawWidth - borderRight
    local offsetY = self.drawHeight - borderBottom

    -- Top Left
    if width > 0 and height > 0 and borderLeft > 0 and borderTop > 0 then
        table.insert(sprites, getRelativeQuadSprite(texture, x, y, 0, 0, borderLeft, borderTop))
    end

    -- Top Right
    if width > borderLeft and height >= 0 and borderRight > 0 and borderTop > 0 then
        table.insert(sprites, getRelativeQuadSprite(texture, x + offsetX, y, spriteWidth - borderRight, 0, borderRight, borderTop))
    end

    -- Bottom Left
    if width > 0 and height > borderBottom then
        table.insert(sprites, getRelativeQuadSprite(texture, x, y + offsetY, 0, spriteHeight - borderBottom, borderLeft, borderBottom))
    end

    -- Bottom Right
    if width > borderRight and height > borderBottom then
        table.insert(sprites, getRelativeQuadSprite(texture, x + offsetX, y + offsetY, spriteWidth - borderRight, spriteHeight - borderBottom, borderLeft, borderBottom))
    end
end

function drawableNinePatchMt.__index:addEdgeQuads(sprites, texture, x, y, width, height, matrix, spriteWidth, spriteHeight)
    local borderLeft, borderRight, borderTop, borderBottom = self.borderLeft, self.borderRight, self.borderTop, self.borderBottom
    local oppositeOffsetX = width - borderRight
    local oppositeOffsetY = height - borderBottom
    local repeatMode = self.borderMode

    if repeatMode == "random" then
        local matrixWidth, matrixHeight = matrix:size()
        local tileWidth, tileHeight = self.tileWidth, self.tileHeight
        local widthInTiles, heightInTiles = math.ceil(width / tileWidth), math.ceil(height / tileHeight)

        -- Vertical
        for ty = 2, heightInTiles - 1 do
            local offsetY = (ty - 1) * tileHeight

            table.insert(sprites, getMatrixSprite(texture, x, y + offsetY, matrix, 1, math.random(2, matrixHeight - 1)))
            table.insert(sprites, getMatrixSprite(texture, x + oppositeOffsetX, y + offsetY, matrix, matrixWidth, math.random(2, matrixHeight - 1)))
        end

        -- Horizontal
        for tx = 2, widthInTiles - 1 do
            local offsetX = (tx - 1) * tileWidth

            table.insert(sprites, getMatrixSprite(texture, x + offsetX, y, matrix, math.random(2, matrixWidth - 1), 1))
            table.insert(sprites, getMatrixSprite(texture, x + offsetX, y + oppositeOffsetY, matrix, math.random(2, matrixHeight - 1), matrixHeight))
        end

    elseif repeatMode == "repeat" then
        local widthNoBorder, heightNoBorder = spriteWidth - borderLeft - borderRight, spriteHeight - borderTop - borderBottom
        local processedX, processedY = borderLeft, borderTop

        -- Vertical
        while processedY < height - borderRight do
            local quadHeight = math.min(height - borderBottom - processedY, heightNoBorder)
            local spriteLeft = getRelativeQuadSprite(texture, x, y + processedY, 0, borderTop, borderLeft, quadHeight)
            local spriteRight = getRelativeQuadSprite(texture, x + oppositeOffsetX, y + processedY, spriteWidth - borderRight, borderBottom, borderRight, quadHeight)

            table.insert(sprites, spriteLeft)
            table.insert(sprites, spriteRight)

            processedY += heightNoBorder
        end

        -- Horizontal
        while processedX < width - borderBottom do
            local quadWidth = math.min(width - borderRight - processedX, widthNoBorder)
            local spriteTop = getRelativeQuadSprite(texture, x + processedX, y, borderLeft, 0, quadWidth, borderTop)
            local spriteBottom = getRelativeQuadSprite(texture, x + processedX, y + oppositeOffsetY, borderRight, spriteHeight - borderBottom, quadWidth, borderBottom)

            table.insert(sprites, spriteTop)
            table.insert(sprites, spriteBottom)

            processedX += widthNoBorder
        end
    end
end

function drawableNinePatchMt.__index:addMiddleQuads(sprites, texture, x, y, width, height, matrix, spriteWidth, spriteHeight)
    local repeatMode = self.fillMode

    if repeatMode == "random" then
        local matrixWidth, matrixHeight = matrix:size()
        local tileWidth, tileHeight = self.tileWidth, self.tileHeight
        local widthInTiles, heightInTiles = math.ceil(width / tileWidth), math.ceil(height / tileHeight)

        for ty = 2, heightInTiles - 1 do
            for tx = 2, widthInTiles - 1 do
                local offsetX = (tx - 1) * tileWidth
                local offsetY = (ty - 1) * tileHeight

                table.insert(sprites, getMatrixSprite(texture, x + offsetX, y + offsetY, matrix, math.random(2, matrixWidth - 1), math.random(2, matrixHeight - 1)))
            end
        end

    elseif repeatMode == "repeat" then
        local borderLeft, borderRight, borderTop, borderBottom = self.borderLeft, self.borderRight, self.borderTop, self.borderBottom
        local oppositeOffsetX = width - borderRight
        local oppositeOffsetY = height - borderBottom
        local widthNoBorder, heightNoBorder = spriteWidth - borderLeft - borderRight, spriteHeight - borderTop - borderBottom
        local processedX, processedY = borderLeft, borderTop

        while processedY < height - borderBottom do
            while processedX < width - borderRight do
                local quadWidth = math.min(width - borderRight - processedX, widthNoBorder)
                local quadHeight = math.min(height - borderBottom - processedY, heightNoBorder)
                local sprite = getRelativeQuadSprite(texture, x + processedX, y + processedY, borderLeft, borderTop, quadWidth, quadHeight)

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
    local x, y = self.drawX, self.drawY
    local width, height = self.drawWidth, self.drawHeight
    local dummySprite = drawableSprite.spriteFromTexture(self.texture, {})
    local spriteWidth, spriteHeight = dummySprite.meta.width, dummySprite.meta.height

    if not matrix then
        return sprites
    end

    local drawBorder = self.mode == "border" or self.mode == "fill"
    local drawMiddle = self.mode == "fill"

    if drawBorder then
        self:addCornerQuads(sprites, texture, x, y, width, height, matrix, spriteWidth, spriteHeight)
        self:addEdgeQuads(sprites, texture, x, y, width, height, matrix, spriteWidth, spriteHeight)
    end

    if drawMiddle then
        self:addMiddleQuads(sprites, texture, x, y, width, height, matrix, spriteWidth, spriteHeight)
    end

    return sprites
end

function drawableNinePatchMt.__index:draw()
    local sprites = self:getDrawableSprite()

    for _, sprite in ipairs(sprites) do
        sprite:draw()
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

    ninePatch.texture = texture
    ninePatch.mode = options.mode or "fill"
    ninePatch.borderMode = options.borderMode or "repeat"
    ninePatch.fillMode = options.fillMode or "repeat"

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