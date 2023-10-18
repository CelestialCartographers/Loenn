local lightBeamHelper = require("helpers.light_beam")

local lightBeam = {}

lightBeam.name = "lightbeam"
lightBeam.depth = -9998
lightBeam.placements = {
    name = "lightbeam",
    data = {
        width = 32,
        height = 24,
        flag = "",
        rotation = 0.0
    }
}

lightBeam.sprite = lightBeamHelper.getSprites
lightBeam.selection = lightBeamHelper.getSelection
lightBeam.rotate = lightBeamHelper.rotate
lightBeam.updateResizeSelection = lightBeamHelper.updateResizeSelection

return lightBeam
