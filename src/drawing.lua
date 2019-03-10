local drawing = {}

-- Assumes everything uses the same base image
function drawing.createSpriteBatch(sprites)
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

function drawing.drawSprite(spriteMeta, x, y, r, sx, sy, ox, oy)
    love.graphics.draw(spriteMeta.image, spriteMeta.quad, x, y, r, sx, sy, ox, oy)
end

function drawing.getCurvePoint(start, stop, control, percent)
    local startMul = (1 - percent)^2
    local controlMul = 2 * (1 - percent) * percent
    local stopMul = percent^2

    return {
        start[1] * startMul + control[1] * controlMul + stop[1] * stopMul,
        start[2] * startMul + control[2] * controlMul + stop[2] * stopMul,
    }
end

function drawing.getSimpleCurve(start, stop, control, resolution)
    local control = control or {(start[1] + stop[1]) / 2, (start[2] + stop[2]) / 2}
    local resolution = resolution or 16
    local res = $()

    for i = 0, resolution do
        res += drawing.getCurvePoint(start, stop, control, i / resolution)
    end

    return res()
end

return drawing