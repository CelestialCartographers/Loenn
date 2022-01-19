local drawableSpriteStruct = require("structs.drawable_sprite")
local enums = require("consts.celeste_enums")

local trackSpinner = {}

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
    local dust = entity.dust
    local star = entity.star

    if star then
        local starfishTexture = "danger/starfish13"

        return drawableSpriteStruct.fromTexture(starfishTexture, entity)

    elseif dust then
        local dustBaseTexture = "danger/dustcreature/base00"
        local dustCenterTexture = "danger/dustcreature/center00"

        return {
            drawableSpriteStruct.fromTexture(dustBaseTexture, entity),
            drawableSpriteStruct.fromTexture(dustCenterTexture, entity),
        }

    else
        local bladeTexture = "danger/blade00"

        return drawableSpriteStruct.fromTexture(bladeTexture, entity)
    end
end

return trackSpinner