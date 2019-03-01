-- TODO - Use spritebatch for supah ~~mario brothers two~~ fast rendering
local function drawSprites()

end

local function drawSprite(spriteMeta, x, y, r, sx, sy, ox, oy)
    love.graphics.draw(spriteMeta.image, spriteMeta.quad, x, y, r, sx, sy, ox, oy)
end

return {
    drawSprites = drawSprites,
    drawSprite = drawSprite
}