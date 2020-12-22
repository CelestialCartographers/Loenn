local utils = require("utils")
local matrix = require("matrix")
local drawing = require("drawing")

local smartDrawingBatch = {}

local orderedDrawingBatchMt = {}
orderedDrawingBatchMt.__index = {}

local spriteBatchMode = "static"
local spriteBatchSize = 1000

-- TODO - Make tinting smarter? Batch based on color?
function orderedDrawingBatchMt.__index:addFromDrawable(drawable)
    local typ = utils.typeof(drawable)

    if typ == "drawableRectangle" then
        -- TODO - Support multiple sprites for outlined rectangles
        self:addFromDrawable(drawable:getDrawableSprite())

        -- These should count as drawableSprites for batching reasons
        -- Otherwise a new batch would be created on every rectangle
        typ = "drawableSprite"

    elseif typ == "drawableSprite" then
        local image = drawable.meta and drawable.meta.image

        if image then
            local offsetX = drawable.offsetX or ((drawable.justificationX or 0.0) * drawable.meta.realWidth + drawable.meta.offsetX)
            local offsetY = drawable.offsetY or ((drawable.justificationY or 0.0) * drawable.meta.realHeight + drawable.meta.offsetY)

            local colorChanged = not utils.sameColor(drawable.color, self._lastColor)

            if image ~= self._lastImage or self._lastType ~= "drawableSprite" or colorChanged or not self._lastBatch then
                self._lastBatch = love.graphics.newSpriteBatch(image, spriteBatchSize, spriteBatchMode)
                self._imagesCurrentBatch = 0
                table.insert(self._drawables, {self._lastBatch, drawable.color})
            end

            self._lastImage = image
            self._lastColor = drawable.color
            self._imagesCurrentBatch += 1
            self._lastBatch:add(drawable.quad, drawable.x, drawable.y, drawable.rotation, drawable.scaleX, drawable.scaleY, offsetX, offsetY)
        end

    elseif typ == "drawableFunction" then
        -- Handles colors itself
        table.insert(self._drawables, {drawable, nil})
    end

    self._lastType = typ
end

function orderedDrawingBatchMt.__index:draw()
    local r, g, b, a = love.graphics.getColor()

    for _, element in ipairs(self._drawables) do
        local drawable, color = element[1], element[2] or {1.0, 1.0, 1.0, 1.0}
        local typ = utils.typeof(drawable)

        love.graphics.setColor(color)

        if typ == "drawableFunction" then
            drawable:draw()

        else
            love.graphics.draw(drawable, 0, 0)
        end
    end

    love.graphics.setColor(r, g, b, a)
end

function orderedDrawingBatchMt.__index:clear()
    self._drawables = {}

    self._imagesCurrentBatch = 0
    self._lastBatch = nil
    self._lastImage = nil
    self._lastColor = nil
    self._lastType = nil
end

function orderedDrawingBatchMt.__index:release()
    for _, element in ipairs(self._drawables) do
        if utils.typeof(element) == "SpriteBatch" then
            element:release()
        end
    end

    return true
end

function smartDrawingBatch.createOrderedBatch()
    local res = {
        _type = "orderedDrawingBatch",
    }

    res._drawables = {}

    res._imagesCurrentBatch = 0
    res._lastBatch = nil
    res._lastImage = nil
    res._lastColor = nil
    res._lastType = nil

    return setmetatable(res, orderedDrawingBatchMt)
end


local unorderedDrawingBatchMt = {}
unorderedDrawingBatchMt.__index = {}

function unorderedDrawingBatchMt.__index:add(meta, quad, x, y, r, sx, sy, jx, jy, ox, oy)
    local image = meta.image

    local offsetX = ox or ((jx or 0.0) * meta.realWidth + meta.offsetX)
    local offsetY = oy or ((jy or 0.0) * meta.realHeight + meta.offsetY)

    self._lookup[image] = self._lookup[image] or love.graphics.newSpriteBatch(image, spriteBatchSize, spriteBatchMode)
    self._lookup[image]:add(quad, x or 0, y or 0, r or 0, sx or 1, sy or 1, offsetX, offsetY)
end

function unorderedDrawingBatchMt.__index:addFromDrawable(drawable)
    if utils.typeof(drawable) == "drawableSprite" then
        self:add(drawable.meta, drawable.quad, drawable.x, drawable.y, drawable.rotation, drawable.scaleX, drawable.scaleY, drawable.justificationX, drawable.justificationY, drawable.offsetX, drawable.offsetY)
    end
end

function unorderedDrawingBatchMt.__index:draw()
    for image, batch in pairs(self._lookup) do
        love.graphics.draw(batch, 0, 0)
    end
end

function unorderedDrawingBatchMt.__index:clear()
    self._lookup = {}
end

function unorderedDrawingBatchMt.__index:release()
    for _, batch in pairs(self._lookup) do
        batch:release()
    end

    return true
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

function matrixDrawingBatchMt.__index:set(x, y, meta, quad, drawX, drawY, r, sx, sy, jx, jy, ox, oy)
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

function matrixDrawingBatchMt.__index:get(x, y, default)
    return self._matrix:get(x, y, default)
end

function matrixDrawingBatchMt.__index:populateBatch(sectorX, sectorY)
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
function matrixDrawingBatchMt.__index:updateBatches()
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

function matrixDrawingBatchMt.__index:draw()
    if not self._canRender then
        self:updateBatches()
    end

    -- We don't need the x, y coordinates, iterate like a normal table
    for i, batch in ipairs(self._batches) do
        batch:draw()
    end

    self._canRender = true
end

function matrixDrawingBatchMt.__index:release()
    -- TODO - Implement when needed
    return false
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
    res._batches = matrix.fromFunction(smartDrawingBatch.createUnorderedBatch, sectorsMatrixWidth, sectorsMatrixHeight)
    res._dirty = matrix.filled(true, sectorsMatrixWidth, sectorsMatrixHeight)
    res._canRender = false
    res._dirtyIfNotEqual = dirtyIfNotEqual == nil or dirtyIfNotEqual

    return setmetatable(res, matrixDrawingBatchMt)
end


local function getSectionStart(batch, x, y)
    local cellWidth = batch._cellWidth
    local cellHeight = batch._cellHeight

    local sectionX = (x - 1) * cellWidth
    local sectionY = (y - 1) * cellHeight

    return sectionX, sectionY, cellWidth, cellHeight
end

-- Assumes Canvas is set for performance reasons
-- Doesn't clear scissor itself for performance reasons, clear manually after batch processing
local function clearCanvasArea(batch, x, y)
    local sectionX, sectionY, cellWidth, cellHeight = getSectionStart(batch, x, y)

    love.graphics.setScissor(sectionX, sectionY, cellWidth, cellHeight)
    love.graphics.clear(0.0, 0.0, 0.0, 0.0)
end

-- Assumes Canvas is set for performance reasons
local function drawCanvasArea(batch, x, y, meta, quad, drawX, drawY, rot, sx, sy, jx, jy, ox, oy)
    local sectionX, sectionY, cellWidth, cellHeight = getSectionStart(batch, x, y)
    local offsetX = ox or ((jx or 0.0) * meta.realWidth + meta.offsetX)
    local offsetY = oy or ((jy or 0.0) * meta.realHeight + meta.offsetY)

    love.graphics.draw(meta.image, quad, sectionX, sectionY, rot or 0, sx or 1, sy or 1, offsetX, offsetY)
end

-- Assumes Canvas is set for performance reasons
-- Doesn't clear scissor itself for performance reasons, clear manually after batch processing
local function redrawCanvasArea(batch, x, y, meta, quad, drawX, drawY, rot, sx, sy, jx, jy, ox, oy)
    if meta then
        local sectionX, sectionY, cellWidth, cellHeight = getSectionStart(batch, x, y)
        local offsetX = ox or ((jx or 0.0) * meta.realWidth + meta.offsetX)
        local offsetY = oy or ((jy or 0.0) * meta.realHeight + meta.offsetY)

        love.graphics.setScissor(sectionX, sectionY, cellWidth, cellHeight)
        love.graphics.clear(0.0, 0.0, 0.0, 0.0)

        love.graphics.draw(meta.image, quad, sectionX, sectionY, rot or 0, sx or 1, sy or 1, offsetX, offsetY)
    end
end

local gridCanvasBatchMt = {}
gridCanvasBatchMt.__index = {}

function gridCanvasBatchMt.__index:set(x, y, meta, quad, drawX, drawY, r, sx, sy, jx, jy, ox, oy)
    -- Exit early if we already have the value set
    if self._ignoreSettingSameValue then
        local target = self._matrix:get(x, y)

        if target and target[1] == meta and target[2] == quad then
            return
        end
    end

    if meta then
        local prev = self._matrix:get(x, y)

        self._matrix:set(x, y, {meta, quad, drawX, drawY, r, sx, sy, jx, jy, ox, oy})

        -- If we previously had a value we also need to clear first
        if prev then
            table.insert(self._dirtyScissorCells, {x, y, redrawCanvasArea})

        else
            table.insert(self._dirtyDrawCells, {x, y})
        end

    else
        self._matrix:set(x, y, false)

        table.insert(self._dirtyScissorCells, {x, y, clearCanvasArea})
    end
end

function gridCanvasBatchMt.__index:get(x, y, default)
    return self._matrix:get(x, y, default)
end

function gridCanvasBatchMt.__index:updateDirtyRegions()
    if #self._dirtyDrawCells > 0 or #self._dirtyScissorCells > 0 then
        local previousCanvas = love.graphics.getCanvas()

        local sx, sy, sw, sh = love.graphics.getScissor()

        love.graphics.push()
        love.graphics.origin()
        love.graphics.setCanvas(self._canvas)

        for i, cell in ipairs(self._dirtyDrawCells) do
            local x, y = cell[1], cell[2]
            local value = self._matrix:get(x, y)

            drawCanvasArea(self, x, y, unpack(value))
        end

        for i, cell in ipairs(self._dirtyScissorCells) do
            local x, y, func = cell[1], cell[2], cell[3]
            local value = self._matrix:get(x, y, false)

            if value then
                func(self, x, y, unpack(value))

            else
                func(self, x, y)
            end
        end

        love.graphics.setScissor(sx, sy, sw, sh)
        love.graphics.setCanvas(previousCanvas)
        love.graphics.pop()

        self._dirtyScissorCells = {}
        self._dirtyDrawCells = {}

        return true
    end

    return false
end

function gridCanvasBatchMt.__index:draw()
    self:updateDirtyRegions()

    love.graphics.draw(self._canvas, 0, 0)
end

function gridCanvasBatchMt.__index:release()
    return self._canvas:release()
end

-- Works like the matrix drawing batch, but assumes that a "cell" can be replaced by painting over its space and then drawn again
-- Does not work when the grid items can cause overlaping
-- ignoreSettingSameValue doesn't cause redraws when the value seemingly hasn't changed
function smartDrawingBatch.createGridCanvasBatch(default, width, height, cellWidth, cellHeight, ignoreSettingSameValue)
    local res = {
        _type = "gridCanvasDrawingBatch",
    }

    res._width = width
    res._height = height
    res._cellWidth = cellWidth
    res._cellHeight = cellHeight
    res._ignoreSettingSameValue = ignoreSettingSameValue
    res._matrix = matrix.filled(default, width, height)
    res._canvas = love.graphics.newCanvas(math.max(width * 8, 1), math.max(height * 8, 1))

    -- Two different tables to increase the amount of assumptions we can make
    res._dirtyScissorCells = {}
    res._dirtyDrawCells = {}

    return setmetatable(res, gridCanvasBatchMt)
end

return smartDrawingBatch