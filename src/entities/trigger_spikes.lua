local spikeHelper = require("helpers.spikes")

local spikeOptions = {
    directionNames = {
        up = "triggerSpikesUp",
        down = "triggerSpikesDown",
        left = "triggerSpikesLeft",
        right = "triggerSpikesRight",
    },
    triggerSpike = true,
}

return spikeHelper.createEntityHandlers(spikeOptions)