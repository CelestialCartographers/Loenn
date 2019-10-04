local matrix = {}

local matrixMt = {}
matrixMt.__index = {}


function matrixMt.__index:get0Inbounds(x, y)
    return self[x + y * self._width + 1]
end

function matrixMt.__index:getInbounds(x, y)
    return self:get0Inbounds(x - 1, y - 1)
end

function matrixMt.__index:get0(x, y, default)
    if x >= 0 and x < self._width and y >= 0 and y < self._height then
        return self:get0Inbounds(x, y)

    else
        return default
    end
end

function matrixMt.__index:get(x, y, default)
    if x >= 1 and x <= self._width and y >= 1 and y <= self._height then
        return self:getInbounds(x, y)

    else
        return default
    end
end


function matrixMt.__index:set0Inbounds(x, y, value)
    self[x + y * self._width + 1] = value
end

function matrixMt.__index:setInbounds(x, y, value)
    self:set0Inbounds(x - 1, y - 1, value)
end

function matrixMt.__index:set0(x, y, value)
    if x >= 0 and x < self._width and y >= 0 and y < self._height then
        self:set0Inbounds(x, y, value)
    end
end

function matrixMt.__index:set(x, y, value)
    if x >= 1 and x <= self._width and y >= 0 and y <= self._height then
        self:setInbounds(x, y, value)
    end
end

-- Inbounds functions just for external validation
function matrixMt.__index:inbounds(x, y)
    return x >= 1 and x <= self._width and y >= 1 and y <= self._height
end

function matrixMt.__index:inbounds0(x, y)
    return x >= 0 and x < self._width and y >= 0 and y < self._height
end


function matrixMt.__index:size()
    return self._width, self._height
end

function matrixMt.__index:getSlice(x1, y1, x2, y2, default)
    local res = matrix.filled(default, math.abs(x2 - x1) + 1, math.abs(y2 - y1) + 1)

    local startX, endX = math.min(x1, x2), math.max(x1, x2)
    local startY, endY = math.min(y1, y2), math.max(y1, y2)

    for x = startX, endX do
        for y = startY, endY do
            res:setInbounds(x - startX + 1, y - startY + 1, self:get(x, y, default))
        end
    end

    return res
end

function matrix.filled(default, width, height)
    local m = {
        _type = "matrix"
    }

    if default ~= nil then
        for i = 1, width * height do
            m[i] = default
        end
    end

    m._width = width
    m._height = height

    return setmetatable(m, matrixMt)
end

function matrix.fromTable(t, width, height)
    local new = {
        _type = "matrix"
    }

    if #t ~= width * height then
        error(string.format("Bad dimensions for matrix. Expected %s elements, got %s.", width * height, #t))
    end

    for i = 1, #t do
        table.insert(new, t[i])
    end

    new._width = width
    new._height = height

    return setmetatable(new, matrixMt)
end

function matrix.fromFunction(func, width, height)
    local m = {
        _type = "matrix"
    }

    for i = 1, width * height do
        m[i] = func(i, width, height)
    end

    m._width = width
    m._height = height

    return setmetatable(m, matrixMt)
end

return matrix