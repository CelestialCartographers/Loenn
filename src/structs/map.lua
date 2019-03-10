local room_struct = require("structs/room")
local filler_struct = require("structs/filler")

local map_struct = {}

function map_struct.decode(data)
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
                map.rooms += room_struct.decode(room)
            end

        elseif d.__name == "Filler" then
            for j, filler <- d.__children or {} do
                map.fillers += filler_struct.decode(filler)
            end
        end
    end

    return map
end

function map_struct.encode(map)

end

return map_struct