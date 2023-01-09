local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

local wallBooster = {}

wallBooster.name = "wallBooster"
wallBooster.depth = 1999
wallBooster.canResize = {false, true}
wallBooster.placements = {
    {
        name = "booster_right",
        placementType = "rectangle",
        data = {
            height = 8,
            left = true,
            notCoreMode = false
        }
    },
    {
        name = "booster_left",
        placementType = "rectangle",
        data = {
            height = 8,
            left = false,
            notCoreMode = false
        }
    },
    {
        name = "ice_right",
        placementType = "rectangle",
        data = {
            height = 8,
            left = true,
            notCoreMode = true
        }
    },
    {
        name = "ice_left",
        placementType = "rectangle",
        data = {
            height = 8,
            left = false,
            notCoreMode = true
        }
    }
}

local fireTopTexture = "objects/wallBooster/fireTop00"
local fireMiddleTexture = "objects/wallBooster/fireMid00"
local fireBottomTexture = "objects/wallBooster/fireBottom00"

local iceTopTexture = "objects/wallBooster/iceTop00"
local iceMiddleTexture = "objects/wallBooster/iceMid00"
local iceBottomTexture = "objects/wallBooster/iceBottom00"

local function getWallTextures(entity)
    if entity.notCoreMode then
        return iceTopTexture, iceMiddleTexture, iceBottomTexture

    else
        return fireTopTexture, fireMiddleTexture, fireBottomTexture
    end
end

function wallBooster.sprite(room, entity)
    local sprites = {}

    local left = entity.left
    local height = entity.height or 8
    local tileHeight = math.floor(height / 8)
    local offsetX = left and 0 or 8
    local scaleX = left and 1 or -1

    local topTexture, middleTexture, bottomTexture = getWallTextures(entity)

    for i = 2, tileHeight - 1 do
        local middleSprite = drawableSprite.fromTexture(middleTexture, entity)

        middleSprite:addPosition(offsetX, (i - 1) * 8)
        middleSprite:setScale(scaleX, 1)
        middleSprite:setJustification(0.0, 0.0)

        table.insert(sprites, middleSprite)
    end

    local topSprite = drawableSprite.fromTexture(topTexture, entity)
    local bottomSprite = drawableSprite.fromTexture(bottomTexture, entity)

    topSprite:addPosition(offsetX, 0)
    topSprite:setScale(scaleX, 1)
    topSprite:setJustification(0.0, 0.0)

    bottomSprite:addPosition(offsetX, (tileHeight - 1) * 8)
    bottomSprite:setScale(scaleX, 1)
    bottomSprite:setJustification(0.0, 0.0)

    table.insert(sprites, topSprite)
    table.insert(sprites, bottomSprite)

    return sprites
end

function wallBooster.rectangle(room, entity)
    return utils.rectangle(entity.x, entity.y, 8, entity.height or 8)
end

function wallBooster.flip(room, entity, horizontal, vertical)
    if horizontal then
        entity.left = not entity.left
        entity.x += (entity.left and 8 or -8)
    end

    return horizontal
end

return wallBooster