-- Only add placement for the Everest NPC
-- Everest version has a lot more options

local npc = {}

npc.name = "npc"
npc.depth = 100
npc.justification = {0.5, 1.0}

local defaultTexture = "characters/oldlady/idle00"
local npcTextures = {
    granny = "characters/oldlady/idle00",
    theo = "characters/theo/theo00",
    oshiro = "characters/oshiro/oshiro24",
    evil = "characters/badeline/sleep00",
    badeline = "characters/badeline/sleep00"
}

function npc.texture(room, entity)
    local name = entity.npc or "granny_00_house"
    local character = string.lower(name:split("_")[1])

    return npcTextures[character] or defaultTexture
end

local everestNpc = {}

everestNpc.name = "everest/npc"
everestNpc.depth = 100
everestNpc.justification = {0.5, 1.0}
everestNpc.fieldInformation = {
    spriteRate = {
        fieldType = "integer",
    },
    approachDistance = {
        fieldType = "integer",
    },
    indicatorOffsetX = {
        fieldType = "integer",
    },
    indicatorOffsetY = {
        fieldType = "integer",
    }
}
everestNpc.placements = {
    name = "npc",
    data = {
        spriteRate = 1,
        dialogId = "",
        onlyOnce = true,
        endLevel = false,
        flipX = false,
        flipY = false,
        approachWhenTalking = false,
        approachDistance = 16,
        indicatorOffsetX = 0,
        indicatorOffsetY = 0
    }
}

function everestNpc.scale(room, entity)
    local scaleX = entity.flipX and -1 or 1
    local scaleY = entity.flipY and -1 or 1

    return scaleX, scaleY
end

function everestNpc.texture(room, entity)
    local texture = string.format("characters/%s00", entity.sprite or "")

    return texture
end

return {
    npc,
    everestNpc
}