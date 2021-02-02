local respawnTarget = {}

respawnTarget.name = "respawnTargetTrigger"
respawnTarget.placements = {
    name = "respawn_target"
}

function respawnTarget.nodeLimits(room, trigger)
    return 1, 1
end


return respawnTarget