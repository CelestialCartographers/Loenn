local flaglineHelper = require("helpers.flagline")
local utils = require("utils")

local clothesline = {}

clothesline.name = "clothesline"
clothesline.nodeLimits = {1, 1}
clothesline.depth = 8999

local flagLineOptions = {
    lineColor = {128 / 255, 128 / 255, 163 / 255},
    pinColor = {128 / 255, 128 / 255, 128 / 255},
    colors = {
        {13 / 255, 46 / 255, 107 / 255},
        {51 / 255, 38 / 255, 136 / 255},
        {79 / 255, 110 / 255, 157 / 255},
        {71 / 255, 25 / 255, 74 / 255}
    },
    minFlagHeight = 8,
    maxFlagHeight = 20,
    minFlagLength = 8,
    maxFlagLength = 16,
    minSpace = 2,
    maxSpace = 8
}

function clothesline.sprite(room, entity)
    return flaglineHelper.getFlagLineSprites(room, entity, flagLineOptions)
end

clothesline.selection = flaglineHelper.getFlaglineSelection
clothesline.placements = {
    name = "clothesline"
}

return clothesline