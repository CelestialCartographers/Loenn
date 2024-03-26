local utils = require("utils")
local drawableSprite = require("structs.drawable_sprite")
local drawableRectangle = require("structs.drawable_rectangle")
local connectedEntities = require("helpers.connected_entities")

local starJumpBlock = {}

starJumpBlock.name = "starJumpBlock"
starJumpBlock.depth = 9010
starJumpBlock.warnBelowSize = {8, 8}
starJumpBlock.placements = {
    name = "star_jump_block",
    data = {
        width = 8,
        height = 8,
        sinks = true
    }
}

local corners = {
    "objects/starjumpBlock/corner00",
    "objects/starjumpBlock/corner01",
    "objects/starjumpBlock/corner02",
    "objects/starjumpBlock/corner03"
}
local edgeHorizontals = {
    "objects/starjumpBlock/edgeH00",
    "objects/starjumpBlock/edgeH01",
    "objects/starjumpBlock/edgeH02",
    "objects/starjumpBlock/edgeH03"
}
local edgeVerticals = {
    "objects/starjumpBlock/edgeV00",
    "objects/starjumpBlock/edgeV01",
    "objects/starjumpBlock/edgeV02",
    "objects/starjumpBlock/edgeV03"
}
local leftRailings = {
    "objects/starjumpBlock/leftrailing00",
    "objects/starjumpBlock/leftrailing01",
    "objects/starjumpBlock/leftrailing02",
    "objects/starjumpBlock/leftrailing03",
    "objects/starjumpBlock/leftrailing04",
    "objects/starjumpBlock/leftrailing05",
    "objects/starjumpBlock/leftrailing06"
}
local rightRailings = {
    "objects/starjumpBlock/rightrailing00",
    "objects/starjumpBlock/rightrailing01",
    "objects/starjumpBlock/rightrailing02",
    "objects/starjumpBlock/rightrailing03",
    "objects/starjumpBlock/rightrailing04",
    "objects/starjumpBlock/rightrailing05",
    "objects/starjumpBlock/rightrailing06"
}
local railings = {
    "objects/starjumpBlock/railing00",
    "objects/starjumpBlock/railing01",
    "objects/starjumpBlock/railing02",
    "objects/starjumpBlock/railing03",
    "objects/starjumpBlock/railing04",
    "objects/starjumpBlock/railing05",
    "objects/starjumpBlock/railing06"
}

local function getSearchPredicate(entity)
    return function(target)
        return entity._name == target._name
    end
end

local function empty(entity, x, y, rectangles)
    return not connectedEntities.hasAdjacent(entity, x, y, rectangles)
end

local function getRandomSprite(entity, textures, offsetX, offsetY, scaleX, scaleY)
    local texture = textures[math.random(1, #textures)]

    if texture then
        local sprite = drawableSprite.fromTexture(texture, entity)

        sprite:addPosition(offsetX, offsetY)
        sprite:setScale(scaleX or 1, scaleY or 1)

        return sprite
    end
end

local function addRandomSprite(sprites, entity, textures, offsetX, offsetY, scaleX, scaleY)
    local sprite = getRandomSprite(entity, textures, offsetX, offsetY, scaleX, scaleY)

    if sprite then
        table.insert(sprites, sprite)
    end
end

local function getRailingSprite(entity, textures, offsetX, offsetY)
    local texture = textures[utils.mod1(math.floor((entity.x + offsetX) / 8), #textures)]

    if texture then
        local sprite = drawableSprite.fromTexture(texture, entity)

        sprite:addPosition(offsetX, offsetY)
        sprite:setJustification(0.0, 0.0)

        return sprite
    end
end

local function addRailingSprite(sprites, entity, textures, offsetX, offsetY)
    local sprite = getRailingSprite(entity, textures, offsetX, offsetY)

    if sprite then
        table.insert(sprites, sprite)
    end
end

function starJumpBlock.sprite(room, entity)
    local relevantBlocks = utils.filter(getSearchPredicate(entity), room.entities)

    connectedEntities.appendIfMissing(relevantBlocks, entity)

    local rectangles = connectedEntities.getEntityRectangles(relevantBlocks)

    local sprites = {}

    local x, y = entity.x or 0, entity.y or 0
    local width, height = entity.width or 16, entity.height or 16

    utils.setSimpleCoordinateSeed(x, y)

    -- Horizontal Border
    for w = 8, width - 16, 8 do
        if empty(entity, w, -8, rectangles) then
            addRandomSprite(sprites, entity, edgeHorizontals, w + 4, 4, 1, 1)
            addRailingSprite(sprites, entity, railings, w, -8)
        end

        if empty(entity, w, height, rectangles) then
            addRandomSprite(sprites, entity, edgeHorizontals, w + 4, height - 4, 1, -1)
        end
    end

    -- Vertical Border
    for h = 8, height - 16, 8 do
        if empty(entity, -8, h, rectangles) then
            addRandomSprite(sprites, entity, edgeVerticals, 4, h + 4, -1, 1)
        end

        if empty(entity, width, h, rectangles) then
            addRandomSprite(sprites, entity, edgeVerticals, width - 4, h + 4, 1, 1)
        end
    end

    -- Top Left Corner
    if empty(entity, -8, 0, rectangles) and empty(entity, 0, -8, rectangles) then
        addRandomSprite(sprites, entity, corners, 4, 4, -1, 1)
        addRailingSprite(sprites, entity, leftRailings, 0, -8)

    elseif empty(entity, -8, 0, rectangles) then
        addRandomSprite(sprites, entity, edgeVerticals, 4, 4, -1, 1)

    elseif empty(entity, 0, -8, rectangles) then
        addRandomSprite(sprites, entity, edgeHorizontals, 4, 4, -1, 1)
        addRailingSprite(sprites, entity, railings, 0, -8)
    end

    -- Top Right Corner
    if empty(entity, width, 0, rectangles) and empty(entity, width - 8, -8, rectangles) then
        addRandomSprite(sprites, entity, corners, width - 4, 4, 1, 1)
        addRailingSprite(sprites, entity, rightRailings, width - 8, -8)

    elseif empty(entity, width, 0, rectangles) then
        addRandomSprite(sprites, entity, edgeVerticals, width - 4, 4, 1, 1)

    elseif empty(entity, width - 8, -8, rectangles) then
        addRandomSprite(sprites, entity, edgeHorizontals, width - 4, 4, 1, 1)
        addRailingSprite(sprites, entity, rightRailings, width - 8, -8)

    end

    -- Bottom Left Corner
    if empty(entity, -8, height - 8, rectangles) and empty(entity, 0, height, rectangles) then
        addRandomSprite(sprites, entity, corners, 4, height - 4, -1, -1)

    elseif empty(entity, -8, height - 8, rectangles) then
        addRandomSprite(sprites, entity, edgeVerticals, 4, height - 4, -1, -1)

    elseif empty(entity, 0, height, rectangles) then
        addRandomSprite(sprites, entity, edgeHorizontals, 4, height - 4, -1, -1)
    end

    -- Bottom Right Corner
    if empty(entity, width, height - 8, rectangles) and empty(entity, width - 8, height, rectangles) then
        addRandomSprite(sprites, entity, corners, width - 4, height - 4, 1, -1)

    elseif empty(entity, width, height - 8, rectangles) then
        addRandomSprite(sprites, entity, edgeVerticals, width - 4, height - 4, 1, -1)

    elseif empty(entity, width - 8, height, rectangles) then
        addRandomSprite(sprites, entity, edgeHorizontals, width - 4, height - 4, 1, -1)
    end

    return sprites
end

return starJumpBlock