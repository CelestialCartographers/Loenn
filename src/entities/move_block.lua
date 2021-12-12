local drawableNinePatch = require("structs.drawable_nine_patch")
local drawableRectangle = require("structs.drawable_rectangle")
local drawableSprite = require("structs.drawable_sprite")

local moveBlock = {}

moveBlock.name = "moveBlock"
moveBlock.depth = 8995
moveBlock.minimumSize = {16, 16}
moveBlock.placements = {}

local moveBlockDirections = {
    "Up", "Down", "Left", "Right"
}

for _, direction in ipairs(moveBlockDirections) do
    for steerable = 1, 2 do
        for fast = 1, 2 do
            local name = string.format("%s_%s_%s", direction:lower(), steerable == 1 and "steer" or "nosteer", fast == 1 and "fast" or "slow")
            table.insert(moveBlock.placements, {
                name = name,
                data = {
                    width = 16,
                    height = 16,
                    direction = direction,
                    canSteer = steerable == 1,
                    fast = fast == 1
                }
            })
        end
    end
end

local ninePatchOptions = {
    mode = "border",
    borderMode = "repeat"
}

local buttonNinePatchOptions = {
    mode = "fill",
    border = 0
}

local midColor = {4 / 255, 3 / 255, 23 / 255}
local highlightColor = {59 / 255, 50 / 255, 101 / 255}
local buttonColor = {71 / 255, 64 / 255, 112 / 255}

local frameTexture = "objects/moveBlock/base"
local buttonTexture = "objects/moveBlock/button"
local arrowTextures = {
    up = "objects/moveBlock/arrow02",
    left = "objects/moveBlock/arrow04",
    right = "objects/moveBlock/arrow00",
    down = "objects/moveBlock/arrow06"
}
local steeringFrameTextures = {
    up = "objects/moveBlock/base_v",
    left = "objects/moveBlock/base_h",
    right = "objects/moveBlock/base_h",
    down = "objects/moveBlock/base_v"
}

-- How far the button peeks out of the block and offset to keep it in the "socket"
local buttonPopout = 3
local buttonOffset = 3

function moveBlock.sprite(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local width, height = entity.width or 24, entity.height or 24

    local direction = string.lower(entity.direction or "up")
    local canSteer = entity.canSteer
    local buttonsOnSide = direction == "up" or direction == "down"

    local blockTexture = frameTexture
    local arrowTexture = arrowTextures[direction] or arrowTextures["up"]

    if canSteer then
        blockTexture = steeringFrameTextures[direction] or blockTexture
    end

    local ninePatch = drawableNinePatch.fromTexture(blockTexture, ninePatchOptions, x, y, width, height)

    local highlightRectangle = drawableRectangle.fromRectangle("fill", x + 2, y + 2, width - 4, height - 4, highlightColor)
    local midRectangle = drawableRectangle.fromRectangle("fill", x + 8, y + 8, width - 16, height - 16, midColor)

    local arrowSprite = drawableSprite.fromTexture(arrowTexture, entity)
    local arrowSpriteWidth, arrowSpriteHeight = arrowSprite.meta.width, arrowSprite.meta.height
    local arrowX, arrowY = x + math.floor((width - arrowSpriteWidth) / 2), y + math.floor((height - arrowSpriteHeight) / 2)
    local arrowRectangle = drawableRectangle.fromRectangle("fill", arrowX, arrowY, arrowSpriteWidth, arrowSpriteHeight, highlightColor)

    arrowSprite:addPosition(math.floor(width / 2), math.floor(height / 2))

    local sprites = {}

    table.insert(sprites, highlightRectangle:getDrawableSprite())
    table.insert(sprites, midRectangle:getDrawableSprite())

    if canSteer then
        if buttonsOnSide then
            for oy = 4, height - 4, 8 do
                local leftQuadX = (oy == 4 and 16 or (oy == height - 4 and 0 or 8))
                local rightQuadX = (oy == 4 and 0 or (oy == height - 4 and 16 or 8))
                local spriteLeft = drawableSprite.fromTexture(buttonTexture, entity)
                local spriteRight = drawableSprite.fromTexture(buttonTexture, entity)

                spriteLeft.rotation = -math.pi / 2
                spriteLeft:addPosition(-buttonPopout, oy + buttonOffset)
                spriteLeft:useRelativeQuad(leftQuadX, 0, 8, 8)
                spriteLeft:setColor(buttonColor)

                spriteRight.rotation = math.pi / 2
                spriteRight:addPosition(width + buttonPopout, oy - buttonOffset)
                spriteRight:useRelativeQuad(rightQuadX, 0, 8, 8)
                spriteRight:setColor(buttonColor)

                table.insert(sprites, spriteLeft)
                table.insert(sprites, spriteRight)
            end

        else
            for ox = 4, width - 4, 8 do
                local quadX = (ox == 4 and 0 or (ox == width - 4 and 16 or 8))
                local sprite = drawableSprite.fromTexture(buttonTexture, entity)

                sprite:addPosition(ox - buttonOffset, -buttonPopout)
                sprite:useRelativeQuad(quadX, 0, 8, 8)
                sprite:setColor(buttonColor)

                table.insert(sprites, sprite)
            end
        end
    end

    for _, sprite in ipairs(ninePatch:getDrawableSprite()) do
        table.insert(sprites, sprite)
    end

    table.insert(sprites, arrowRectangle:getDrawableSprite())
    table.insert(sprites, arrowSprite)

    return sprites
end

return moveBlock