local roomStruct = require("structs/room")
local fillerStruct = require("structs/filler")

local mapStruct = {}

function mapStruct.decode(data)
    local map = {
        _type = "map",
        _raw = data
    }

    map.package = data._package -- TODO?
    map.style = {} -- TODO

    map.rooms = $()
    map.fillers = $()

    for i, d <- data.__children[1].__children do
        if d.__name == "levels" then
            for j, room <- d.__children or {} do
                map.rooms += roomStruct.decode(room)
            end

        elseif d.__name == "Filler" then
            for j, filler <- d.__children or {} do
                map.fillers += fillerStruct.decode(filler)
            end
        end
    end

    return map
end

function mapStruct.encode(map)

end

return mapStruct