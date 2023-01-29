local everestLavaBlocker = {}

everestLavaBlocker.name = "everest/lavaBlockerTrigger"
everestLavaBlocker.associatedMods = {"Everest"}
everestLavaBlocker.placements = {
    name = "lava_blocker",
    data = {
        canReenter = false
    }
}

return everestLavaBlocker