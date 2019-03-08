local utils = require("utils")

local tiles = {}

function tiles.convertTileString(tiles)
    local tiles = tiles:gsub("\r\n", "\n")
    local lines = tiles:split("\n")

    local cols = 0
    local rows = lines:len

    for i, line <- lines do
        cols = math.max(cols, #line)
    end

    local res = table.filled("0", {cols, rows})

    for y, line <- lines do
        local chars = $(line):split(1)()

        for x, char <- chars do
            res[x, y] = char
        end
    end

    return res
end

return tiles