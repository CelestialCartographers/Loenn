local drawableSprite = require("structs.drawable_sprite")
local drawableLine = require("structs.drawable_line")
local drawableNinePatch = require("structs.drawable_nine_patch")
local drawableRectangle = require("structs.drawable_rectangle")
local utils = require("utils")
local enums = require("consts.celeste_enums")

local swapBlock = {}

local themeTextures = {
    normal = {
        frame = "objects/swapblock/blockRed",
        trail = "objects/swapblock/target",
        middle = "objects/swapblock/midBlockRed00",
        path = true
    },
    moon = {
        frame = "objects/swapblock/moon/blockRed",
        trail = "objects/swapblock/moon/target",
        middle = "objects/swapblock/moon/midBlockRed00",
        path = false
    }
}

local frameNinePatchOptions = {
    mode = "fill",
    borderMode = "repeat"
}

local trailNinePatchOptions = {
    mode = "fill",
    borderMode = "repeat",
    useRealSize = true
}

local pathNinePatchOptions = {
    mode = "fill",
    fillMode = "repeat",
    border = 0
}

local themes = {
    "Normal", "Moon"
}

local pathDepth = 8999
local trailDepth = 8999
local blockDepth = -9999

swapBlock.name = "swapBlock"
swapBlock.nodeLimits = {1, 1}
swapBlock.fieldInformation = {
    theme = {
        options = enums.swap_block_themes,
        editable = false
    }
}
swapBlock.placements = {}
swapBlock.minimumSize = {16, 16}

for i, theme in ipairs(themes) do
    swapBlock.placements[i] = {
        name = string.lower(theme),
        data = {
            width = 16,
            height = 16,
            theme = theme
        }
    }
end

local function addBlockSprites(sprites, entity, position, frameTexture, middleTexture)
    local x, y = position.x or 0, position.y or 0
    local width, height = entity.width or 8, entity.height or 8

    local frameNinePatch = drawableNinePatch.fromTexture(frameTexture, frameNinePatchOptions, x, y, width, height)
    local frameSprites = frameNinePatch:getDrawableSprite()
    local middleSprite = drawableSprite.fromTexture(middleTexture, position)

    middleSprite:addPosition(math.floor(width / 2), math.floor(height / 2))
    middleSprite.depth = blockDepth

    for _, sprite in ipairs(frameSprites) do
        sprite.depth = blockDepth

        table.insert(sprites, sprite)
    end

    table.insert(sprites, middleSprite)
end

local function addTrailSprites(sprites, entity, trailTexture, path)
    local nodes = entity.nodes or {}
    local x, y = entity.x or 0, entity.y or 0
    local nodeX, nodeY = nodes[1].x or x, nodes[1].y or y
    local width, height = entity.width or 8, entity.height or 8
    local drawWidth, drawHeight = math.abs(x - nodeX) + width, math.abs(y - nodeY) + height

    x, y = math.min(x, nodeX), math.min(y, nodeY)

    if path then
        local pathDirection = x == nodeX and "V" or "H"
        local pathTexture = string.format("objects/swapblock/path%s", pathDirection)
        local pathNinePatch = drawableNinePatch.fromTexture(pathTexture, pathNinePatchOptions, x, y, drawWidth, drawHeight)
        local pathSprites = pathNinePatch:getDrawableSprite()

        for _, sprite in ipairs(pathSprites) do
            sprite.depth = pathDepth

            table.insert(sprites, sprite)
        end
    end

    local frameNinePatch = drawableNinePatch.fromTexture(trailTexture, trailNinePatchOptions, x, y, drawWidth, drawHeight)
    local frameSprites = frameNinePatch:getDrawableSprite()

    for _, sprite in ipairs(frameSprites) do
        sprite.depth = trailDepth

        table.insert(sprites, sprite)
    end
end

function swapBlock.sprite(room, entity)
    local sprites = {}

    local theme = string.lower(entity.theme or "normal")
    local themeData = themeTextures[theme] or themeTextures["normal"]

    addTrailSprites(sprites, entity, themeData.trail, themeData.path)
    addBlockSprites(sprites, entity, entity, themeData.frame, themeData.middle)

    return sprites
end

function swapBlock.nodeSprite(room, entity, node)
    local sprites = {}

    local theme = string.lower(entity.theme or "normal")
    local themeData = themeTextures[theme] or themeTextures["normal"]

    addBlockSprites(sprites, entity, node, themeData.frame, themeData.middle)

    return sprites
end

function swapBlock.selection(room, entity)
    local nodes = entity.nodes or {}
    local x, y = entity.x or 0, entity.y or 0
    local nodeX, nodeY = nodes[1].x or x, nodes[1].y or y
    local width, height = entity.width or 8, entity.height or 8

    return utils.rectangle(x, y, width, height), {utils.rectangle(nodeX, nodeY, width, height)}
end

return swapBlock