-- Assumes everything uses the same base image
local function createSpriteBatch(sprites)
    local image = sprites[1].meta.image
    local batch = love.graphics.newSpriteBatch(image)

    for i, sprite <- sprites do
        if sprite.meta.image ~= image then
            print("Sprite " .. tostring(i) .. " is using a different image from the sprite batch.")
        end

        batch:add(sprite.meta.quad, sprite.x, sprite.y, sprite.r, sprite.sx, sprite.sy, sprite.ox, sprite.oy, sprite.kx, sprite.ky)
    end

    return batch
end

local function drawSprite(spriteMeta, x, y, r, sx, sy, ox, oy)
    love.graphics.draw(spriteMeta.image, spriteMeta.quad, x, y, r, sx, sy, ox, oy)
end

return {
    createSpriteBatch = createSpriteBatch,
    drawSprite = drawSprite
}