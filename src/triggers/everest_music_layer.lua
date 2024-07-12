local everestMusicLayer = {}

everestMusicLayer.name = "everest/musicLayerTrigger"
everestMusicLayer.category = "audio"
everestMusicLayer.associatedMods = {"Everest"}
everestMusicLayer.placements = {
    name = "music_layer",
    data = {
        layers = "",
        enable = false
    }
}

return everestMusicLayer