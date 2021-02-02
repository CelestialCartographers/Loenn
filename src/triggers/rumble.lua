local rumble = {}

rumble.name = "rumbleTrigger"
rumble.placements = {
    name = "rumble",
    data = {
        manualTrigger = false,
        persistent = false,
        constrainHeight = false
    }
}

function rumble.nodeLimits(room, trigger)
    return 2, 2
end

return rumble