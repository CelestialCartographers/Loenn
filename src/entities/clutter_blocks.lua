local atlases = require("atlases")
local matrixLib = require("utils.matrix")
local utils = require("utils")
local drawableSprite = require("structs.drawable_sprite")

local function getTextureName(color, index)
    return string.format("objects/resortclutter/%s_%02d", color, index)
end

local function getResourceChoices(color)
    local i = 0
    local sprites = {}

    while true do
        local texture = getTextureName(color, i)
        local sprite = atlases.getResource(texture)

        if sprite then
            i += 1

            table.insert(sprites, sprite)

        else
            break
        end
    end

    return sprites
end

local function choiceFits(needsDrawing, x, y, width, height)
    for tx = x, x + width - 1 do
        for ty = y, y + height - 1 do
            if not needsDrawing:get(tx, ty) then
                return false
            end
        end
    end

    return true
end

local function markChoiceComplete(needsDrawing, x, y, width, height)
    for tx = x, x + width - 1 do
        for ty = y, y + height - 1 do
            needsDrawing:set(tx, ty, false)
        end
    end
end

local function getClutterSprites(room, entity, color)
    local width, height = entity.width or 32, entity.height or 32
    local tileWidth, tileHeight = math.ceil(width / 8), math.ceil(height / 8)
    local needsDrawing = matrixLib.filled(true, tileWidth, tileHeight)

    local resourceChoices = getResourceChoices(color)

    local sprites = {}

    utils.setSimpleCoordinateSeed(entity.x, entity.y)

    for x = 1, tileWidth do
        for y = 1, tileHeight do
            if needsDrawing:get(x, y) then
                local choices = table.shallowcopy(resourceChoices)

                utils.shuffle(choices)

                for _, choice in ipairs(choices) do
                    local spriteTileWidth = math.floor(choice.width / 8)
                    local spriteTileHeight = math.floor(choice.height / 8)

                    if choiceFits(needsDrawing, x, y, spriteTileWidth, spriteTileHeight) then
                        local sprite = drawableSprite.fromMeta(choice, entity)

                        sprite:setJustification(0.0, 0.0)
                        sprite:addPosition(x * 8 - 8, y * 8 - 8)

                        table.insert(sprites, sprite)
                        markChoiceComplete(needsDrawing, x, y, spriteTileWidth, spriteTileHeight)
                    end
                end
            end
        end
    end

    return sprites
end

local function getBlocksHandler(entityName, color)
    local blocks = {}

    blocks.name = entityName
    blocks.depth = -9998
    blocks.placements = {
        name = color,
        data = {
            width = 8,
            height = 8
        }
    }

    function blocks.sprite(room, entity)
        return getClutterSprites(room, entity, color)
    end

    return blocks
end

local redBlocks = getBlocksHandler("redBlocks", "red")
local yellowBlocks = getBlocksHandler("yellowBlocks", "yellow")
local greenBlocks = getBlocksHandler("greenBlocks", "green")

return {
    redBlocks,
    yellowBlocks,
    greenBlocks
}