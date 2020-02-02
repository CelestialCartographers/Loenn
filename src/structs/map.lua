local tasks = require("task")
local roomStruct = require("structs.room")
local fillerStruct = require("structs.filler")
local styleStruct = require("structs.style")

local mapStruct = {}

function mapStruct.decode(data)
    local map = {
        _type = "map",
        _raw = data
    }

    map.package = data._package

    map.rooms = {}
    map.fillers = {}

    map.stylesFg = {}
    map.stylesBg = {}

    for i, d in ipairs(data.__children) do
        if d.__name == "levels" then
            for j, room in ipairs(d.__children or {}) do
                table.insert(map.rooms, roomStruct.decode(room))
                tasks.yield()
            end

        elseif d.__name == "Filler" then
            for j, filler in ipairs(d.__children or {}) do
                table.insert(map.fillers, fillerStruct.decode(filler))
            end

            tasks.yield()

        elseif d.__name == "Style" then
            for j, style in ipairs(d.__children or {}) do
                if style.__name == "Foregrounds" then
                    map.stylesFg = styleStruct.decode(style)

                elseif style.__name == "Backgrounds" then
                    map.stylesBg = styleStruct.decode(style)
                end
            end

            tasks.yield()
        end
    end

    tasks.update(map)

    return map
end

function mapStruct.encode(map)
    local res = {}

    res.__name = "Map"
    res._package = map.package

    res.__children = {}

    if map.fillers and #map.fillers > 0 then
        local children = {}

        for i, filler in ipairs(map.fillers) do
            table.insert(children, fillerStruct.encode(filler))
        end

        table.insert(res.__children, {
            __name = "Filler",
            __children = children
        })
    end

    if map.rooms and #map.rooms > 0 then
        local children = {}

        for i, room in ipairs(map.rooms) do
            table.insert(children, roomStruct.encode(room))
        end

        table.insert(res.__children, {
            __name = "levels",
            __children = children
        })

        tasks.yield()
    end

    local style = {
        __name = "Style",
        __children = {}
    }

    table.insert(style.__children, {
        __name = "Foregrounds",
        __children = styleStruct.encode(map.stylesFg)
    })

    table.insert(style.__children, {
        __name = "Backgrounds",
        __children = styleStruct.encode(map.stylesBg)
    })

    table.insert(res.__children, style)

    tasks.update(res)

    return res
end

return mapStruct