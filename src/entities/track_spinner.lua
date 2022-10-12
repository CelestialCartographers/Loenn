local drawableSpriteStruct = require("structs.drawable_sprite")
local enums = require("consts.celeste_enums")

local trackSpinner = {}

local nodeAlpha = 0.3
local dustEdgeColor = {1.0, 0.0, 0.0}

local speeds = {
    slow = "Slow",
    normal = "Normal",
    fast = "Fast",
}

-- Values are {dust, star}
local trackSpinnerTypes = {
    blade = {false, false},
    dust = {true, false},
    starfish = {false, true},
}

trackSpinner.name = "trackSpinner"
trackSpinner.nodeLimits = {1, 1}
trackSpinner.nodeLineRenderType = "line"
trackSpinner.depth = -50
trackSpinner.fieldInformation = {
    speed = {
        options = enums.track_spinner_speeds,
        editable = false
    }
}
trackSpinner.placements = {}

for typeName, typeAttributes in pairs(trackSpinnerTypes) do
    for speedName, speedValue in pairs(speeds) do
        local languageName = string.format("%s_%s", typeName, speedName)
        local dust, star = unpack(typeAttributes)

        table.insert(trackSpinner.placements, {
            name = languageName,
            data = {
                speed = speedValue,
                dust = dust,
                star = star,
                startCentered = false
            }
        })
    end
end

function getSprite(room, entity, alpha)
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

function trackSpinner.sprite(room, entity)
    return getSprite(room, entity)
end

function trackSpinner.nodeSprite(room, entity, node)
    local entityCopy = table.shallowcopy(entity)

    entityCopy.x = node.x
    entityCopy.y = node.y

    return getSprite(room, entityCopy, nodeAlpha)
end

return trackSpinner