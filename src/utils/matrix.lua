-- Fast Matrix implementation in Lua
-- Most set/gets are inlined for performance reasons

local matrix = {}

local matrixMt = {}
matrixMt.__index = {}


function matrixMt.__index:get0Inbounds(x, y)
    return self[x + y * self._width + 1]
end

function matrixMt.__index:getInbounds(x, y)
    return self[(x - 1) + (y - 1) * self._width + 1]
end

function matrixMt.__index:get0(x, y, default)
    return x >= 0 and x < self._width and y >= 0 and y < self._height and self[x + y * self._width + 1] or default
end

function matrixMt.__index:get(x, y, default)
    return x >= 1 and x <= self._width and y >= 1 and y <= self._height and self[(x - 1) + (y - 1) * self._width + 1] or default
end


function matrixMt.__index:set0Inbounds(x, y, value)
    self[x + y * self._width + 1] = value
end

function matrixMt.__index:setInbounds(x, y, value)
    self[(x - 1) + (y - 1) * self._width + 1] = value
end

function matrixMt.__index:set0(x, y, value)
    if x >= 0 and x < self._width and y >= 0 and y < self._height then
        self[x + y * self._width + 1] = value
    end
end

function matrixMt.__index:set(x, y, value)
    if x >= 1 and x <= self._width and y >= 0 and y <= self._height then
        self[(x - 1) + (y - 1) * self._width + 1] = value
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
    local sliceWidth = math.abs(x2 - x1) + 1
    local sliceHeight = math.abs(y2 - y1) + 1
    local res = matrix.filled(default, sliceWidth, sliceHeight)

    local startX, endX = math.min(x1, x2), math.max(x1, x2)
    local startY, endY = math.min(y1, y2), math.max(y1, y2)

    for y = math.max(1, startY), math.min(self._height, endY) do
        for x = math.max(1, startX), math.min(self._width, endX) do
            local resultX = x - startX
            local resultY = y - startY

            -- This check is 0 index based, not 1 index based
            if resultX >= 0 and resultX < sliceWidth and resultY >= 0 and resultY < sliceHeight then
                res[resultX + resultY * sliceWidth + 1] = self:get(x, y, default)
            end
        end
    end

    return res
end

function matrixMt.__index:setSlice(x1, y1, x2, y2, slice)
    local sliceIsMatrix = slice._type == "matrix"

    local sliceWidth = math.abs(x2 - x1) + 1
    local sliceHeight = math.abs(y2 - y1) + 1

    local startX, endX = math.min(x1, x2), math.max(x1, x2)
    local startY, endY = math.min(y1, y2), math.max(y1, y2)

    -- Make sure sizes match
    if sliceIsMatrix and (sliceWidth ~= slice._width or sliceHeight ~= slice._height) then
        return false
    end

    for y = math.max(1, startY), math.min(self._height, endY) do
        for x = math.max(1, startX), math.min(self._width, endX) do
            if sliceIsMatrix then
                local resultX = x - startX
                local resultY = y - startY

                self:set(x, y, slice[resultX + resultY * sliceWidth + 1])

            else
                self:set(x, y, slice)
            end
        end
    end
end


function matrixMt.__index:flipHorizontal()
    local width, height = self:size()

    for x = 1, math.floor(width / 2) do
        for y = 1, height do
            local rightX = width - x + 1
            local left = self:getInbounds(x, y)
            local right = self:getInbounds(rightX, y)

            self:setInbounds(x, y, right)
            self:setInbounds(rightX, y, left)
        end
    end

    return self
end

function matrixMt.__index:flipVertical()
    local width, height = self:size()

    for y = 1, math.floor(height / 2) do
        for x = 1, width do
            local bottomY = height - y + 1
            local top = self:getInbounds(x, y)
            local bottom = self:getInbounds(x, bottomY)

            self:setInbounds(x, y, bottom)
            self:setInbounds(x, bottomY, top)
        end
    end

    return self
end

function matrixMt.__index:flip(horizontal, vertical)
    if horizontal then
        self:flipHorizontal()
    end

    if vertical then
        self:flipVertical()
    end

    return self
end


-- 90 degrees clockwise rotation
function matrixMt.__index:rotateLeft()
    local width, height = self:size()
    local rotated = matrix.fromTable(self, height, width)

    for x = 1, width do
        for y = 1, height do
            local rotatedX = y
            local rotatedY = width - x + 1

            rotated:setInbounds(rotatedX, rotatedY, self:getInbounds(x, y))
        end
    end

    return self:updateData(rotated, height, width)
end

-- 90 degrees counter clockwise rotation
function matrixMt.__index:rotateRight()
    local width, height = self:size()
    local rotated = matrix.fromTable(self, height, width)

    for x = 1, width do
        for y = 1, height do
            local rotatedX = height - y + 1
            local rotatedY = x

            rotated:setInbounds(rotatedX, rotatedY, self:getInbounds(x, y))
        end
    end

    return self:updateData(rotated, height, width)
end

function matrixMt.__index:rotate(steps)
    local rotationFunction = steps > 0 and self.rotateRight or self.rotateLeft

    for i = 1, math.abs(steps) do
        rotationFunction(self)
    end

    return self
end


function matrixMt.__index:updateData(data, width, height)
    for i = 1, #data do
        self[i] = data[i]
    end

    -- Blank out any excess values after updating
    for i = #data + 1, self._width * self._height do
        self[i] = nil
    end

    self._width = width
    self._height = height

    return self
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