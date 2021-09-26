local spikeHelper = require("helpers.spikes")

local getSpikePlacements = spikeHelper.getSpikePlacements
local getSpikeSprites = spikeHelper.getSpikeSprites
local spikeVariants = spikeHelper.spikeVariants

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