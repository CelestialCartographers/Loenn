local resortPlatformHelper = require("helpers.resort_platforms")
local utils = require("utils")

local textures = {
    "default", "cliffside"
}

local movingPlatform = {}

movingPlatform.name = "movingPlatform"
movingPlatform.depth = 1
movingPlatform.nodeLimits = {1, 1}
movingPlatform.placements = {}

for i, texture in ipairs(textures) do
    movingPlatform.placements[i] = {
        name = texture,
        data = {
            width = 8,
            texture = texture
        }
    }
end

function movingPlatform.sprite(room, entity)
    local sprites = {}

    local x, y = entity.x or 0, entity.y or 0
    local nodes = entity.nodes or {{x = 0, y = 0}}
    local nodeX, nodeY = nodes[1].x, nodes[1].y

    resortPlatformHelper.addConnectorSprites(sprites, entity, x, y, nodeX, nodeY)
    resortPlatformHelper.addPlatformSprites(sprites, entity, entity)

    return sprites
end

function movingPlatform.nodeSprite(room, entity, node)
    return resortPlatformHelper.addPlatformSprites({}, entity, node)
end

movingPlatform.selection = resortPlatformHelper.getSelection

local sinkingPlatform = {}

sinkingPlatform.name = "sinkingPlatform"
sinkingPlatform.depth = 1
sinkingPlatform.placements = {}

for i, texture in ipairs(textures) do
    sinkingPlatform.placements[i] = {
        name = texture,
        data = {
            width = 16,
            texture = texture
        }
    }
end

function sinkingPlatform.sprite(room, entity)
    local sprites = {}

    -- Prevent visual oddities with too long lines
    local x, y = entity.x or 0, entity.y or 0
    local nodeY = room.height - 2

    if y > nodeY then
        nodeY = y
    end

    resortPlatformHelper.addConnectorSprites(sprites, entity, x, y, x, nodeY)
    resortPlatformHelper.addPlatformSprites(sprites, entity, entity)

    return sprites
end

sinkingPlatform.selection = resortPlatformHelper.getSelection

return {
    movingPlatform,
    sinkingPlatform
}