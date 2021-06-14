local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

local resortRoofEnding = {}

resortRoofEnding.name = "resortRoofEnding"
resortRoofEnding.depth = 0
resortRoofEnding.placements = {
    name = "resort_roof_ending",
    data = {
        width = 8
    }
}

local startTexture = "decals/3-resort/roofEdge_d"
local endTexture = "decals/3-resort/roofEdge"

local centerTextures = {
    "decals/3-resort/roofCenter",
    "decals/3-resort/roofCenter_b",
    "decals/3-resort/roofCenter_c",
    "decals/3-resort/roofCenter_d"
}

-- Manual offsets and justifications of the sprites
function resortRoofEnding.sprite(room, entity)
    utils.setSimpleCoordinateSeed(entity.x, entity.y)

    local sprites = {}

    local width = entity.width or 8
    local offset = 0

    local startSprite = drawableSprite.fromTexture(startTexture, entity)

    startSprite:addPosition(8, 4)
    table.insert(sprites, startSprite)

    while offset < width do
        local texture = centerTextures[math.random(1, #centerTextures)]
        local middleSprite = drawableSprite.fromTexture(texture, entity)

        middleSprite:addPosition(offset + 8, 4)
        table.insert(sprites, middleSprite)

        offset += 16
    end

    local endSprite = drawableSprite.fromTexture(endTexture, entity)

    endSprite:addPosition(offset + 8, 4)
    table.insert(sprites, endSprite)

    return sprites
end

function resortRoofEnding.selection(room, entity)
    return utils.rectangle(entity.x, entity.y, math.max(entity.width or 0, 8), 8)
end

return resortRoofEnding