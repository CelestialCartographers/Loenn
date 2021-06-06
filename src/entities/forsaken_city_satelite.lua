local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

local forsakenCitySatellite = {}

forsakenCitySatellite.name = "birdForsakenCityGem"
forsakenCitySatellite.depth = 8999
forsakenCitySatellite.nodeLineRenderType = "line"
forsakenCitySatellite.nodeLimits = {2, 2}
forsakenCitySatellite.placements = {
    name = "satellite"
}

local birdTexture = "scenery/flutterbird/flap01"
local gemTexture = "collectables/heartGem/0/00"

local dishTexture = "objects/citysatellite/dish"
local lightTexture = "objects/citysatellite/light"
local computerTexture = "objects/citysatellite/computer"
local computerScreenTexture = "objects/citysatellite/computerscreen"

local computerOffsetX, computerOffsetY = 32, 24
local birdFlightDistance = 64

local codeColors = {
    U = {240 / 255, 240 / 255, 240 / 255},
    DR = {10 / 255, 68 / 255, 224 / 255},
    UR = {179 / 255, 45 / 255, 0 / 255},
    L = {145 / 255, 113 / 255, 242 / 255},
    UL = {255 / 255, 205 / 255, 55 / 255}
}

function forsakenCitySatellite.sprite(room, entity)
    local dishSprite = drawableSprite.fromTexture(dishTexture, entity)
    dishSprite:setJustification(0.5, 1.0)

    local lightSprite = drawableSprite.fromTexture(lightTexture, entity)
    lightSprite:setJustification(0.5, 1.0)

    local computerSprite = drawableSprite.fromTexture(computerTexture, entity)
    computerSprite:addPosition(computerOffsetX, computerOffsetY)

    local computerScreenSprite = drawableSprite.fromTexture(computerScreenTexture, entity)
    computerScreenSprite:addPosition(computerOffsetX, computerOffsetY)

    return {
        dishSprite, lightSprite, computerSprite, computerScreenSprite
    }
end

local function getBirdSprites(node)
    local sprites = {}

    for code, color in pairs(codeColors) do
        local sprite = drawableSprite.fromTexture(birdTexture, node)

        local direcitonX = string.contains(code, "L") and -1 or string.contains(code, "R") and 1 or 0
        local directionY = string.contains(code, "U") and -1 or string.contains(code, "D") and 1 or 0
        local offsetX = direcitonX * birdFlightDistance
        local offsetY = directionY * birdFlightDistance
        local magnitude = math.sqrt(offsetX^2 + offsetY^2)

        sprite:addPosition(offsetX / magnitude * birdFlightDistance, offsetY / magnitude * birdFlightDistance)
        sprite:setColor(color)

        if offsetX == -1 then
            sprite.scaleX = -1
        end

        table.insert(sprites, sprite)
    end

    return sprites
end

function forsakenCitySatellite.nodeSprite(room, entity, node, nodeIndex)
    if nodeIndex == 1 then
        return getBirdSprites(node)

    else
        local gemSprite = drawableSprite.fromTexture(gemTexture, node)

        return gemSprite
    end
end

function forsakenCitySatellite.nodeRectangle(room, entity, node, nodeIndex)
    if nodeIndex == 1 then
        return utils.rectangle(node.x - 8, node.y - 8, 16, 16)

    else
        local gemSprite = drawableSprite.fromTexture(gemTexture, node)

        return gemSprite:getRectangle()
    end
end

return forsakenCitySatellite