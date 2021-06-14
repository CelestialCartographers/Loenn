local drawableSprite = require("structs.drawable_sprite")
local drawableRectangle = require("structs.drawable_rectangle")
local utils = require("utils")
local drawing = require("drawing")

local heartDoor = {}

heartDoor.name = "heartGemDoor"
heartDoor.depth = 0
heartDoor.nodeLimits = {0, 1}
heartDoor.placements = {
    name = "door",
    data = {
        width = 40,
        requires = 0,
        startHidden = false
    }
}

local wallColor = {47 / 255, 187 / 255, 255 / 255, 255 / 255}
local heartPadding = 4
local edgeTexture = "objects/heartdoor/edge"
local heartTexture = "objects/heartdoor/icon00"

local function heartsWidth(heartSpriteWidth, hearts)
    return hearts * (heartSpriteWidth + heartPadding) - heartPadding
end

local function heartsPossible(edgeSpriteWidth, heartSpriteWidth, width, required)
    local rowWidth = width - 2 * edgeSpriteWidth

    for i = 0, required do
        if heartsWidth(heartSpriteWidth, i) > rowWidth then
            return i - 1
        end
    end

    return required
end

function heartDoor.sprite(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local width = entity.width or 40
    local roomWidth, roomHeight = room.width, room.height
    local hearts = entity.requires or 0

    local edgeSpriteSample = drawableSprite.fromTexture(edgeTexture, entity)
    local heartSpriteSample = drawableSprite.fromTexture(heartTexture, entity)

    local edgeWidth, edgeHeight = edgeSpriteSample.meta.width, edgeSpriteSample.meta.height
    local heartWidth, heartHeight = heartSpriteSample.meta.width, heartSpriteSample.meta.height

    local rectangleSprite = drawableRectangle.fromRectangle("fill", x, 0, width, roomHeight, wallColor)

    local position = {x = x, y = 0}
    local sprites = {rectangleSprite}

    for i = 0, roomHeight - 1, edgeHeight do
        local leftSprite = drawableSprite.fromTexture(edgeTexture, position)
        local rightSprite = drawableSprite.fromTexture(edgeTexture, position)

        leftSprite:setJustification(0.5, 0.0)
        leftSprite:setScale(-1, 1)
        leftSprite:addPosition(edgeWidth - 1, i)

        rightSprite:setJustification(0.5, 0.0)
        rightSprite:addPosition(width - edgeWidth + 1, i)

        table.insert(sprites, leftSprite)
        table.insert(sprites, rightSprite)
    end

    if hearts > 0 then
        local fits = heartsPossible(edgeWidth, heartWidth, width, hearts)
        local rows = math.ceil(hearts / fits)

        for row = 1, rows do
            local displayedHearts = heartsPossible(edgeWidth, heartWidth, width, hearts)
            local drawWidth = heartsWidth(heartWidth, displayedHearts)

            local startX = x + utils.round((width - drawWidth) / 2) + edgeWidth - 2
            local startY = y - utils.round(rows / 2 * (heartHeight + heartPadding)) - heartPadding - 2

            for col = 1, displayedHearts do
                local drawX = startX + (col - 1) * (heartWidth + heartPadding) - heartPadding
                local drawY = startY + row * (heartHeight + heartPadding) - heartPadding

                local sprite = drawableSprite.fromTexture(heartTexture, {
                    x = drawX,
                    y = drawY
                })

                sprite:setJustification(0.0, 0.0)

                table.insert(sprites, sprite)
            end

            hearts -= displayedHearts
        end
    end

    return sprites
end

function heartDoor.drawSelected(room, layer, entity, color)
    local nodes = entity.nodes

    if nodes and #nodes > 0 then
        local x, y = entity.x or 0, entity.y or 0
        local nx, ny = nodes[1].x, nodes[1].y
        local width = entity.width or 40

        drawing.callKeepOriginalColor(function()
            love.graphics.setColor(1.0, 0.0, 0.0, 1.0)

            love.graphics.rectangle("fill", x, ny, width, 1)
            love.graphics.rectangle("fill", x, 2 * y - ny, width, 1)

            love.graphics.rectangle("fill", nx - 8, ny, width + 16, 8)
        end)
    end
end

function heartDoor.selection(room, entity)
    local nodes = entity.nodes
    local x, y = entity.x or 0, entity.y or 0
    local width = entity.width or 40
    local roomWidth, roomHeight = room.width, room.height

    local mainRectangle = utils.rectangle(x, 0, width, roomHeight)

    if nodes and #nodes > 0 then
        local nx, ny = nodes[1].x, nodes[1].y
        local nodeRectangle = utils.rectangle(nx - 8, ny, width + 16, 8)

        return mainRectangle, {nodeRectangle}
    end

    return mainRectangle
end

return heartDoor