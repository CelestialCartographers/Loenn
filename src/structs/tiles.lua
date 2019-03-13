local matrix = require("matrix")

local tilesStruct = {}

function tilesStruct.convertTileString(tiles)
    local tiles = tiles:gsub("\r\n", "\n")
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

    tiles.matrix = tilesStruct.convertTileString(data.innerText or "")

    return tiles
end

function tilesStruct.encode(tiles)

end

return tilesStruct