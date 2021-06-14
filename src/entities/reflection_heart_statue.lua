local drawableSprite = require("structs.drawable_sprite")

local reflectionHeartStatue = {}

reflectionHeartStatue.name = "reflectionHeartStatue"
reflectionHeartStatue.depth = 8999
reflectionHeartStatue.nodeVisibility = "always"
reflectionHeartStatue.nodeLineRenderType = "line"
reflectionHeartStatue.nodeLimits = {5, 5}
reflectionHeartStatue.placements = {
    name = "statue"
}

local statueTexture = "objects/reflectionHeart/statue"
local torchTexture = "objects/reflectionHeart/torch00"
local gemTexture = "objects/reflectionHeart/gem"

-- U, L, DR, UR, L, UL
local codeColors = {
    {240 / 255, 240 / 255, 240 / 255},
    {145 / 255, 113 / 255, 242 / 255},
    {10 / 255, 68 / 255, 224 / 255},
    {179 / 255, 45 / 255, 0 / 255},
    {145 / 255, 113 / 255, 242 / 255},
    {255 / 255, 205 / 255, 55 / 255}
}

local function hintTexture(index)
    return string.format("objects/reflectionHeart/hint%02d", index)
end


function reflectionHeartStatue.sprite(room, entity)
    local sprite = drawableSprite.fromTexture(statueTexture, entity)

    sprite:setJustification(0.5, 1.0)

    return sprite
end

function reflectionHeartStatue.nodeSprite(room, entity, node, nodeIndex)
    if nodeIndex <= 4 then
        local torchSprite = drawableSprite.fromTexture(torchTexture, node)
        local hintSprite = drawableSprite.fromTexture(hintTexture(nodeIndex - 1), node)

        hintSprite:setJustification(0.5, 0.5)
        hintSprite:addPosition(0, 28)

        torchSprite:setJustification(0.0, 0.0)
        torchSprite:addPosition(-32, -64)

        return {torchSprite, hintSprite}

    else
        local sprites = {}
        local codeLength = #codeColors

        for i = 0, codeLength - 1 do
            local gemSprite = drawableSprite.fromTexture(gemTexture, node)
            local offsetX = (i - (codeLength - 1) / 2) * 24

            gemSprite:addPosition(offsetX, 0)
            gemSprite:setColor(codeColors[i + 1])

            sprites[i + 1] = gemSprite
        end

        return sprites
    end
end

return reflectionHeartStatue