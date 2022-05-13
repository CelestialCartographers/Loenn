local utils = require("utils")

local ellipses = {}

local ellipseMt = {}
ellipseMt.__index = {}

function ellipses.getApproxCirumference(radiusX, radiusY)
    return 2 * math.pi * math.sqrt((radiusX ^ 2 + radiusY ^ 2) / 2)
end

-- Radii are always integers, no floor/ceil needed
local function addPoint(points, added, topLeftX, topLeftY, radiusX, pointX, pointY)
    local width = radiusX * 2 + 1
    local index = pointX - topLeftX + (pointY - topLeftY) * width

    if not added[index] then
        table.insert(points, {pointX, pointY})

        added[index] = true
    end
end

function ellipses.getPoints(x, y, radiusX, radiusY, mode, checks)
    mode = mode or "line"
    checks = checks or math.max(1, math.ceil(ellipses.getApproxCirumference(radiusX, radiusY)))
    radiusX = utils.round(radiusX)
    radiusY = utils.round(radiusY)

    local tlx, tly = x - radiusX, y - radiusY

    local points = {}
    local added = {}

    if checks > 0 then
        local step = math.pi / checks
        local filled = mode == "fill"

        for theta = 0, 2 * math.pi, step do
            local offsetX = math.cos(theta) * radiusX
            local offsetY = math.sin(theta) * radiusY

            local pointX = utils.round(x + offsetX)
            local pointY = utils.round(y + offsetY)

            addPoint(points, added, tlx, tly, radiusX, pointX, pointY)

            if filled then
                for i = math.floor(-offsetX + 1), math.ceil(offsetX - 1) do
                    addPoint(points, added, tlx, tly, radiusX, x + i, pointY)
                end
            end
        end
    end

    return points
end

function ellipseMt.__index:getPoints(mode, checks)
    return ellipses.getPoints(self.x, self.y, self.radiusX, self.radiusY, mode, checks)
end

function ellipses.create(x, y, radiusX, radiusY)
    local line = {
        _type = "ellipse"
    }

    line.x = x
    line.y = y

    line.radiusX = radiusX
    line.radiusY = radiusY

    return setmetatable(line, ellipseMt)
end

return ellipses
