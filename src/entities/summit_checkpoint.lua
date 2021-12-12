local drawableSprite = require("structs.drawable_sprite")

local summitCheckpoint = {}

summitCheckpoint.name = "summitcheckpoint"
summitCheckpoint.depth = 8999
summitCheckpoint.fieldInformation = {
    number = {
        fieldType = "integer",
    }
}
summitCheckpoint.placements = {
    name = "summit_checkpoint",
    data = {
        number = 0
    }
}

local backTexture = "scenery/summitcheckpoints/base02"
local digitBackground = "scenery/summitcheckpoints/numberbg0%d"
local digitForeground = "scenery/summitcheckpoints/number0%d"

function summitCheckpoint.sprite(room, entity)
    local number = entity.number or 0
    local digit1 = math.floor(number % 100 / 10)
    local digit2 = number % 10

    local backSprite = drawableSprite.fromTexture(backTexture, entity)
    local backDigit1 = drawableSprite.fromTexture(string.format(digitBackground, digit1), entity)
    local frontDigit1 = drawableSprite.fromTexture(string.format(digitForeground, digit1), entity)
    local backDigit2 = drawableSprite.fromTexture(string.format(digitBackground, digit2), entity)
    local frontDigit2 = drawableSprite.fromTexture(string.format(digitForeground, digit2), entity)

    backDigit1:addPosition(-2, 4)
    frontDigit1:addPosition(-2, 4)
    backDigit2:addPosition(2, 4)
    frontDigit2:addPosition(2, 4)

    local sprites = {
        backSprite,
        backDigit1,
        backDigit2,
        frontDigit1,
        frontDigit2
    }

    return sprites
end

return summitCheckpoint