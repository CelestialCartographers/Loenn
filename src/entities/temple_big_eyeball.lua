local viewportHandler = require("viewport_handler")
local drawableSpriteStruct = require("structs.drawable_sprite")
local utils = require("utils")

local templeBigEyeball = {}

templeBigEyeball.name = "templeBigEyeball"
templeBigEyeball.depth = 0
templeBigEyeball.placements = {
    name = "temple_big_eyeball"
}

local bodyTexture = "danger/templeeye/body00"
local pupilTexture = "danger/templeeye/pupil"

function templeBigEyeball.draw(room, entity, viewport)
    local roomX, roomY = viewportHandler.getRoomCoordindates(room)
    local deltaX = roomX - entity.x
    local deltaY = roomY - entity.y
    local angle = math.atan2(deltaY, deltaX)
    local offsetX = math.cos(angle) * 10
    local offsetY = math.sin(angle) * 10

    if math.abs(deltaX) < math.abs(offsetX) then
        offsetX = deltaX
    end

    if math.abs(deltaY) < math.abs(offsetY) then
        offsetY = deltaY
    end

    local pupilData = {
        x = entity.x + offsetX,
        y = entity.y + offsetY
    }

    local bodySprite = drawableSpriteStruct.fromTexture(bodyTexture, entity)
    local pupilSprite = drawableSpriteStruct.fromTexture(pupilTexture, pupilData)

    bodySprite:draw()
    pupilSprite:draw()
end

function templeBigEyeball.selection(room, entity)
    local sprite = drawableSpriteStruct.fromTexture(bodyTexture, entity)

    return sprite:getRectangle()
end

return templeBigEyeball