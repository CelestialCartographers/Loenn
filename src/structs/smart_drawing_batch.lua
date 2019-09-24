local utils = require("utils")
local matrix = require("matrix")

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

        if drawable.color and type(drawable.color) == "table" then
            -- Special case
            local newDrawable = {_type = "drawableFunction"}

            function newDrawable.func(drawable)
                drawable:draw()
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
            self._lastBatch:add(drawable.quad, drawable.x, drawable.y, drawable.rotation, drawable.scaleX, drawable.scaleY, offsetX, offsetY)
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

function orderedDrawingBatchMt.__index.clear(self)
    self._drawables = {}
    self._lastBatch = nil
    self._lastImage = nil
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

function unorderedDrawingBatchMt.__index.add(self, meta, quad, x, y, r, sx, sy, jx, jy, ox, oy)
    local image = meta.image

    local offsetX = ox or ((jx or 0.0) * meta.realWidth + meta.offsetX)
    local offsetY = oy or ((jy or 0.0) * meta.realHeight + meta.offsetY)

    self._lookup[image] = self._lookup[image] or love.graphics.newSpriteBatch(image, 1000, spriteBatchMode)
    self._lookup[image]:add(quad, x or 0, y or 0, r or 0, sx or 1, sy or 1, offsetX, offsetY)
end

function unorderedDrawingBatchMt.__index.addFromDrawable(self, drawable)
    if utils.typeof(drawable) == "drawableSprite" then
        self:add(drawable.meta, drawable.quad, drawable.x, drawable.y, drawable.rotation, drawable.scaleX, drawable.scaleY, drawable.jx, drawable.jy, drawable.offsetX, drawable.offsetY)
    end
end

function unorderedDrawingBatchMt.__index.draw(self)
    for image, batch <- self._lookup do
        love.graphics.draw(batch, 0, 0)
    end
end

function unorderedDrawingBatchMt.__index.clear(self)
    self._lookup = {}
end

-- Only works with textures
function smartDrawingBatch.createUnorderedBatch()
    local res = {
        _type = "unorderedDrawingBatch",
    }

    res._lookup = {}

    return setmetatable(res, unorderedDrawingBatchMt)
end


local function getSectorCoordinate(x, y, sectorWidth, sectorHeight)
    return math.floor((x - 1) / sectorWidth) + 1, math.floor((y - 1) / sectorHeight) + 1
end

local matrixDrawingBatchMt = {}
matrixDrawingBatchMt.__index = {}

function matrixDrawingBatchMt.__index.set(self, x, y, meta, quad, drawX, drawY, r, sx, sy, jx, jy, ox, oy)
    -- Exit early if we already have the value set
    if self._dirtyIfNotEqual then
        local target = self._matrix:get(x, y)

        if target and target[1] == meta and target[2] == quad then
            return
        end
    end

    local sectorX, sectorY = getSectorCoordinate(x, y, self._sectorWidth, self._sectorHeight)

    if meta then
        self._matrix:set(x, y, {meta, quad, drawX, drawY, r, sx, sy, jx, jy, ox, oy})

    else
        self._matrix:set(x, y, false)
    end

    self._dirty:set(sectorX, sectorY, true)
    self._canRender = false
end

function matrixDrawingBatchMt.__index.get(self, x, y, def)
    return self._matrix:get(x, y, def)
end

function matrixDrawingBatchMt.__index.populateBatch(self, sectorX, sectorY)
    local batch = self._batches:getInbounds(sectorX, sectorY)

    local startX = 1 + (sectorX - 1) * self._sectorWidth
    local startY = 1 + (sectorY - 1) * self._sectorHeight

    for x = startX, startX + self._sectorWidth - 1 do
        for y = startY, startY + self._sectorHeight - 1 do
            local target = self._matrix:get(x, y)

            if target then
                batch:add(unpack(target))
            end
        end
    end
end

-- Clears and updates all dirty sector batches
function matrixDrawingBatchMt.__index.updateBatches(self)
    local width, height = self._batches:size()

    for x = 1, width do
        for y = 1, height do
            if self._dirty:getInbounds(x, y) then
                self._batches:getInbounds(x, y):clear()
                self._dirty:setInbounds(x, y, false)
                self:populateBatch(x, y)
            end
        end
    end
end

function matrixDrawingBatchMt.__index.draw(self)
    if not self._canRender then
        self:updateBatches()
    end

    local width, height = self._batches:size()

    for x = 1, width do
        for y = 1, height do
            self._batches:getInbounds(x, y):draw()
        end
    end

    self._canRender = true
end

-- Only works with textures
-- dirtyIfNotEqual makes it so a sector is only marked as dirty if the "new" value isn't the same as the one already stored
function smartDrawingBatch.createMatrixBatch(default, width, height, sectorWidth, sectorHeight, dirtyIfNotEqual)
    local res = {
        _type = "matrixDrawingBatch",
    }

    sectorWidth = sectorWidth or width
    sectorHeight = sectorHeight or height

    local sectorsMatrixWidth, sectorsMatrixHeight = math.ceil(width / sectorWidth), math.ceil(height / sectorHeight)

    res._width = width
    res._height = height
    res._sectorWidth = sectorWidth
    res._sectorHeight = sectorHeight
    res._matrix = matrix.filled(default, width, height)
    res._batches = matrix.filled(false, sectorsMatrixWidth, sectorsMatrixHeight)
    res._dirty = matrix.filled(true, sectorsMatrixWidth, sectorsMatrixHeight)
    res._canRender = false
    res._dirtyIfNotEqual = dirtyIfNotEqual == nil or dirtyIfNotEqual

    for x = 1, sectorsMatrixWidth do
        for y = 1, sectorsMatrixHeight do
            res._batches:setInbounds(x, y, smartDrawingBatch.createUnorderedBatch())
        end
    end

    return setmetatable(res, matrixDrawingBatchMt)
end


return smartDrawingBatch