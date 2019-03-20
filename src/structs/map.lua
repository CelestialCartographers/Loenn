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

    for i, d <- data.__children do
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
    local res = {}

    res.__name = "Map"
    res._package = map.package

    res.__children = {}

    if map.fillers:len > 0 then
        local children = {}

        for i, filler <- map.fillers do
            table.insert(children, fillerStruct.encode(filler))
        end

        table.insert(res.__children, {
            __name = "Filler",
            __children = children
        })
    end
    
    if map.rooms:len > 0 then
        local children = {}

        for i, room <- map.rooms do
            table.insert(children, roomStruct.encode(room))
        end

        table.insert(res.__children, {
            __name = "levels",
            __children = children
        })
    end

    return res
end

return mapStruct