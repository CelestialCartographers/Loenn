local entityStruct = require("structs.entity")
local triggerStruct = require("structs.trigger")
local tilesStruct = require("structs.tiles")
local objectTilesStruct = require("structs.object_tiles")
local decalStruct = require("structs.decal")

local roomStruct = {}

local structTilesNames = {
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

roomStruct.recommendedMinimumWidth = 320
roomStruct.recommendedMinimumHeight = 184

function roomStruct.decode(data)
    local room = {
        _type = "room"
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
    room.ambienceProgress = data.ambienceProgress or ""

    room.dark = data.dark == true
    room.space = data.space == true
    room.underwater = data.underwater == true
    room.whisper = data.whisper == true
    room.disableDownTransition = data.disableDownTransition == true

    room.delayAlternativeMusicFade = data.delayAltMusicFade == true

    room.music = data.music or "music_oldsite_awake"
    room.musicAlternative = data.alt_music or ""

    room.windPattern = data.windPattern or "None"

    room.color = data.c or 0

    room.cameraOffsetX = data.cameraOffsetX or 0
    room.cameraOffsetY = data.cameraOffsetY or 0

    room.entities = {}
    room.triggers = {}

    room.decalsFg = {}
    room.decalsBg = {}

    room.tilesFg = nil
    room.tilesBg = nil
    room.tilesObj = nil

    local roomTilesWidth = math.ceil(room.width / 8)
    local roomTilesHeight = math.ceil(room.height / 8)

    for key, value in ipairs(data.__children or {}) do
        local name = value.__name

        if structTilesNames[name] and value then
            local handler = structTilesNames[name]
            local target, struct = handler[1], handler[2]

            room[target] = struct.resize(struct.decode(value), roomTilesWidth, roomTilesHeight)
        end

        if structMutlipleNames[name] then
            for i, d in ipairs(value.__children or {}) do
                local handler = structMutlipleNames[name]
                local target, struct = handler[1], handler[2]

                table.insert(room[target], struct.decode(d))
            end
        end
    end

    return room
end

-- Resize a room from a given side
-- Also cuts off background tiles
-- Amount in tiles
function roomStruct.directionalResize(room, side, amount)
    room.tilesFg = tilesStruct.directionalResize(room.tilesFg, side, amount)
    room.tilesBg = tilesStruct.directionalResize(room.tilesBg, side, amount)
    room.tilesObj = objectTilesStruct.directionalResize(room.tilesObj, side, amount)

    local offsetX = side == "left" and amount * 8 or 0
    local offsetY = side == "up" and amount * 8 or 0
    local offsetWidth = (side == "left" or side == "right") and amount * 8 or 0
    local offsetHeight = (side == "up" or side == "down") and amount * 8 or 0

    room.x -= offsetX
    room.y -= offsetY
    room.width += offsetWidth
    room.height += offsetHeight

    for _, targets in ipairs({room.entities, room.triggers, room.decalsFg, room.decalsBg}) do
        for _, target in ipairs(targets) do
            target.x += offsetX
            target.y += offsetY
        end
    end
end

-- Moves amount * step in the direction
-- Step defaults to 8, being a tile
function roomStruct.directionalMove(room, side, amount, step)
    step = step or 8

    if side == "left" then
        room.x -= amount * step

    elseif side == "right" then
        room.x += amount * step

    elseif side == "up" then
        room.y -= amount * step

    elseif side == "down" then
        room.y += amount * step
    end
end

function roomStruct.getPosition(room)
    return room.x, room.y
end

function roomStruct.getSize(room)
    return room.width, room.height
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

    res.musicProgress = room.musicProgress
    res.ambienceProgress = room.ambienceProgress

    res.musicLayer1 = room.musicLayer1
    res.musicLayer2 = room.musicLayer2
    res.musicLayer3 = room.musicLayer3
    res.musicLayer4 = room.musicLayer4

    res.dark = room.dark
    res.space = room.space
    res.underwater = room.underwater
    res.whisper = room.whisper
    res.disableDownTransition = room.disableDownTransition

    res.delayAltMusicFade = room.delayAlternativeMusicFade

    res.music = room.music
    res.alt_music = room.musicAlternative

    res.windPattern = room.windPattern

    res.c = room.color

    res.cameraOffsetX = room.cameraOffsetX
    res.cameraOffsetY = room.cameraOffsetY

    for raw, meta in pairs(structTilesNames) do
        local key, struct = unpack(meta)

        if room[key] then
            local encoded = struct.encode(room[key])

            encoded.__name = raw

            table.insert(res.__children, encoded)
        end
    end

    for raw, meta in pairs(structMutlipleNames) do
        local key, struct = unpack(meta)

        if #room[key] > 0 then
            local children = {}

            for j, target in ipairs(room[key]) do
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