local starClimbController = {}

starClimbController.name = "starClimbController"
starClimbController.depth = 0
starClimbController.texture = "@Internal@/northern_lights"
starClimbController.placements = {
    name = "controller"
}

local everestStarClimbGraphicsController = {}

everestStarClimbGraphicsController.name = "everest/starClimbGraphicsController"
everestStarClimbGraphicsController.depth = 0
everestStarClimbGraphicsController.texture = "@Internal@/northern_lights"
everestStarClimbGraphicsController.placements = {
    name = "controller",
    data = {
        fgColor = "A3FFFF",
        bgColro = "293E4B"
    }
}

return {
    starClimbController,
    everestStarClimbGraphicsController
}