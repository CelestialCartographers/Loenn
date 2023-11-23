local matrix = require("utils.matrix")
local utils = require("utils")

local tilesStruct = {}

function tilesStruct.matrixToTileString(matrix, separator, empty)
    separator = separator or ""
    empty = empty or "0"

    local width, height = matrix:size

    local lines = {}

    for y = 1, height do
        local row = {}

        for x = 1, width do
            table.insert(row, matrix:getInbounds(x, y))
        end

        table.insert(lines, table.concat(row, separator))
    end

    return table.concat(lines, "\n")
end

local function getRelevantCols(matrix, empty)
    empty = empty or "0"

    local width, height = matrix:size
    local relevantCols = {}

    for y = 1, height do
        for x = width, 1, -1 do
            if matrix:getInbounds(x, y) ~= empty then
                relevantCols[y] = x

                break
            end
        end

        if #relevantCols ~= y then
            relevantCols[y] = 0
        end
    end

    return relevantCols
end

local function getRelevantRowCount(relevantCols)
    for y = #relevantCols, 1, -1 do
        if relevantCols[y] > 0 then
            return y
        end
    end

    return 0
end

function tilesStruct.matrixToTileStringMinimized(matrix, separator, empty)
    separator = separator or ""
    empty = empty or "0"

    local width, height = matrix:size
    local relevantCols = getRelevantCols(matrix, empty)
    local relevantRowsCount = getRelevantRowCount(relevantCols)
    local lines = {}

    for y = 1, relevantRowsCount do
        local row = {}

        for x = 1, relevantCols[y] do
            row[x] = matrix:getInbounds(x, y)
        end

        lines[y] = table.concat(row, separator)
    end

    return table.concat(lines, "\n")
end

function tilesStruct.tileStringToMatrix(tiles, separator, empty)
    separator = separator or 1
    empty = empty or "0"
    tiles = tiles:gsub("\r\n", "\n")

    local lines = tiles:split("\n")()

    local cols = 0
    local rows = #lines

    for i, line in ipairs(lines) do
        cols = math.max(cols, #line)
    end

    local res = matrix.filled(empty, cols, rows)
    local parseNumber = type(empty) == "number"

    for y, line in ipairs(lines) do
        for x, char in ipairs(utils.splitUTF8(line, separator)) do
            if parseNumber then
                res:setInbounds(x, y, tonumber(char))

            else
                res:setInbounds(x, y, char)
            end
        end
    end

    return res
end

-- Returns nil if no resizing is needed
function tilesStruct.resizeMatrix(tiles, width, height, default, offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    local tilesMatrix = tiles.matrix
    local tilesWidth, tilesHeight = tilesMatrix:size()

    local offsetXPos = math.max(offsetX, 0)
    local offsetYPos = math.max(offsetY, 0)
    local offsetXNeg = math.min(offsetX, 0)
    local offsetYNeg = math.min(offsetY, 0)

    local hasOffset = offsetX ~= 0 or offsetY ~= 0
    local sameSize = tilesWidth == width and tilesHeight == height

    if not sameSize or hasOffset then
        local simpleResize = not hasOffset and tilesWidth <= width and tilesHeight <= height
        local newTilesMatrix = matrix.filled(default, width, height)

        if simpleResize then
            for x = 1, tilesWidth do
                for y = 1, tilesHeight do
                    newTilesMatrix:setInbounds(x, y, tilesMatrix:getInbounds(x, y))
                end
            end

        else
            for x = 1, width do
                for y = 1, height do
                    newTilesMatrix:set(x + offsetXPos, y + offsetYPos, tilesMatrix:get(x - offsetXNeg, y - offsetYNeg, default))
                end
            end
        end

        return newTilesMatrix
    end
end

function tilesStruct.resize(tiles, width, height, default)
    local newTilesMatrix = tilesStruct.resizeMatrix(tiles, width, height, default or "0")

    if newTilesMatrix then
        return tilesStruct.fromMatrix(newTilesMatrix)
    end

    return tiles
end

function tilesStruct.fromMatrix(m, raw)
    local tiles = {
        _type = "tiles",
        raw = raw
    }

    tiles.matrix = m

    return tiles
end

-- Adds or removes amount rows/columns from the given side
function tilesStruct.directionalResize(tiles, side, amount, default)
    if not tiles then
        return false
    end

    local newTilesMatrix
    local width, height = tiles.matrix:size()

    if side == "left" then
        newTilesMatrix = tilesStruct.resizeMatrix(tiles, width + amount, height, default or "0", amount, 0)

    elseif side == "right" then
        newTilesMatrix = tilesStruct.resizeMatrix(tiles, width + amount, height, default or "0", 0, 0)

    elseif side == "up" then
        newTilesMatrix = tilesStruct.resizeMatrix(tiles, width, height + amount, default or "0", 0, amount)

    elseif side == "down" then
        newTilesMatrix = tilesStruct.resizeMatrix(tiles, width, height + amount, default or "0", 0, 0)
    end

    if newTilesMatrix then
        return tilesStruct.fromMatrix(newTilesMatrix)
    end

    return tiles
end

function tilesStruct.decode(data)
    return tilesStruct.fromMatrix(tilesStruct.tileStringToMatrix(data.innerText or ""), data)
end

function tilesStruct.encode(tiles)
    local res = {}

    res.innerText = tilesStruct.matrixToTileStringMinimized(tiles.matrix)

    return res
end

return tilesStruct