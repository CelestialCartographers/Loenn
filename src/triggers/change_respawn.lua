local changeRespawn = {}

changeRespawn.name = "changeRespawnTrigger"
changeRespawn.placements = {
    name = "change_respawn"
}

function changeRespawn.nodeLimits(room, trigger)
    return 0, 1
end

return changeRespawn