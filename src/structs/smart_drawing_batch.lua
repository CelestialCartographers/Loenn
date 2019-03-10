local utils = require("utils")

local smartDrawingBatch = {}

local smartDrawingBatchMt = {}
smartDrawingBatchMt.__index = {}

function smartDrawingBatchMt.__index.add(self, drawable)
    local typ = utils.typeof(drawable)

    if typ == "drawableSprite" then
        local image = drawable.meta.image

        local offsetX = drawable.offsetX or (drawable.jx * drawable.meta.realWidth + drawable.meta.offsetX)
        local offsetY = drawable.offsetY or (drawable.jy * drawable.meta.realHeight + drawable.meta.offsetY)

        if drawable.color then
            -- Special case
            local newDrawable = {_type = "drawableFunction"}

            function drawable.func(drawable)
                local prevColor = {love.graphics.getColor()}

                love.graphics.setColor(drawable.color)
                love.graphics.draw(drawable.meta.image, drawable.meta.quad, drawable.x, drawable.y, drawable.rotation, drawable.scaleX, drawable.scaleY, offsetX, offsetY)
                love.graphics.setColor(prevColor)
            end

            newDrawable.depth = drawable.depth
            newDrawable.args = {drawable}

            typ = "drawableFunction"
            drawable = newDrawable

        else
            if image ~= self._prevImage or self._prevTyp ~= "drawableSprite" then
                self._drawables += love.graphics.newSpriteBatch(image)
            end

            self._drawables[self._drawables:len]:add(drawable.meta.quad, drawable.x, drawable.y, drawable.rotation, drawable.scaleX, drawable.scaleY, offsetX, offsetY)

            self._prevImage = image
        end
    end


    if typ == "drawableFunction" then
        self._drawables += drawable
    end

    self._prevTyp = typ
end

function smartDrawingBatchMt.__index.draw(self)
    for i, drawable <- self._drawables do
        local typ = utils.typeof(drawable)

        if typ == "drawableFunction" then
            drawable.func(unpack(drawable.args))

        else
            love.graphics.draw(drawable, 0, 0)
        end
    end
end

function smartDrawingBatch.createBatch()
    local res = {
        _type = "smartDrawingBatch",
    }

    res._drawables = $()

    return setmetatable(res, smartDrawingBatchMt)
end


return smartDrawingBatch