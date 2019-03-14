local utils = require("utils")

local smartDrawingBatch = {}

local orderedDrawingBatchMt = {}
orderedDrawingBatchMt.__index = {}

local spriteBatchMode = "static"

-- TODO - Make tinting smarter? Batch based on color?
function orderedDrawingBatchMt.__index.addFromDrawable(self, drawable)
    local typ = utils.typeof(drawable)

    if typ == "drawableSprite" then
        local image = drawable.meta.image

        local offsetX = drawable.offsetX or ((drawable.jx or 0.0) * drawable.meta.realWidth + drawable.meta.offsetX)
        local offsetY = drawable.offsetY or ((drawable.jy or 0.0) * drawable.meta.realHeight + drawable.meta.offsetY)

        if drawable.color then
            -- Special case
            local newDrawable = {_type = "drawableFunction"}

            function newDrawable.func(drawable)
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
                self._lastBatch = love.graphics.newSpriteBatch(image, 1000, spriteBatchMode)
                table.insert(self._drawables, self._lastBatch)
            end

            self._prevImage = image
            self._lastBatch:add(drawable.meta.quad, drawable.x, drawable.y, drawable.rotation, drawable.scaleX, drawable.scaleY, offsetX, offsetY)
        end
    end


    if typ == "drawableFunction" then
        table.insert(self._drawables, drawable)
    end

    self._prevTyp = typ
end

function orderedDrawingBatchMt.__index.draw(self)
    for i, drawable <- self._drawables do
        local typ = utils.typeof(drawable)

        if typ == "drawableFunction" then
            drawable.func(unpack(drawable.args))

        else
            love.graphics.draw(drawable, 0, 0)
        end
    end
end

function smartDrawingBatch.createOrderedBatch()
    local res = {
        _type = "orderedDrawingBatch",
    }

    res._drawables = {}
    res._lastBatch = nil
    res._lastImage = nil

    return setmetatable(res, orderedDrawingBatchMt)
end


local unorderedDrawingBatchMt = {}
unorderedDrawingBatchMt.__index = {}

function unorderedDrawingBatchMt.__index.add(self, meta, x, y, r, sx, sy, jx, jy, ox, oy)
    local image = meta.image
    
    local offsetX = offsetX or ((jx or 0.0) * meta.realWidth + meta.offsetX)
    local offsetY = offsetY or ((jy or 0.0) * meta.realHeight + meta.offsetY)

    self._lookup[image] = self._lookup[image] or love.graphics.newSpriteBatch(image, 1000, spriteBatchMode)
    self._lookup[image]:add(meta.quad, x or 0, y or 0, r or 0, sx or 1, sy or 1, offsetX, offsetY)
end

function unorderedDrawingBatchMt.__index.addFromDrawable(self, drawable)
    if utils.typeof(drawable) == "drawableSprite" then
        self:add(drawable.meta, drawable.x, drawable.y, drawable.rotation, drawable.scaleX, drawable.scaleY, drawable.jx, drawable.jy, drawable.offsetX, drawable.offsetY)
    end
end

function unorderedDrawingBatchMt.__index.draw(self)
    for image, batch <- self._lookup do
        love.graphics.draw(batch, 0, 0)
    end
end

-- Only works with textures
function smartDrawingBatch.createUnorderedBatch()
    local res = {
        _type = "unorderedDrawingBatch",
    }

    res._lookup = {}

    return setmetatable(res, unorderedDrawingBatchMt)
end


return smartDrawingBatch