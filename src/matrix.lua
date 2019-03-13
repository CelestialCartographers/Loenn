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
    if x >= 1 and x <= self._width and y >= 0 and y <= self._height then
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
        return self:set0Inbounds(x, y, val)
    end
end

function matrixMt.__index.set(self, x, y, val)
    if x >= 1 and x <= self._width and y >= 0 and y <= self._height then
        return self:setInbounds(x, y, val)
    end
end


function matrixMt.__index.size(self)
    return self._width, self._height
end


function matrix.filled(default, width, height)
    local m = {
        _type = "matrix"
    }

    for i = 1, width * height do
        m[i] = default
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

return matrix