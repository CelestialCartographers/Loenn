local starClimbController = {}

starClimbController.name = "starClimbController"
starClimbController.depth = 0
starClimbController.texture = "@Internal@/northern_lights"
starClimbController.placements = {
    name = "controller"
}

local everestStarClimbGraphicsController = {}

everestStarClimbGraphicsController.name = "everest/starClimbGraphicsController"
everestStarClimbGraphicsController.associatedMods = {"Everest"}
everestStarClimbGraphicsController.depth = 0
everestStarClimbGraphicsController.texture = "@Internal@/northern_lights"
everestStarClimbGraphicsController.placements = {
    name = "controller",
    data = {
        fgColor = "A3FFFF",
        bgColor = "293E4B"
    }
}
everestStarClimbGraphicsController.fieldInformation = {
    fgColor = {
        fieldType = "color"
    },
    bgColor = {
        fieldType = "color"
    }
}

return {
    starClimbController,
    everestStarClimbGraphicsController
}