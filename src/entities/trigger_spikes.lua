local spikeHelper = require("helpers.spikes")

local getTriggerSpikePlacements = spikeHelper.getTriggerSpikePlacements
local getTriggerSpikeSprites = spikeHelper.getTriggerSpikeSprites
local spikeVariants = spikeHelper.spikeVariants

local spikeUp = {}

spikeUp.name = "triggerSpikesUp"
spikeUp.placements = getTriggerSpikePlacements("up", spikeVariants)

function spikeUp.sprite(room, entity)
    return getTriggerSpikeSprites(entity, "up")
end

local spikeDown = {}

spikeDown.name = "triggerSpikesDown"
spikeDown.placements = getTriggerSpikePlacements("down", spikeVariants)

function spikeDown.sprite(room, entity)
    return getTriggerSpikeSprites(entity, "down")
end

local spikeLeft = {}

spikeLeft.name = "triggerSpikesLeft"
spikeLeft.placements = getTriggerSpikePlacements("left", spikeVariants)

function spikeLeft.sprite(room, entity)
    return getTriggerSpikeSprites(entity, "left")
end

local spikeRight = {}

spikeRight.name = "triggerSpikesRight"
spikeRight.placements = getTriggerSpikePlacements("right", spikeVariants)

function spikeRight.sprite(room, entity)
    return getTriggerSpikeSprites(entity, "right")
end

return {
    spikeUp,
    spikeDown,
    spikeLeft,
    spikeRight
}