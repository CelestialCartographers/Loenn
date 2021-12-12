local spikeHelper = require("helpers.spikes")

local spikeUp = spikeHelper.createEntityHandler("triggerSpikesOriginalUp", "up")
local spikeDown = spikeHelper.createEntityHandler("triggerSpikesOriginalDown", "down")
local spikeLeft = spikeHelper.createEntityHandler("triggerSpikesOriginalLeft", "left")
local spikeRight = spikeHelper.createEntityHandler("triggerSpikesOriginalRight", "right")

return {
    spikeUp,
    spikeDown,
    spikeLeft,
    spikeRight
}