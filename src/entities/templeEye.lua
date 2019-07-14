local viewportHandler = require("viewport_handler")
local drawableSpriteStruct = require("structs/drawable_sprite")

local templeEye = {}

local function isBackground(room, entity)
    local x = entity.x or 0
    local y = entity.y or 0

    local tx = math.floor(x / 8) + 1
    local ty = math.floor(y / 8) + 1

    return room.tilesFg.matrix:get(tx, ty, "0") == "0"
end

function templeEye.depth(room, entity, viewport)
    return isBackground(room, entity) and 8990 or -10001
end

function templeEye.draw(room, entity, viewport)
    local roomX, roomY = viewportHandler.getRoomCoordindates(room)
    local angle = math.atan2(roomY - entity.y, roomX - entity.x)

    local pupilData = {
        x = entity.x + math.cos(angle),
        y = entity.y + math.sin(angle)
    }

    local layer = isBackground(room, entity) and "bg" or "fg"

    local sprite1 = drawableSpriteStruct.spriteFromTexture("scenery/temple/eye/" .. layer .. "_eye", entity)
    local sprite2 = drawableSpriteStruct.spriteFromTexture("scenery/temple/eye/" .. layer .. "_lid00", entity)
    local sprite3 = drawableSpriteStruct.spriteFromTexture("scenery/temple/eye/" .. layer .. "_pupil", pupilData)

    sprite1:draw()
    sprite2:draw()
    sprite3:draw()
end

return templeEye