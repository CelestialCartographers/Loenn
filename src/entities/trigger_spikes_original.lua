local spikeHelper = require("helpers.spikes")

local spikeOptions = {
    directionNames = {
        up = "triggerSpikesOriginalUp",
        down = "triggerSpikesOriginalDown",
        left = "triggerSpikesOriginalLeft",
        right = "triggerSpikesOriginalRight"
    },
    originalTriggerSpike = true
}

return spikeHelper.createEntityHandlers(spikeOptions)