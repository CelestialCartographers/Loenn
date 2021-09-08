local utils = require("utils")

local connectedEntities = {}

-- Useful for adding a placement preview entity into the entities list
function connectedEntities.appendIfMissing(entities, target)
    local seen = false

    for _, entity in ipairs(entities) do
        if entity == target then
            seen = true

            break
        end
    end

    if not seen then
        table.insert(entities, target)
    end

    return seen
end

function connectedEntities.getEntityRectangles(entities)
    local rectangles = {}
    local seenExtra = false

    for _, entity in ipairs(entities) do
        table.insert(rectangles, utils.rectangle(entity.x, entity.y, entity.width, entity.height))

        if entity == extra then
            seenExtra = true
        end
    end

    return rectangles
end

function connectedEntities.hasAdjacent(entity, offsetX, offsetY, rectangles, checkWidth, checkHeight)
    local x, y = entity.x or 0, entity.y or 0
    local checkX, checkY = x + offsetX, y + offsetY

    for _, rect in ipairs(rectangles) do
        if utils.aabbCheckInline(rect.x, rect.y, rect.width, rect.height, checkX, checkY, checkWidth or 8, checkHeight or 8) then
            return true
        end
    end

    return false
end

return connectedEntities