-- TODO Editing options: positionMode

local bloomFade = {}

bloomFade.name = "bloomFadeTrigger"
bloomFade.placements = {
    name = "bloom_fade",
    data = {
        bloomAddFrom = 0.0,
        bloomAddTo = 0,
        positionMode = "NoEffect"
    }
}

return bloomFade