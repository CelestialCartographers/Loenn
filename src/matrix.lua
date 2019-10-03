local matrix = {}

local matrixMt = {}
matrixMt.__index = {}


function matrixMt.__index.get0Inbounds(self, x, y)
    return self[x + y * self._width + 1]
end

function matrixMt.__index.getInbounds(self, x, y)
    return self:get0Inbounds(x - 1, y - 1)
end

function matrixMt.__index.get0(self, x, y, def)
    if x >= 0 and x < self._width and y >= 0 and y < self._height then
        return self:get0Inbounds(x, y)

    else
        return def
    end
end

function matrixMt.__index.get(self, x, y, def)
    if x >= 1 and x <= self._width and y >= 1 and y <= self._height then
        return self:getInbounds(x, y)

    else
        return def
    end
end


function matrixMt.__index.set0Inbounds(self, x, y, val)
    self[x + y * self._width + 1] = val
end

function matrixMt.__index.setInbounds(self, x, y, val)
    self:set0Inbounds(x - 1, y - 1, val)
end

function matrixMt.__index.set0(self, x, y, val)
    if x >= 0 and x < self._width and y >= 0 and y < self._height then
        self:set0Inbounds(x, y, val)
    end
end

function matrixMt.__index.set(self, x, y, val)
    if x >= 1 and x <= self._width and y >= 0 and y <= self._height then
        self:setInbounds(x, y, val)
    end
end

-- Inbounds functions just for external validation
function matrixMt.__index.inbounds(self, x, y)
    return x >= 1 and x <= self._width and y >= 1 and y <= self._height
end

function matrixMt.__index.inbounds0(self, x, y)
    return x >= 0 and x < self._width and y >= 0 and y < self._height
end


function matrixMt.__index.size(self)
    return self._width, self._height
end

function matrixMt.__index.getSlice(self, x1, y1, x2, y2, def)
    local res = matrix.filled(def, math.abs(x2 - x1) + 1, math.abs(y2 - y1) + 1)

    local startX, endX = math.min(x1, x2), math.max(x1, x2)
    local startY, endY = math.min(y1, y2), math.max(y1, y2)

    for x = startX, endX do
        for y = startY, endY do
            res:setInbounds(x - startX + 1, y - startY + 1, self:get(x, y, def))
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