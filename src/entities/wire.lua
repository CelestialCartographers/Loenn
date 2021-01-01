local drawing = require("drawing")
local utils = require("utils")

local wire = {}

function wire.depth(room, entity)
    return entity.above and -8500 or 2000
end

function wire.draw(room, entity)
    local pr, pg, pb, pa = love.graphics.getColor()
    local tr, tg, tb = 89 / 255, 88 / 255, 102 / 255

    if entity.color then
        local success, r, g, b = utils.parseHexColor(entity.color)

        if success then
            tr, tg, tb = r, g, b
        end
    end

    local start = {entity.x, entity.y}
    local stop = entity.nodes[1]
    local control = {
        (start[1] + stop[1]) / 2,
        (start[2] + stop[2]) / 2 + 24
    }

    local points = drawing.getSimpleCurve(start, stop, control)

    love.graphics.setColor(tr, tg, tb)
    love.graphics.line(table.flatten(points))

    love.graphics.setColor(pr, pg, pb, pa)
end

function wire.selection(room, entity)
    local main = utils.rectangle(entity.x - 2, entity.y - 2, 5, 5)
    local nodes = {}

    if entity.nodes then
        for i, node in ipairs(entity.nodes) do
            nodes[i] = utils.rectangle(node[1] - 2, node[2] - 2, 5, 5)
        end
    end

    return main, nodes
end

function wire.nodeLimits(room, entity)
    return 1, 1
end

wire.placements = {
    name = "Wire",
    data = {
        above = false,
        color = "595866",
        nodes = {{0, 0}}
    }
}

return wire