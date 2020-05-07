
local drawableSpriteStruct = require("structs.drawable_sprite")
local drawing = require("drawing")
local utils = require("utils")
local hanginglamp = {}

hanginglamp.depth = -2000000
local quads = {
    {0, 0, 7, 2}, {0, 7, 7, 9}, {0, 15, 7,9}
}

local quadCache = {}
local function getQuad(sprite, texture, index)
    quadCache[texture] = quadCache[texture] or {}

    if not quadCache[texture][index] then
        quadCache[texture][index] = drawing.getRelativeQuad(sprite.meta, unpack(quads[index]))
    end

    return quadCache[texture][index]
end
function hanginglamp.sprite(room, entity)
    local sprites = {}
    local texture = "objects/hanginglamp"
    local RHeight = entity.height / 8;
   
    if (RHeight > 2) then
        for i=1,RHeight-1  do 
            local chainSprite = drawableSpriteStruct.spriteFromTexture(texture, entity)
    
            chainSprite:addPosition(0,i*8 - 8) 
            chainSprite:setOffset(0, 0)
        
            chainSprite.quad = getQuad(chainSprite, texture, 2)
            table.insert(sprites, chainSprite)
        end
    end
    local sprite = drawableSpriteStruct.spriteFromTexture(texture, entity)
    
    sprite:addPosition(0, 0) 
    sprite:setOffset(0, 0)

    sprite.quad = getQuad(sprite, texture, 1)
    table.insert(sprites, sprite)
    local spritelantern = drawableSpriteStruct.spriteFromTexture(texture, entity)
   
    spritelantern:addPosition(0, entity.height-8) 
    spritelantern:setOffset(0, 0)

    spritelantern.quad = getQuad(spritelantern, texture, 3)
    table.insert(sprites, spritelantern)

    

    return sprites
end
return hanginglamp