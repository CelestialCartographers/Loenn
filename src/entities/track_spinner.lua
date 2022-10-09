local drawableSpriteStruct = require("structs.drawable_sprite")
local enums = require("consts.celeste_enums")

local trackSpinner = {}

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

function trackSpinner.sprite(room, entity)
    local dust = entity.dust or true
    local star = entity.star

    if star then
        local starfishTexture = "danger/starfish13"

        return drawableSpriteStruct.fromTexture(starfishTexture, entity)

    elseif dust then
        local dustBaseTexture = "danger/dustcreature/base00"
        local dustBaseOutlineTexture = "dust_creature_outlines/base00"
        local dustBaseSprite = drawableSpriteStruct.fromTexture(dustBaseTexture, entity)
        local dustBaseOutlineSprite = drawableSpriteStruct.fromInternalTexture(dustBaseOutlineTexture, entity)

        dustBaseOutlineSprite:setColor(dustEdgeColor)

        return {
            dustBaseOutlineSprite,
            dustBaseSprite
        }

    else
        local bladeTexture = "danger/blade00"

        return drawableSpriteStruct.fromTexture(bladeTexture, entity)
    end
end

return trackSpinner