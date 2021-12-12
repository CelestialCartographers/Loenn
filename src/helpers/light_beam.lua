local drawing = require("utils.drawing")
local utils = require("utils")
local drawableLine = require("structs.drawable_line")
local drawableRectangle = require("structs.drawable_rectangle")
local drawableSprite = require("structs.drawable_sprite")

local lightBeamHelper = {}

local lightBeamTexture = "util/lightbeam"

function lightBeamHelper.getSprites(room, entity, color, onlyBase)
    -- Shallowcopy so we can change the alpha later
    color = table.shallowcopy(color or {0.8, 1.0, 1.0, 0.4})

    if not color[4] then
        color[4] = 0.4
    end

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
    sprite:setColor(color)
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

            color[4] = alpha

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
                beamSprite:setColor(color)
                beamSprite:setJustification(0.0, 0.0)
                beamSprite:setScale(beamLengthScale, beamWidth)
                beamSprite.rotation = theta + math.pi / 2

                table.insert(sprites, beamSprite)
            end
        end
    end

    return sprites
end

function lightBeamHelper.getSelection(room, entity)
    local baseSprite = lightBeamHelper.getSprites(room, entity, nil, true)[1]

    return baseSprite:getRectangle()
end

return lightBeamHelper