local spikeHelper = require("helpers.spikes")

local spikeOptions = {
    directionNames = {
        up = "spikesUp",
        down = "spikesDown",
        left = "spikesLeft",
        right = "spikesRight"
    }
}

return spikeHelper.createEntityHandlers(spikeOptions)