local drawableRectangle = require("structs.drawable_rectangle")
local xnaColors = require("xna_colors")
local utils = require("utils")
local connectedEntities = require("helpers.connected_entities")
local waterfallHelper = require("helpers.waterfalls")

local waterfall = {}

waterfall.name = "waterfall"
waterfall.depth = -9999
waterfall.placements = {
    name = "waterfall"
}

local lightBlue = xnaColors.LightBlue
local fillColor = {lightBlue[1] * 0.3, lightBlue[2] * 0.3, lightBlue[3] * 0.3, 0.3}
local borderColor = {lightBlue[1] * 0.8, lightBlue[2] * 0.8, lightBlue[3] * 0.8, 0.8}

local function waterSearchPredicate(entity)
    return entity._name == "water"
end

local function anyCollisions(rectangle, rectangles)
    for _, rect in ipairs(rectangles) do
        if utils.aabbCheck(rect, rectangle) then
            return true
        end
    end

    return false
end

function waterfall.getHeight(room, entity)
    local waterBlocks = utils.filter(waterSearchPredicate, room.entities)
    local waterRectangles = connectedEntities.getEntityRectangles(waterBlocks)

    local x, y = entity.x or 0, entity.y or 0
    local tileX, tileY = math.floor(x / 8) + 1, math.floor(y / 8) + 1

    local roomHeight = room.height
    local wantedHeight = 8 - y % 8

    local tileMatrix = room.tilesFg.matrix

    while wantedHeight < roomHeight - y do
        local rectangle = utils.rectangle(x, y + wantedHeight, 8, 8)

        if anyCollisions(rectangle, waterRectangles) then
            break
        end

        if tileMatrix:get(tileX, tileY + 1, "0") ~= "0" then
            break
        end

        wantedHeight += 8
        tileY += 1
    end

    return wantedHeight
end

function waterfall.sprite(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local height = waterfall.getHeight(room, entity)

    local sprites = {}

    local middleRectangle = drawableRectangle.fromRectangle("fill", x, y, 8, height, fillColor)
    local leftRectangle = drawableRectangle.fromRectangle("fill", x - 1, y, 1, height, borderColor)
    local rightRectangle = drawableRectangle.fromRectangle("fill", x + 8, y, 1, height, borderColor)

    table.insert(sprites, middleRectangle:getDrawableSprite())
    table.insert(sprites, leftRectangle:getDrawableSprite())
    table.insert(sprites, rightRectangle:getDrawableSprite())

    local addWaveLineSprite = waterfallHelper.addWaveLineSprite

    -- Add wave pattern
    for i = 0, height, 21 do
        -- From left to right in the waterfall
        addWaveLineSprite(sprites, y, height, x, y + i + 9, 1, 13, borderColor)
        addWaveLineSprite(sprites, y, height, x + 1, y + i + 11, 1, 8, borderColor)
        addWaveLineSprite(sprites, y, height, x + 6, y + i + 1, 1, 8, borderColor)
        addWaveLineSprite(sprites, y, height, x + 7, y + i - 2, 1, 13, borderColor)
    end

    return sprites
end

function waterfall.rectangle(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local height = waterfall.getHeight(room, entity)

    return utils.rectangle(x - 1, y, 10, height)
end

return waterfall