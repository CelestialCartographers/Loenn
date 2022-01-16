local utils = require("utils")

local circles = {}

local circleMt = {}
circleMt.__index = {}

function circles.getCirumference(radius)
    return 2 * math.pi * radius
end

-- Radius is always a integer, no floor/ceil needed
local function addPoint(points, added, topLeftX, topLeftY, radius, pointX, pointY)
    local width = radius * 2 + 1
    local index = pointX - topLeftX + (pointY - topLeftY) * width

    if not added[index] then
        table.insert(points, {pointX, pointY})

        added[index] = true
    end
end

function circles.getPoints(x, y, radius, mode, checks)
    mode = mode or "line"
    checks = checks or math.max(1, math.ceil(circles.getCirumference(radius)))
    radius = utils.round(radius)

    local tlx, tly = x - radius, y - radius

    local points = {}
    local added = {}

    if checks > 0 then
        local step = math.pi / checks
        local filled = mode == "fill"

        for theta = 0, 2 * math.pi, step do
            local offsetX = math.cos(theta) * radius
            local offsetY = math.sin(theta) * radius

            local pointX = utils.round(x + offsetX)
            local pointY = utils.round(y + offsetY)

            addPoint(points, added, tlx, tly, radius, pointX, pointY)

            if filled then
                for i = math.floor(-offsetX + 1), math.ceil(offsetX - 1) do
                    addPoint(points, added, tlx, tly, radius, x + i, pointY)
                end
            end
        end
    end

    return points
end

function circleMt.__index:getPoints(mode, checks)
    return circles.getPoints(self.x, self.y, self.radius, mode, checks)
end

function circles.create(x, y, radius)
    local line = {
        _type = "circle"
    }

    line.x = x
    line.y = y

    line.radius = radius

    return setmetatable(line, circleMt)
end

return circles