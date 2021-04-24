local moonCreature = {}

local nodeStruct = require("structs.node")

moonCreature.name = "moonCreature"
moonCreature.depth = -1000000
moonCreature.texture = "scenery/moon_creatures/tiny05"

moonCreature.placements = {
    {
        name = "moon_creature",
        data = {
            number = 1
        }
    }
}

return moonCreature