local utils = require("utils")

local lines = {}

local lineMt = {}
lineMt.__index = {}

local function rayDelta(n, a)
    local s = utils.sign(a)

    if s > 0 then
        return math.floor(n + 1) - n

    elseif s < 0 then
        return math.ceil(n - 1) - n

    else
        return 0
    end
end

function lines.pointsBetween(x1, y1, x2, y2)
    local points = {}
    local theta = math.atan2(y2 - y1, x2 - x1)

    local velocityX = math.cos(theta)
    local velocityY = math.sin(theta)

    velocityX = utils.isApprox(velocityX, 0) and 0 or velocityX
    velocityY = utils.isApprox(velocityY, 0) and 0 or velocityY

    local x, y = x1, y1
    local px, py = x1, y1

    table.insert(points, {x1, y1})

    while velocityX ~= 0 and not utils.isApprox(x, x2) or velocityY ~= 0 and not utils.isApprox(y, y2) do
        local deltaX = rayDelta(x, velocityX)
        local deltaY = rayDelta(y, velocityY)

        local timeX = velocityX == 0 and math.huge or deltaX / velocityX
        local timeY = velocityY == 0 and math.huge or deltaY / velocityY

        if timeX < timeY then
            x += deltaX
            y += timeX * velocityY

        else
            x += timeY * velocityX
            y += deltaY
        end

        local pointX, pointY = math.floor(x), math.floor(y)

        if pointX ~= px or pointY ~= py then
            px, py = pointX, pointY

            table.insert(points, {pointX, pointY})
        end
    end


    if x2 ~= px or y2 ~= py then
        table.insert(points, {x2, y2})
    end

    return points
end

function lineMt.__index:getPoints()
    return lines.pointsBetween(self.x1, self.y1, self.x2, self.y2)
end

function lines.create(x1, y1, x2, y2)
    local line = {
        _type = "line"
    }

    line.x1 = x1
    line.y1 = y1

    line.x2 = x2
    line.y2 = y2

    return setmetatable(line, lineMt)
end

return lines