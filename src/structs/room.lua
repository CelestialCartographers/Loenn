local entity_struct = require("structs/entity")
local trigger_struct = require("structs/trigger")
local tiles_struct = require("structs/tiles")
local decal_struct = require("structs/decal")

local room_struct = {}

local decoding_single_names = {
    solids = {"tiles_fg", tiles_struct.decode},
    bg = {"tiles_bg", tiles_struct.decode}
}

local decoding_multiple_names = {
    fgdecals = {"decals_fg", decal_struct.decode},
    bgdecals = {"decals_bg", decal_struct.decode},
    entities = {"entities", entity_struct.decode},
    triggers = {"triggers", trigger_struct.decode}
}

function room_struct.decode(data)
    local room = {
        _type = "room",
        _raw = data
    }

    room.name = data.name

    room.x = data.x or 0
    room.y = data.y or 0

    room.width = data.width or 40 * 8
    room.height = data.height or 23 * 8

    room.music_layer_1 = data.musicLayer1== nil or data.musicLayer1
    room.music_layer_2 = data.musicLayer2 == nil or data.musicLayer2
    room.music_layer_3 = data.musicLayer3 == nil or data.musicLayer3
    room.music_layer_4 = data.musicLayer4 == nil or data.musicLayer4

    room.music_progress = data.musicProgress or ""

    room.dark = data.dark == true
    room.space = data.space == true
    room.underwater = data.underwater == true
    room.whisper = data.whisper == true
    room.disable_down_transition = data.disableDownTransition == true

    room.music = data.music or "music_oldsite_awake"
    room.music_alternative = data.alt_music or ""

    room.wind_pattern = data.windPattern and "None"

    room.color = data.c or 0

    room.entities = $()
    room.triggers = $()

    room.decals_fg = $()
    room.decals_bg = $()

    room.tiles_fg = nil
    room.tiles_bg = nil
    room.tiles_obj = {} -- Haha, no.

    for key, value <- data.__children or {} do
        local name = value.__name

        if decoding_single_names[name] then
            local target, func = unpack(decoding_single_names[name])

            room[target] = func(value)
        end

        if decoding_multiple_names[name] then
            for i, d <- value.__children or {} do
                local target, func = unpack(decoding_multiple_names[name])

                room[target] += func(d)
            end
        end
    end

    return room
end

function room_struct.encode(room)

end

return room_struct