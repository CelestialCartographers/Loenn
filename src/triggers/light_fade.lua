-- TODO Editing options: positionMode

local lightFade = {}

lightFade.name = "lightFadeTrigger"
lightFade.placements = {
    name = "light_fade",
    data = {
        lightAddFrom = 0.0,
        lightAddTo = 0.0,
        positionMode = "NoEffect"
    }
}

return lightFade