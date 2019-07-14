local matrix = require("matrix")

local tilesStruct = {}

-- TODO - Add minimized version
function tilesStruct.matrixToTileString(matrix, seperator, empty)
    seperator = seperator or ""
    empty = empty or "0"

    local width, height = matrix:size

    local lines = {}

    for y = 1, height do
        local rowData = {}

        for x = 1, width do
            table.insert(rowData, matrix:getInbounds(x, y))
        end

        table.insert(lines, table.concat(rowData, seperator))
    end

    return table.concat(lines, "\n")
end

function tilesStruct.tileStringToMatrix(tiles)
    tiles = tiles:gsub("\r\n", "\n")
    
    local lines = tiles:split("\n")

    local cols = 0
    local rows = lines:len

    for i, line <- lines do
        cols = math.max(cols, #line)
    end

    local res = matrix.filled("0", cols, rows)

    for y, line <- lines do
        local chars = line:split(1)

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

    res.innerText = tilesStruct.matrixToTileString(tiles.matrix)

    return res
end

return tilesStruct