local detachFollowers = {}

detachFollowers.name = "detachFollowersTrigger"
detachFollowers.nodeLimits = {1, 1}
detachFollowers.placements = {
    name = "detach_followers",
    data = {
        global = true
    }
}

return detachFollowers