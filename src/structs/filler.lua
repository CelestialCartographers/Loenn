local fillerStruct = {}

fillerStruct.recommendedMinimumWidth = 8
fillerStruct.recommendedMinimumHeight = 8

function fillerStruct.decode(data)
    local filler = {
        _type = "filler"
    }

    filler.x = data.x or 0
    filler.y = data.y or 0

    filler.width = data.w or 0
    filler.height = data.h or 0

    return filler
end

function fillerStruct.encode(rect)
    local res = {}

    res.__name = "rect"

    res.x = rect.x
    res.y = rect.y

    res.w = rect.width
    res.h = rect.height

    return res
end

-- Resize a filler from a given side
-- Amount in tiles
function fillerStruct.directionalResize(filler, side, amount)
    local offsetX = side == "left" and amount or 0
    local offsetY = side == "up" and amount or 0
    local offsetWidth = (side == "left" or side == "right") and amount or 0
    local offsetHeight = (side == "up" or side == "down") and amount or 0

    if filler.width + offsetWidth <= 0 or filler.height + offsetHeight <= 0 then
        return false
    end

    filler.x -= offsetX
    filler.y -= offsetY
    filler.width += offsetWidth
    filler.height += offsetHeight

    return true
end

-- Moves amount * step in the direction
-- Step defaults to 8, being a tile
function fillerStruct.move(filler, amountX, amountY, step)
    step = step or 8

    local moveAmountX = math.floor(amountX * step / 8)
    local moveAmountY = math.floor(amountY * step / 8)

    filler.x += moveAmountX
    filler.y += moveAmountY
end

-- Pixel position of the filler
function fillerStruct.getPosition(filler)
    return filler.x * 8, filler.y * 8
end

-- Pixel size of the filler
function fillerStruct.getSize(filler)
    return filler.width * 8, filler.height * 8
end

return fillerStruct