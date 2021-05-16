local drawing = require("drawing")
local utils = require("utils")
local drawableLine = require("structs.drawable_line")

local cobweb = {}

cobweb.name = "cobweb"
cobweb.nodeLimits = {1, -1}
cobweb.depth = -1
cobweb.fieldInformation = {
    color = {
        fieldType = "color"
    }
}

local function spritesFromMiddle(middle, target, color)
    local coords = {target.x, target.y}
    local control = {
        (middle[1] + coords[1]) / 2,
        (middle[2] + coords[2]) / 2 + 4
    }
    local points = drawing.getSimpleCurve(coords, middle, control)

    return drawableLine.fromPoints(points, color, 1)
end

local defaultColor = {41 / 255, 42 / 255, 41 / 255}

function cobweb.sprite(room, entity)
    local color = defaultColor

    if entity.color then
        local success, r, g, b = utils.parseHexColor(entity.color)

        if success then
            color = {r, g, b}
        end
    end

    local nodes = entity.nodes or {}
    local firstNode = nodes[1] or entity

    local start = {entity.x, entity.y}
    local stop = {firstNode.x, firstNode.y}
    local control = {
        (start[1] + stop[1]) / 2,
        (start[2] + stop[2]) / 2 + 4
    }
    local middle = {drawing.getCurvePoint(start, stop, control, 0.5)}
    local sprites = {}

    for _, node in ipairs(nodes) do
        table.insert(sprites, spritesFromMiddle(middle, node, color))
    end

    -- Use entity rather than start since drawFromMiddle uses x and y
    table.insert(sprites, spritesFromMiddle(middle, entity, color))

    return table.flatten(sprites)
end

function cobweb.selection(room, entity)
    local main = utils.rectangle(entity.x - 2, entity.y - 2, 5, 5)
    local nodes = {}

    if entity.nodes then
        for i, node in ipairs(entity.nodes) do
            nodes[i] = utils.rectangle(node.x - 2, node.y - 2, 5, 5)
        end
    end

    return main, nodes
end

cobweb.placements = {
    name = "cobweb",
    placementType = "line",
    data = {
        color = "696A6A"
    }
}

return cobweb