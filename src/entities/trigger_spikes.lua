local spikeHelper = require("helpers.spikes")

local spikeUp = spikeHelper.createEntityHandler("triggerSpikesUp", "up", true)
local spikeDown = spikeHelper.createEntityHandler("triggerSpikesDown", "down", true)
local spikeLeft = spikeHelper.createEntityHandler("triggerSpikesLeft", "left", true)
local spikeRight = spikeHelper.createEntityHandler("triggerSpikesRight", "right", true)

return {
    spikeUp,
    spikeDown,
    spikeLeft,
    spikeRight
}