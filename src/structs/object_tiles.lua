local matrix = require("matrix")
local tilesStruct = require("structs/tiles")

local objectTilesStruct = {}

function objectTilesStruct.decode(data)
    local tiles = {
        _type = "object_tiles",
        _raw = data
    }

    tiles.matrix = tilesStruct.tileStringToMatrix(data.innerText or "", ",", "-1")

    return tiles
end

function objectTilesStruct.encode(tiles)
    local res = {}

    res.innerText = tilesStruct.matrixToTileString(tiles.matrix, ",", "-1")

    return res
end

return objectTilesStruct