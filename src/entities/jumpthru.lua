local drawableSpriteStruct = require("structs/drawable_sprite")
local drawing = require("drawing")

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

-- TODO find depth
jumpthru.depth = 0

function jumpthru.sprite(room, entity)
    local texture = getTexture(entity)

    local x, y = entity.x or 0, entity.y or 0
    local width = entity.width or 8
    local startX, startY = math.floor(x / 8) + 1, math.floor(y / 8) + 1
    local stopX = startX + math.floor(width / 8) - 1

    local sprites = {}

    for i = 0, stopX - startX do
        local connected = 1
        local qx = 2
        if i == 0 then
            connected = room.fgTiles.matrix:get(startX - 1, startY, '0') ~= '0' and 0 or 1
            qx = 1
        elseif i == len then
            connected = room.fgTiles.matrix:get(stopX + 1, startY, '0') ~= '0' and 0 or 1
            qx = 3
        end

        local sprite = drawableSpriteStruct.spriteFromTexture(texture, entity)

        local quadI = connected * 3 + qx
        if not quadCache[quadI] then
            quadCache[quadI] = drawing.getRelativeQuad(sprite.meta, unpack(quads[quadI]))
        end

        sprite.quad = quadCache[quadI]

        table.insert(sprites, sprite)
    end

    return sprites
end

return jumpthru