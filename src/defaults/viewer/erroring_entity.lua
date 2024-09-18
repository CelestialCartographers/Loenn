local colors = require("consts.colors")
local utils = require("utils")
local configs = require("configs")

local missing = {}

missing.mode = "fill"
missing.color = colors.entityErrorColor
missing.nodeLineRenderType = "line"

function missing.rectangle(room, entity)
    local x = entity.x or 0
    local y = entity.y or 0

    local width = entity.width or 0
    local height = entity.height or 0

    local drawX = width > 0 and x or x - 2
    local drawY = height > 0 and y or y - 2
    local drawWidth = math.max(width, 5)
    local drawHeight = math.max(height, 5)

    return utils.rectangle(drawX, drawY, drawWidth, drawHeight)
end

function missing.nodeRectangle(room, entity, node, i)
    return missing.rectangle(room, node)
end

return missing