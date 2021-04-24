local rumble = {}

rumble.name = "rumbleTrigger"
rumble.nodeLimits = {2, 2}
rumble.placements = {
    name = "rumble",
    data = {
        manualTrigger = false,
        persistent = false,
        constrainHeight = false
    }
}

return rumble