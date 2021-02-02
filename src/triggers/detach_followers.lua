local detachFollowers = {}

detachFollowers.name = "detachFollowersTrigger"
detachFollowers.placements = {
    name = "detach_followers",
    data = {
        global = true
    }
}

function detachFollowers.nodeLimits(room, trigger)
    return 1, 1
end

return detachFollowers