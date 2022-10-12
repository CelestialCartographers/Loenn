local drawableSpriteStruct = require("structs.drawable_sprite")

local rotateSpinner = {}

local nodeAlpha = 0.3
local dustEdgeColor = {1.0, 0.0, 0.0}

local speeds = {
    slow = "Slow",
    normal = "Normal",
    fast = "Fast",
}

-- Values are {dust, star}
local rotateSpinnerTypes = {
    blade = {false, false},
    dust = {true, false},
    starfish = {false, true},
}

rotateSpinner.name = "rotateSpinner"
rotateSpinner.nodeLimits = {1, 1}
rotateSpinner.nodeLineRenderType = "circle"
rotateSpinner.depth = -50
rotateSpinner.placements = {}

for typeName, typeAttributes in pairs(rotateSpinnerTypes) do
    for i = 1, 2 do
        local clockwise = i == 1
        local languageName = string.format("%s_%s", typeName, clockwise and "clockwise" or "counter_clockwise")
        local dust, star = unpack(typeAttributes)

        table.insert(rotateSpinner.placements, {
            name = languageName,
            data = {
                clockwise = clockwise,
                dust = dust,
                star = star
            }
        })
    end
end

local function getSprite(room, entity, alpha)
    local sprites = {}

    local dust = entity.dust
    local star = entity.star

    if star then
        local starfishTexture = "danger/starfish13"

        table.insert(sprites, drawableSpriteStruct.fromTexture(starfishTexture, entity))

    elseif dust then
        local dustBaseTexture = "danger/dustcreature/base00"
        local dustBaseOutlineTexture = "dust_creature_outlines/base00"
        local dustBaseSprite = drawableSpriteStruct.fromTexture(dustBaseTexture, entity)
        local dustBaseOutlineSprite = drawableSpriteStruct.fromInternalTexture(dustBaseOutlineTexture, entity)

        dustBaseOutlineSprite:setColor(dustEdgeColor)

        table.insert(sprites, dustBaseOutlineSprite)
        table.insert(sprites, dustBaseSprite)

    else
        local bladeTexture = "danger/blade00"

        table.insert(sprites, drawableSpriteStruct.fromTexture(bladeTexture, entity))
    end

    if alpha then
        for _, sprite in ipairs(sprites) do
            sprite:setAlpha(alpha)
        end
    end

    return sprites
end

function rotateSpinner.sprite(room, entity)
    return getSprite(room, entity)
end

function rotateSpinner.nodeSprite(room, entity, node)
    local entityCopy = table.shallowcopy(entity)

    entityCopy.x = node.x
    entityCopy.y = node.y

    return getSprite(room, entityCopy, nodeAlpha)
end

return rotateSpinner