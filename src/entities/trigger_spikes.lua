local spikeHelper = require("helpers.spikes")

local spikeUp = spikeHelper.createEntityHandler("triggerSpikesUp", "up")
local spikeDown = spikeHelper.createEntityHandler("triggerSpikesDown", "down")
local spikeLeft = spikeHelper.createEntityHandler("triggerSpikesLeft", "left")
local spikeRight = spikeHelper.createEntityHandler("triggerSpikesRight", "right")

return {
    spikeUp,
    spikeDown,
    spikeLeft,
    spikeRight
}