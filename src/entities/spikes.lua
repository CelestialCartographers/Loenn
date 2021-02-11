local drawableSpriteStruct = require("structs.drawable_sprite")

local spikeDepth = -1
local spikeTexture = "danger/spikes/%s_%s00"

local spikeVariants = {
    "default",
    "outline",
    "cliffside",
    "reflection",
    "tentacles"
}

local function getDirectionJustification(direction)
    if direction == "up" then
        return 0.0, 1.0

    elseif direction == "down" then
        return 0.0, 0.0

    elseif direction == "left" then
        return 1.0, 0.0

    else
        return 0.0, 0.0
    end
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
    if direction == "up" then
        return 0

    elseif direction == "down" then
        return math.pi

    elseif direction == "left" then
        return -math.pi / 2

    else
        return math.pi / 2
    end
end

local function getRotation(direction, variant)
    if variant == "tentacles" then
        return getTentacleDirectionRotation(direction)

    else
        return getDirectionRotation(direction)
    end
end

local function getSpikeSpritesFromTexture(entity, direction, variant, texture, step)
    step = step or 8

    local horizontal = direction == "left" or direction == "right"
    local justificationX, justificationY = getJustification(direction, variant)
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

        local sprite = drawableSpriteStruct.spriteFromTexture(texture, position)

        sprite.depth = spikeDepth
        sprite.rotation = rotation
        sprite:setJustification(justificationX, justificationY)

        table.insert(sprites, sprite)

        position[positionOffsetKey] += step
    end

    return sprites
end

-- Spikes with side images
local function getNormalSpikeSprites(entity, direction, variant, step)
    local texture = string.format(spikeTexture, variant, direction)

    return getSpikeSpritesFromTexture(entity, direction, variant, texture, step or 8)
end

-- Spikes with rotated sprites
local function getTentacleSprites(entity, direction, variant, step)
    local texture = "danger/tentacles00"

    return getSpikeSpritesFromTexture(entity, direction, variant, texture, step or 16)
end

local function getSpikeSprites(entity, direction)
    local variant = entity.type or "default"

    if variant == "tentacles" then
        return getTentacleSprites(entity, direction, variant, 16)

    else
        return getNormalSpikeSprites(entity, direction, variant, 8)
    end
end

local function getSpikePlacements(direction, variants)
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

local spikeUp = {}

spikeUp.name = "spikesUp"
spikeUp.placements = getSpikePlacements("up", spikeVariants)

function spikeUp.sprite(room, entity)
    return getSpikeSprites(entity, "up")
end

local spikeDown = {}

spikeDown.name = "spikesDown"
spikeDown.placements = getSpikePlacements("down", spikeVariants)

function spikeDown.sprite(room, entity)
    return getSpikeSprites(entity, "down")
end

local spikeLeft = {}

spikeLeft.name = "spikesLeft"
spikeLeft.placements = getSpikePlacements("left", spikeVariants)

function spikeLeft.sprite(room, entity)
    return getSpikeSprites(entity, "left")
end

local spikeRight = {}

spikeRight.name = "spikesRight"
spikeRight.placements = getSpikePlacements("right", spikeVariants)

function spikeRight.sprite(room, entity)
    return getSpikeSprites(entity, "right")
end

return {
    spikeUp,
    spikeDown,
    spikeLeft,
    spikeRight
}