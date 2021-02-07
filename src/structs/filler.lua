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

    filler.x -= offsetX
    filler.y -= offsetY
    filler.width += offsetWidth
    filler.height += offsetHeight
end

-- Moves amount * step in the direction
-- Step defaults to 8, being a tile
function fillerStruct.directionalMove(filler, side, amount, step)
    step = step or 8

    local moveAmount = math.floor(amount * step / 8)

    if side == "left" then
        filler.x -= moveAmount

    elseif side == "right" then
        filler.x += moveAmount

    elseif side == "up" then
        filler.y -= moveAmount

    elseif side == "down" then
        filler.y += moveAmount
    end
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