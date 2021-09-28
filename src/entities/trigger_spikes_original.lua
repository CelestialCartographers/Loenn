local spikeHelper = require("helpers.spikes")

local getSpikePlacements = spikeHelper.getSpikePlacements
local getSpikeSprites = spikeHelper.getSpikeSprites
local spikeVariants = spikeHelper.spikeVariants

local spikeUp = {}

spikeUp.name = "triggerSpikesOriginalUp"
spikeUp.placements = getSpikePlacements("up", spikeVariants, true)

function spikeUp.sprite(room, entity)
    return getSpikeSprites(entity, "up", true)
end

local spikeDown = {}

spikeDown.name = "triggerSpikesOriginalDown"
spikeDown.placements = getSpikePlacements("down", spikeVariants, true)

function spikeDown.sprite(room, entity)
    return getSpikeSprites(entity, "down", true)
end

local spikeLeft = {}

spikeLeft.name = "triggerSpikesOriginalLeft"
spikeLeft.placements = getSpikePlacements("left", spikeVariants, true)

function spikeLeft.sprite(room, entity)
    return getSpikeSprites(entity, "left", true)
end

local spikeRight = {}

spikeRight.name = "triggerSpikesOriginalRight"
spikeRight.placements = getSpikePlacements("right", spikeVariants, true)

function spikeRight.sprite(room, entity)
    return getSpikeSprites(entity, "right", true)
end

return {
    spikeUp,
    spikeDown,
    spikeLeft,
    spikeRight
}