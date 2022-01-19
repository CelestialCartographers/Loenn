local enums = require("consts.celeste_enums")

local seekerStatue = {}

seekerStatue.name = "seekerStatue"
seekerStatue.depth = 8999
seekerStatue.nodeLineRenderType = "line"
seekerStatue.nodeLimits = {1, -1}
seekerStatue.texture = "decals/5-temple/statue_e"
seekerStatue.nodeTexture = "characters/monsters/predator73"
seekerStatue.fieldInformation = {
    hatch = {
        options = enums.seeker_statue_hatches,
        editable = false
    }
}
seekerStatue.placements = {
    {
        name = "seeker_statue",
        data = {
            hatch = "Distance"
        }
    }
}

return seekerStatue