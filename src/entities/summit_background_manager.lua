local summitBackgroundManager = {}

summitBackgroundManager.name = "SummitBackgroundManager"
summitBackgroundManager.depth = 0
summitBackgroundManager.texture = "@Internal@/summit_background_manager"
summitBackgroundManager.placements = {
    name = "manager",
    data = {
        index = 0,
        cutscene = "",
        intro_launch = false,
        dark = false,
        ambience = ""
    }
}

return summitBackgroundManager