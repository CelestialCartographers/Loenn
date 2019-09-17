local entityStruct = require("structs/entity")
local triggerStruct = require("structs/trigger")
local tilesStruct = require("structs/tiles")
local objectTilesStruct = require("structs/object_tiles")
local decalStruct = require("structs/decal")

local roomStruct = {}

local structSingleNames = {
    solids = {"tilesFg", tilesStruct},
    bg = {"tilesBg", tilesStruct},
    objtiles = {"tilesObj", objectTilesStruct}
}

local structMutlipleNames = {
    fgdecals = {"decalsFg", decalStruct},
    bgdecals = {"decalsBg", decalStruct},
    entities = {"entities", entityStruct},
    triggers = {"triggers", triggerStruct}
}

function roomStruct.decode(data)
    local room = {
        _type = "room",
        _raw = data
    }

    room.name = data.name

    room.x = data.x or 0
    room.y = data.y or 0

    room.width = data.width or 40 * 8
    room.height = data.height or 23 * 8

    room.musicLayer1 = data.musicLayer1== nil or data.musicLayer1
    room.musicLayer2 = data.musicLayer2 == nil or data.musicLayer2
    room.musicLayer3 = data.musicLayer3 == nil or data.musicLayer3
    room.musicLayer4 = data.musicLayer4 == nil or data.musicLayer4

    room.musicProgress = data.musicProgress or ""

    room.dark = data.dark == true
    room.space = data.space == true
    room.underwater = data.underwater == true
    room.whisper = data.whisper == true
    room.disableDownTransition = data.disableDownTransition == true

    room.music = data.music or "music_oldsite_awake"
    room.musicAlternative = data.alt_music or ""

    room.windPattern = data.windPattern and "None"

    room.color = data.c or 0

    room.entities = {}
    room.triggers = {}

    room.decalsFg = {}
    room.decalsBg = {}

    room.tilesFg = nil
    room.tilesBg = nil
    room.tilesObj = nil

    for key, value <- data.__children or {} do
        local name = value.__name

        if structSingleNames[name] and value then
            local target, struct = unpack(structSingleNames[name])

            room[target] = struct.decode(value)
        end

        if structMutlipleNames[name] then
            for i, d <- value.__children or {} do
                if d then
                    local target, struct = unpack(structMutlipleNames[name])

                    table.insert(room[target], struct.decode(d))
                end
            end
        end
    end

    return room
end

function roomStruct.encode(room)
    local res = {}

    res.__name = "level"
    res.__children = {}

    res.name = room.name

    res.x = room.x
    res.y = room.y

    res.width = room.width
    res.height = room.height

    res.musicLayer1 = room.musicLayer1
    res.musicLayer2 = room.musicLayer2
    res.musicLayer3 = room.musicLayer3
    res.musicLayer4 = room.musicLayer4

    res.dark = room.dark
    res.space = room.space
    res.underwater = room.underwater
    res.whisper = room.whisper
    res.disableDownTransition = room.disableDownTransition

    res.music = room.music
    res.alt_music = room.musicAlternative

    res.windPattern = room.windPattern

    res.c = room.color

    for raw, meta <- structSingleNames do
        local key, struct = unpack(meta)

        if room[key] then
            local encoded = struct.encode(room[key])

            encoded.__name = raw

            table.insert(res.__children, encoded)
        end
    end

    for raw, meta <- structMutlipleNames do
        local key, struct = unpack(meta)

        if #room[key] > 0 then
            local children = {}

            for j, target <- room[key] do
                table.insert(children, struct.encode(target))
            end

            table.insert(res.__children, {
                __name = raw,
                __children = children
            })
        end
    end

    return res
end

return roomStruct