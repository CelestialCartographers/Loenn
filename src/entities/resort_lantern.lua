local drawableSprite = require("structs.drawable_sprite")

local holderTexture = "objects/resortLantern/holder"
local lanternTexture = "objects/resortLantern/lantern00"

local resortLantern = {}

resortLantern.name = "resortLantern"
resortLantern.depth = 2000
resortLantern.placements = {
    name = "lantern"
}

function resortLantern.sprite(room, entity)
    local checkX, checkY = math.floor(entity.x / 8) + 2, math.floor(entity.y / 8)
    local connected = room.tilesFg.matrix:get(checkX, checkY, "0")

    local holderSprite = drawableSprite.fromTexture(holderTexture, entity)
    local lanternSprite = drawableSprite.fromTexture(lanternTexture, entity)

    if connected ~= "0" and connected ~= " " then
        holderSprite.scaleX = -1
    end

    return {
        holderSprite,
        lanternSprite
    }
end

return resortLantern