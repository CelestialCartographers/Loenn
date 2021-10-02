local matrix = require("utils.matrix")
local tilesStruct = require("structs.tiles")

local objectTilesStruct = {}

function objectTilesStruct.resize(tiles, width, height, default)
    return tilesStruct.resize(tiles, width, height, default or "-1")
end

function objectTilesStruct.fromMatrix(m, raw)
    local tiles = {
        _type = "object_tiles",
        raw = raw
    }

    tiles.matrix = m

    return tiles
end

function objectTilesStruct.directionalResize(tiles, side, amount, default)
    return tilesStruct.directionalResize(tiles, side, amount, default or "-1")
end

function objectTilesStruct.decode(data)
    return objectTilesStruct.fromMatrix(tilesStruct.tileStringToMatrix(data.innerText or "", ",", "-1"))
end

function objectTilesStruct.encode(tiles)
    local res = {}

    res.innerText = tilesStruct.matrixToTileStringMinimized(tiles.matrix, ",", "-1")

    return res
end

return objectTilesStruct