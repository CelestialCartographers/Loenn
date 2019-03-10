local entityStruct = require("structs/entity")
local triggerStruct = require("structs/trigger")
local tilesStruct = require("structs/tiles")
local decalStruct = require("structs/decal")

local roomStruct = {}

local decodingSingleNames = {
    solids = {"tilesFg", tilesStruct.decode},
    bg = {"tilesBg", tilesStruct.decode}
}

local decodingMutlipleNames = {
    fgdecals = {"decalsFg", decalStruct.decode},
    bgdecals = {"decalsBg", decalStruct.decode},
    entities = {"entities", entityStruct.decode},
    triggers = {"triggers", triggerStruct.decode}
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

    room.entities = $()
    room.triggers = $()

    room.decalsFg = $()
    room.decalsBg = $()

    room.tilesFg = nil
    room.tilesBg = nil
    room.tilesObj = {} -- Haha, no.

    for key, value <- data.__children or {} do
        local name = value.__name

        if decodingSingleNames[name] then
            local target, func = unpack(decodingSingleNames[name])

            room[target] = func(value)
        end

        if decodingMutlipleNames[name] then
            for i, d <- value.__children or {} do
                local target, func = unpack(decodingMutlipleNames[name])

                room[target] += func(d)
            end
        end
    end

    return room
end

function roomStruct.encode(room)

end

return roomStruct