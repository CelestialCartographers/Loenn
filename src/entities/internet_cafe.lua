local drawableSprite = require("structs.drawable_sprite")

local internetCafe = {}

internetCafe.name = "wavedashmachine"
internetCafe.depth = 1000
internetCafe.placements = {
    name = "cafe"
}

local backTexture = "objects/wavedashtutorial/building_back"
local leftTexture = "objects/wavedashtutorial/building_front_left"
local rightTexture = "objects/wavedashtutorial/building_front_right"

function internetCafe.sprite(room, entity)
    local backSprite = drawableSprite.fromTexture(backTexture, entity)
    local leftSprite = drawableSprite.fromTexture(leftTexture, entity)
    local rightSprite = drawableSprite.fromTexture(rightTexture, entity)

    backSprite:setJustification(0.5, 1.0)
    leftSprite:setJustification(0.5, 1.0)
    rightSprite:setJustification(0.5, 1.0)

    local sprites = {
        backSprite,
        leftSprite,
        rightSprite
    }

    return sprites
end

return internetCafe