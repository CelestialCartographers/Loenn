local entities = require("entities")
local drawing = require("drawing")
local utils = require("utils")

return {
    name = "wire",
    draw = function(room, entity)
        local pr, pg, pb, pa = love.graphics.getColor()
        local tr, tg, tb = 89 / 255, 88 / 255, 102 / 255

        if entity.color then
            local success, r, g, b = utils.parseHexColor(entity.color)

            if success then
                tr, tg, tb = r, g, b
            end
        end

        local start = {entity.x, entity.y}
        local stop = entities.getNodes(entity)[1]
        local control = {
            (start[1] + stop[1]) / 2,
            (start[2] + stop[2]) / 2 + 24
        }

        local points = drawing.getSimpleCurve(start, stop, control)

        love.graphics.setColor(tr, tg, tb)
        love.graphics.line(table.flatten(points))

        love.graphics.setColor(pr, pg, pb, pa)
    end
}