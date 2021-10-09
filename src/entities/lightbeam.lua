local drawing = require("utils.drawing")
local utils = require("utils")
local drawableLine = require("structs.drawable_line")
local drawableRectangle = require("structs.drawable_rectangle")
local drawableSprite = require("structs.drawable_sprite")

local lightBeam = {}

lightBeam.name = "lightbeam"
lightBeam.depth = -9998
lightBeam.placements = {
    name = "lightbeam",
    data = {
        width = 32,
        height = 24,
        flag = "",
        rotation = 0
    }
}

local lightBeamTexture = "util/lightbeam"

local function getSprites(room, entity, onlyBase)
    local sprites = {}
    local x, y = entity.x, entity.y

    local sprite = drawableSprite.fromTexture(lightBeamTexture, entity)
    local theta = math.rad(entity.rotation or 0)
    local width = entity.width or 32
    local height = entity.height or 24
    local halfWidth = math.floor(width / 2)
    local widthOffsetX, widthOffsetY = halfWidth * math.cos(theta), halfWidth * math.sin(theta)
    local widthScale = (height - 4) / sprite.meta.width

    sprite:addPosition(widthOffsetX, widthOffsetY)
    sprite:setColor({0.8, 1.0, 1.0, 0.4})
    sprite:setJustification(0.0, 0.0)
    sprite:setScale(widthScale, width)
    sprite.rotation = theta + math.pi / 2

    table.insert(sprites, sprite)
    utils.setSimpleCoordinateSeed(x, y)

    -- Selection doesn't need the extra visual beams
    if not onlyBase then
        for i = 0, width - 1, 4 do
            local num = i * 0.6
            local lineWidth = 4 + math.sin(num * 0.5 + 1.2) * 4.0
            local alpha = 0.6 + math.sin(num + 0.8) * 0.3
            local offset = math.sin((num + i * 32) * 0.1 + math.sin(num * 0.05 + i * 0.1) * 0.25) * (width / 2.0 - lineWidth / 2.0)

            -- Makes rendering a bit less boring, not used by game
            local offsetMultiplier = (math.random() - 0.5) * 2

            for j = 1, 2 do
                local beamSprite = drawableSprite.fromTexture(lightBeamTexture, entity)
                local beamWidth = math.random(-4, 4)
                local extraOffset = offset * offsetMultiplier - width / 2 + beamWidth
                local offsetX = utils.round(extraOffset * math.cos(theta))
                local offsetY = utils.round(extraOffset * math.sin(theta))
                local beamLengthScale = (height - math.random(4, math.floor(height / 2)))/ beamSprite.meta.width

                beamSprite:addPosition(widthOffsetX, widthOffsetY)
                beamSprite:addPosition(offsetX, offsetY)
                beamSprite:setColor({0.8, 1.0, 1.0, alpha})
                beamSprite:setJustification(0.0, 0.0)
                beamSprite:setScale(beamLengthScale, beamWidth)
                beamSprite.rotation = theta + math.pi / 2

                table.insert(sprites, beamSprite)
            end
        end
    end

    return sprites
end

function lightBeam.sprite(room, entity)
    return getSprites(room, entity)
end

function lightBeam.selection(room, entity)
    local baseSprite = getSprites(room, entity, true)[1]

    return baseSprite:getRectangle()
end

return lightBeam