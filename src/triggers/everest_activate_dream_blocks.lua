local everestActivateDreamBlocks = {}

everestActivateDreamBlocks.name = "everest/activateDreamBlocksTrigger"
everestActivateDreamBlocks.associatedMods = {"Everest"}
everestActivateDreamBlocks.placements = {
    name = "activate_dream_blocks",
    data = {
        fullRoutine = false,
        activate = true,
        fastAnimation = false
    }
}

return everestActivateDreamBlocks