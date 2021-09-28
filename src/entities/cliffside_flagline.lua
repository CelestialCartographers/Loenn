local flaglineHelper = require("helpers.flagline")
local utils = require("utils")

local cliffsideFlagline = {}

cliffsideFlagline.name = "cliffflag"
cliffsideFlagline.nodeLimits = {1, 1}
cliffsideFlagline.depth = 8999

local flagLineOptions = {
    lineColor = {128 / 255, 128 / 255, 163 / 255},
    pinColor = {128 / 255, 128 / 255, 128 / 255},
    colors = {
        {216 / 255, 95 / 255, 47 / 255},
        {216 / 255, 47 / 255, 99 / 255},
        {47 / 255, 216 / 255, 162 / 255},
        {216 / 255, 214 / 255, 47 / 255}
    },
    minFlagHeight = 10,
    maxFlagHeight = 10,
    minFlagLength = 10,
    maxFlagLength = 10,
    minSpace = 2,
    maxSpace = 8,
    droopAmount = 0.2
}

function cliffsideFlagline.sprite(room, entity)
    return flaglineHelper.getFlagLineSprites(room, entity, flagLineOptions)
end

cliffsideFlagline.selection = flaglineHelper.getFlaglineSelection
cliffsideFlagline.placements = {
    name = "cliffflag"
}

return cliffsideFlagline