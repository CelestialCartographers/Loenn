local player = {}

player.name = "player"
player.depth = 0
player.justification = {0.5, 1.0}
player.texture = "characters/player/sitDown00"
player.placements = {
    name = "player",
    data = {
        isDefaultSpawn = false
    }
}

return player