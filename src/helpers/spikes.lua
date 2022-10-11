local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")
local entities = require("entities")

local spikeHelper = {}

local spikeDepth = -1
local spikeTexture = "danger/spikes/%s_%s00"

local triggerSpikeDepth = -1
local triggerSpikeTexture1 = "danger/triggertentacle/wiggle_v06"
local triggerSpikeTexture2 = "danger/triggertentacle/wiggle_v03"

local originalTriggerSpikeOffsets = {
    up = {-1, 5},
    down = {-1, -5},
    right = {-5, -1},
    left = {5, -1}
}

local spikeOffsets = {
    up = {4, 1},
    down = {4, -1},
    right = {-1, 4},
    left = {1, 4}
}

local spikeJustifications = {
    up = {0.5, 1.0},
    down = {0.5, 0.0},
    right = {0.0, 0.5},
    left = {1.0, 0.5}
}

local tentacleRotations = {
    up = 0,
    down = math.pi,
    right = math.pi / 2,
    left = math.pi * 3 / 2
}

spikeHelper.spikeVariants = {
    "default",
    "outline",
    "cliffside",
    "reflection",
    "tentacles"
}

spikeHelper.triggerSpikeVariants = {
    "default",
    "outline",
    "cliffside",
    "reflection"
}

local triggerSpikeColors = {
    {242 / 255, 90 / 255, 16 / 255},
    {255 / 255, 0 / 255, 0 / 255},
    {242 / 255, 16 / 255, 103 / 255}
}

local triggerSpikeSecondOffset = {
    up = {1, 0},
    down = {-1, 0},
    right = {0, 1},
    left = {0, -1}
}

local triggerSpikeRotationOffset = {
    up = {0, 0},
    down = {4, 0},
    right = {0, 0},
    left = {0, 4}
}

local triggerRotations = {
    up = 0,
    down = math.pi,
    right = math.pi / 2,
    left = math.pi * 3 / 2
}

-- Used to move the spikes into the wall
local function getOriginalTriggerSpikeOffset(direction)
    return unpack(originalTriggerSpikeOffsets[direction] or {0, 0})
end

local function getDirectionOffset(direction)
    return unpack(spikeOffsets[direction] or {0, 0})
end

local function getTentacleDirectionOffset(direction)
    return 0, 0
end

local function getOffset(direction, variant, originalTrigger)
    if originalTrigger then
        return getOriginalTriggerSpikeOffset(direction)

    elseif variant == "tentacles" then
        return getTentacleDirectionOffset(direction)

    else
        return getDirectionOffset(direction)
    end
end

local function getDirectionJustification(direction)
    return unpack(spikeJustifications[direction] or {0, 0})
end

local function getTentacleDirectionJustification(direction)
    if direction == "up" or direction == "right" then
        return 0.0, 0.5

    elseif direction == "down" or direction == "left" then
        return 1.0, 0.5
    end
end

local function getJustification(direction, variant)
    if variant == "tentacles" then
        return getTentacleDirectionJustification(direction)

    else
        return getDirectionJustification(direction)
    end
end

local function getDirectionRotation(direction)
    return 0
end

local function getTentacleDirectionRotation(direction)
    return tentacleRotations[direction] or 0
end

local function getRotation(direction, variant)
    if variant == "tentacles" then
        return getTentacleDirectionRotation(direction)

    else
        return getDirectionRotation(direction)
    end
end

local function getSpikeSpritesFromTexture(entity, direction, variant, originalTrigger, texture, step)
    step = step or 8

    local horizontal = direction == "left" or direction == "right"
    local justificationX, justificationY = getJustification(direction, variant)
    local offsetX, offsetY = getOffset(direction, variant, originalTrigger)
    local rotation = getRotation(direction, variant)
    local length = horizontal and (entity.height or step) or (entity.width or step)
    local positionOffsetKey = horizontal and "y" or "x"

    local position = {
        x = entity.x,
        y = entity.y
    }

    local sprites = {}

    for i = 0, length - 1, step do
        -- Tentacles overlap instead of "overflowing"
        if i == length - step / 2 then
            position[positionOffsetKey] -= step / 2
        end

        local sprite = drawableSprite.fromTexture(texture, position)

        sprite.depth = spikeDepth
        sprite.rotation = rotation
        sprite:setJustification(justificationX, justificationY)
        sprite:addPosition(offsetX, offsetY)

        table.insert(sprites, sprite)

        position[positionOffsetKey] += step
    end

    return sprites
end

-- Spikes with side images
local function getNormalSpikeSprites(entity, direction, variant, originalTrigger, step)
    local texture = string.format(spikeTexture, variant, direction)

    return getSpikeSpritesFromTexture(entity, direction, variant, originalTrigger, texture, step or 8)
end

-- Spikes with rotated sprites
local function getTentacleSprites(entity, direction, variant, step)
    local texture = "danger/tentacles00"

    return getSpikeSpritesFromTexture(entity, direction, variant, nil, texture, step or 16)
end

function spikeHelper.getSpikeSprites(entity, direction, originalTrigger)
    local variant = entity.type or "default"

    if variant == "tentacles" then
        return getTentacleSprites(entity, direction, variant, 16)

    else
        return getNormalSpikeSprites(entity, direction, variant, originalTrigger, 8)
    end
end

function spikeHelper.getSpikePlacements(direction, variants, originalTrigger)
    local placements = {}
    local horizontal = direction == "left" or direction == "right"
    local lengthKey = horizontal and "height" or "width"

    for i, variant in ipairs(variants) do
        placements[i] = {
            name = string.format("%s_%s", direction, variant),
            data = {
                type = variant,
            }
        }

        placements[i].data[lengthKey] = 8
    end

    return placements
end

function spikeHelper.getTriggerSpikeSprites(entity, direction)
    local sprites = {}

    utils.setSimpleCoordinateSeed(entity.x, entity.y)

    local horizontal = direction == "left" or direction == "right"
    local lengthKey = horizontal and "height" or "width"
    local length = entity[lengthKey] or 8
    local rotation = triggerRotations[direction] or 0
    local rotationOffsetX, rotationOffsetY = unpack(triggerSpikeRotationOffset[direction] or {0, 0})
    local justificationX, justificationY = 0.0, 1.0
    local secondOffsetX, secondOffsetY = unpack(triggerSpikeSecondOffset[direction] or {0, 0})

    for offset = 0, length - 4, 4 do
        local secondSprite = offset % 8 == 4

        local offsetX = horizontal and 0 or offset
        local offsetY = horizontal and offset or 0

        local color = triggerSpikeColors[math.random(1, #triggerSpikeColors)]

        local texture = secondSprite and triggerSpikeTexture2 or triggerSpikeTexture1
        local sprite = drawableSprite.fromTexture(texture, entity)

        -- Offset second sprite from the first one
        if secondSprite then
            sprite:addPosition(-secondOffsetX * math.random(1, 2), -secondOffsetY * math.random(1, 2))
        end

        sprite:addPosition(offsetX + rotationOffsetX, offsetY + rotationOffsetY)
        sprite:setJustification(justificationX, justificationY)
        sprite:setColor(color)

        sprite.rotation = rotation
        sprite.depth = triggerSpikeDepth

        table.insert(sprites, sprite)
    end

    return sprites
end

function spikeHelper.getTriggerSpikePlacements(direction, variants)
    local horizontal = direction == "left" or direction == "right"
    local lengthKey = horizontal and "height" or "width"

    local placements = {
        {
            name = direction,
            data = {}
        }
    }

    placements[1].data[lengthKey] = 8

    return placements
end

function spikeHelper.getCanResize(direction)
    if direction == "left" or direction == "right" then
        return {false, true}
    end

    return {true, false}
end

function spikeHelper.getFieldInformations(variants, attribute)
    attribute = attribute or "type"

    return {
        [attribute] = {
            options = variants
        }
    }
end

function spikeHelper.createEntityHandler(name, direction, triggerSpike, originalTriggerSpike, variants)
    variants = variants or (originalTriggerSpike and spikeHelper.triggerSpikeVariants) or spikeHelper.spikeVariants

    local handler = {}

    local spriteFunction = triggerSpike and spikeHelper.getTriggerSpikeSprites or spikeHelper.getSpikeSprites
    local placementFunction = triggerSpike and spikeHelper.getTriggerSpikePlacements or spikeHelper.getSpikePlacements

    handler.name = name
    handler.placements = placementFunction(direction, variants, originalTriggerSpike)
    handler.canResize = spikeHelper.getCanResize(direction)
    handler.fieldInformation = spikeHelper.getFieldInformations(variants)

    function handler.sprite(room, entity)
        return spriteFunction(entity, direction, originalTriggerSpike)
    end

    function handler.selection(room, entity)
        local sprites = spriteFunction(entity, direction, originalTriggerSpike)

        return entities.getDrawableRectangle(sprites)
    end

    return handler
end

return spikeHelper