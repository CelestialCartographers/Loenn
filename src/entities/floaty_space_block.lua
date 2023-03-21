local fakeTilesHelper = require("helpers.fake_tiles")
local utils = require("utils")
local matrixLib = require("utils.matrix")

local floatySpaceBlock = {}

floatySpaceBlock.name = "floatySpaceBlock"
floatySpaceBlock.depth = -9000
floatySpaceBlock.placements = {
    name = "floaty_space_block",
    data = {
        tiletype = "3",
        disableSpawnOffset = false,
        width = 8,
        height = 8
    }
}

floatySpaceBlock.fieldInformation = fakeTilesHelper.getFieldInformation("tiletype")

-- Filter by floaty space blocks sharing the same tiletype
local function getSearchPredicate(entity)
    return function(target)
        return entity._name == target._name and entity.tiletype == target.tiletype
    end
end

function floatySpaceBlock.sprite(room, entity)
    local relevantBlocks = utils.filter(getSearchPredicate(entity), room.entities)
    local firstEntity = relevantBlocks[1] == entity

    if firstEntity then
        -- Can use simple render, nothing to merge together
        if #relevantBlocks == 1 then
            return fakeTilesHelper.getEntitySpriteFunction("tiletype", false)(room, entity)
        end

        return fakeTilesHelper.getCombinedEntitySpriteFunction(relevantBlocks, "tiletype")(room)
    end

    local entityInRoom = utils.contains(entity, relevantBlocks)

    -- Entity is from a placement preview
    if not entityInRoom then
        return fakeTilesHelper.getEntitySpriteFunction("tiletype", false)(room, entity)
    end
end

return floatySpaceBlock