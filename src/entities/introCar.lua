local entities = require("entities")
local colors = require("xna_colors")

local introCar = {}

local barrierTexture = "scenery/car/barrier"
local bodyTexture = "scenery/car/body"
local pavementTexture = "scenery/car/pavement"
local wheelsTexture = "scenery/car/wheels"

function introCar.sprite(room, entity)
    local sprites = $()
    local hasRoadAndBarriers = entity.hasRoadAndBarriers

    local carBodyData = {
        x = entity.x,
        y = entity.y,

        jx = 0.5,
        jy = 1.0,

        depth = 1
    }

    local carWheelsData = {
        x = entity.x,
        y = entity.y,

        jx = 0.5,
        jy = 1.0,

        depth = 3
    }
    
    sprites += entities.spriteFromTexture(bodyTexture, carBodyData)
    sprites += entities.spriteFromTexture(wheelsTexture, carWheelsData)

    if hasRoadAndBarriers then
        local barrierOneData = {
            x = entity.x + 32,
            y = entity.y,

            jx = 0.0,
            jy = 1.0,

            depth = -10
        }

        local barrierTwoData = {
            x = entity.x + 41,
            y = entity.y,

            jx = 0.0,
            jy = 1.0,

            depth = 5,
            color = colors.DarkGray
        }

        sprites += entities.spriteFromTexture(barrierTexture, barrierOneData)
        sprites += entities.spriteFromTexture(barrierTexture, barrierTwoData)

        -- TODO - Add pavement
    end

    return sprites
end

return introCar