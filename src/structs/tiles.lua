local matrix = require("matrix")

local tilesStruct = {}

function tilesStruct.matrixToTileString(matrix, seperator, empty)
    seperator = seperator or ""
    empty = empty or "0"

    local width, height = matrix:size

    local lines = {}

    for y = 1, height do
        local row = {}

        for x = 1, width do
            table.insert(row, matrix:getInbounds(x, y))
        end

        table.insert(lines, table.concat(row, seperator))
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
                table.insert(relevantCols, x)

                break
            end
        end

        if #relevantCols ~= y then
            table.insert(relevantCols, 0)
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

function tilesStruct.matrixToTileStringMinimized(matrix, seperator, empty)
    seperator = seperator or ""
    empty = empty or "0"

    local width, height = matrix:size
    local relevantCols = getRelevantCols(matrix, empty)
    local relevantRowsCount = getRelevantRowCount(relevantCols)
    local lines = {}

    for y = 1, relevantRowsCount do
        local row = {}

        for x = 1, relevantCols[y] do
            table.insert(row, matrix:getInbounds(x, y))
        end

        table.insert(lines, table.concat(row, seperator))
    end

    return table.concat(lines, "\n")
end

function tilesStruct.tileStringToMatrix(tiles, seperator, empty)
    seperator = seperator or 1
    empty = empty or "0"
    tiles = tiles:gsub("\r\n", "\n")

    local lines = tiles:split("\n")()

    local cols = 0
    local rows = #lines

    for i, line in ipairs(lines) do
        cols = math.max(cols, #line)
    end

    local res = matrix.filled(empty, cols, rows)

    for y, line in ipairs(lines) do
        local chars = line:split(seperator)()

        for x, char in ipairs(chars) do
            res:setInbounds(x, y, char)
        end
    end

    return res
end

-- Returns nil if no resizing is needed
function tilesStruct.resizeMatrix(tiles, width, height, default, offsetX, offsetY)
    local tilesMatrix = tiles.matrix
    local tilesWidth, tilesHeight = tilesMatrix:size()

    local offsetXPos = math.max(offsetX or 0, 0)
    local offsetYPos = math.max(offsetY or 0, 0)
    local offsetXNeg = math.min(offsetX or 0, 0)
    local offsetYNeg = math.min(offsetY or 0, 0)

    local hasOffset = offsetX ~= 0 and offsetY ~= 0

    if tilesWidth ~= width or tilesHeight ~= height or hasOffset then
        local newTilesMatrix = matrix.filled(default, width, height)

        for x = 1, width do
            for y = 1, height do
                newTilesMatrix:set(x + offsetXPos, y + offsetYPos, tilesMatrix:get(x - offsetXNeg, y - offsetYNeg, default))
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