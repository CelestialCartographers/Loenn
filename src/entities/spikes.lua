local spikeHelper = require("helpers.spikes")

local spikeUp = spikeHelper.createEntityHandler("spikesUp", "up")
local spikeDown = spikeHelper.createEntityHandler("spikesDown", "down")
local spikeLeft = spikeHelper.createEntityHandler("spikesLeft", "left")
local spikeRight = spikeHelper.createEntityHandler("spikesRight", "right")

return {
    spikeUp,
    spikeDown,
    spikeLeft,
    spikeRight
}