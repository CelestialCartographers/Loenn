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

    local lines = tiles:split("\n")

    local cols = 0
    local rows = lines:len

    for i, line <- lines do
        cols = math.max(cols, #line)
    end

    local res = matrix.filled(empty, cols, rows)

    for y, line <- lines do
        local chars = line:split(seperator)

        for x, char <- chars do
            res:setInbounds(x, y, char)
        end
    end

    return res
end

function tilesStruct.decode(data)
    local tiles = {
        _type = "tiles",
        _raw = data
    }

    tiles.matrix = tilesStruct.tileStringToMatrix(data.innerText or "")

    return tiles
end

function tilesStruct.encode(tiles)
    local res = {}

    res.innerText = tilesStruct.matrixToTileStringMinimized(tiles.matrix)

    return res
end

return tilesStruct