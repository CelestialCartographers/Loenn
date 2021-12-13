local spikeHelper = require("helpers.spikes")

local spikeUp = spikeHelper.createEntityHandler("triggerSpikesOriginalUp", "up", false, true)
local spikeDown = spikeHelper.createEntityHandler("triggerSpikesOriginalDown", "down", false, true)
local spikeLeft = spikeHelper.createEntityHandler("triggerSpikesOriginalLeft", "left", false, true)
local spikeRight = spikeHelper.createEntityHandler("triggerSpikesOriginalRight", "right", false, true)

return {
    spikeUp,
    spikeDown,
    spikeLeft,
    spikeRight
}