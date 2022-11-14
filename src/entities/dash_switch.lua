local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

local textures = {
    default = "objects/temple/dashButton00",
    mirror = "objects/temple/dashButtonMirror00",
}
local textureOptions = {}

for texture, _ in pairs(textures) do
    textureOptions[utils.titleCase(texture)] = texture
end

local dashSwitchHorizontal = {}

dashSwitchHorizontal.name = "dashSwitchH"
dashSwitchHorizontal.depth = 0
dashSwitchHorizontal.justification = {0.5, 0.5}
dashSwitchHorizontal.fieldInformation = {
    sprite = {
        options = textureOptions
    }
}
dashSwitchHorizontal.placements = {}

function dashSwitchHorizontal.sprite(room, entity)
    local leftSide = entity.leftSide
    local texture = entity.sprite == "default" and textures["default"] or textures["mirror"]
    local sprite = drawableSprite.fromTexture(texture, entity)

    if leftSide then
        sprite:addPosition(0, 8)
        sprite.rotation = math.pi

    else
        sprite:addPosition(8, 8)
        sprite.rotation = 0
    end

    return sprite
end

local dashSwitchVertical = {}

dashSwitchVertical.name = "dashSwitchV"
dashSwitchVertical.depth = 0
dashSwitchVertical.justification = {0.5, 0.5}
dashSwitchVertical.fieldInformation = {
    sprite = {
        options = textureOptions
    }
}
dashSwitchVertical.placements = {}

function dashSwitchVertical.sprite(room, entity)
    local ceiling = entity.ceiling
    local texture = entity.sprite == "default" and textures["default"] or textures["mirror"]
    local sprite = drawableSprite.fromTexture(texture, entity)

    if ceiling then
        sprite:addPosition(8, 0)
        sprite.rotation = -math.pi / 2

    else
        sprite:addPosition(8, 8)
        sprite.rotation = math.pi / 2
    end

    return sprite
end

local placementsInfo = {
    {dashSwitchVertical.placements, "up", "ceiling", false},
    {dashSwitchVertical.placements, "down", "ceiling", true},
    {dashSwitchHorizontal.placements, "left", "leftSide", false},
    {dashSwitchHorizontal.placements, "right", "leftSide", true}
}

for name, texture in pairs(textures) do
    for _, info in ipairs(placementsInfo) do
        local placementsTable, direction, key, value = unpack(info)
        local placement = {
            name = string.format("%s_%s", direction, name),
            data = {
                persistent = false,
                sprite = name,
                allGates = false
            }
        }

        placement.data[key] = value

        table.insert(placementsTable, placement)
    end
end

return {
    dashSwitchHorizontal,
    dashSwitchVertical
}