local drawableSpriteStruct = require("structs.drawable_sprite")
local drawing = require("drawing")
local utils = require("utils")

-- For future use I guess?
local textures = {"wood", "dream", "temple", "templeB", "cliffside", "reflection", "core"}

local function getTexture(entity)
    return entity.texture and entity.texture ~= "default" and entity.texture or "wood"
end

local quads = {
    {0, 0, 8, 7}, {8, 0, 8, 7}, {16, 0, 8, 7},
    {0, 8, 8, 5}, {8, 8, 8, 5}, {16, 8, 8, 5}
}

local quadCache = {}

local jumpthru = {}

jumpthru.name = "jumpThru"
jumpthru.depth = -9000
jumpthru.placements = {}

for i, texture in ipairs(textures) do
    jumpthru.placements[i] = {
        name = texture,
        data = {
            width = 8,
            texture = texture
        }
    }
end

local function getQuad(sprite, texture, index)
    quadCache[texture] = quadCache[texture] or {}

    if not quadCache[texture][index] then
        quadCache[texture][index] = drawing.getRelativeQuad(sprite.meta, unpack(quads[index]))
    end

    return quadCache[texture][index]
end

function jumpthru.sprite(room, entity)
    local textureRaw = getTexture(entity)
    local texture = "objects/jumpthru/" .. textureRaw

    local x, y = entity.x or 0, entity.y or 0
    local width = entity.width or 8

    local startX, startY = math.floor(x / 8) + 1, math.floor(y / 8) + 1
    local stopX = startX + math.floor(width / 8) - 1
    local len = stopX - startX

    local sprites = {}

    for i = 0, len do
        local connected = 1
        local qx = 2

        if i == 0 then
            connected = room.tilesFg.matrix:get(startX - 1, startY, "0") ~= "0" and 0 or 1
            qx = 1

        elseif i == len then
            connected = room.tilesFg.matrix:get(stopX + 1, startY, "0") ~= "0" and 0 or 1
            qx = 3
        end

        local sprite = drawableSpriteStruct.spriteFromTexture(texture, entity)
        sprite:addPosition(i * 8, 0)
        sprite:setOffset(0, 0)

        local index = connected * 3 + qx
        sprite.quad = getQuad(sprite, texture, index)

        table.insert(sprites, sprite)
    end

    return sprites
end

function jumpthru.selection(room, entity)
    return utils.rectangle(entity.x, entity.y, entity.width, 8)
end

return jumpthru