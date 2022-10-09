local utils = require("utils")
local matrix = require("utils.matrix")
local drawing = require("utils.drawing")

local atlases = require("atlases")
local runtimeAtlas = require("runtime_atlas")

local arrayImage
local arrayImageLookup

local function getLayeredImage()
    return runtimeAtlas.canvasArray
end

local smartDrawingBatch = {}

local orderedDrawingBatchMt = {}
orderedDrawingBatchMt.__index = {}

local spriteBatchMode = "static"
local spriteBatchSize = 1000

function orderedDrawingBatchMt.__index:addFromDrawable(drawable)
    local typ = utils.typeof(drawable)

    if drawable.getDrawableSprite then
        local sprites = drawable:getDrawableSprite()

        if #sprites == 0 then
            self:addFromDrawable(sprites)

        else
            for _, sprite in ipairs(sprites) do
                self:addFromDrawable(sprite)
            end
        end

        -- These should count as drawableSprites for batching reasons
        -- Otherwise a new batch would be created on every rectangle
        typ = "drawableSprite"

    elseif typ == "drawableSprite" then
        local image = drawable.meta and drawable.meta.image
        local layer = drawable.meta and drawable.meta.layer

        if image then
            local offsetX = drawable.offsetX or math.floor((drawable.justificationX or 0.0) * drawable.meta.realWidth + drawable.meta.offsetX)
            local offsetY = drawable.offsetY or math.floor((drawable.justificationY or 0.0) * drawable.meta.realHeight + drawable.meta.offsetY)

            local colorChanged = not utils.sameColor(drawable.color, self._lastColor)
            local targetImage = layer and self._layeredImage or image

            if not layer and image ~= self._lastImage or self._lastType ~= "drawableSprite" or not self._lastBatch or layer and self._batchTarget ~= self._layeredImage then
                self._lastBatch = love.graphics.newSpriteBatch(targetImage, spriteBatchSize, spriteBatchMode)
                self._batchTarget = targetImage
                self._imagesCurrentBatch = 0
                self._lastColor = nil

                table.insert(self._drawables, self._lastBatch)
            end

            if colorChanged then
                if drawable.color then
                    local color = drawable.color
                    local r, g, b, a = color[1], color[2], color[3], color[4]

                    self._lastBatch:setColor(r, g, b, a)

                else
                    self._lastBatch:setColor(1.0, 1.0, 1.0, 1.0)
                end
            end

            self._lastImage = image
            self._lastColor = drawable.color
            self._imagesCurrentBatch += 1

            if layer then
                self._lastBatch:addLayer(layer, drawable.quad, drawable.x, drawable.y, drawable.rotation, drawable.scaleX, drawable.scaleY, offsetX, offsetY)

            else
                self._lastBatch:add(drawable.quad, drawable.x, drawable.y, drawable.rotation, drawable.scaleX, drawable.scaleY, offsetX, offsetY)
            end
        end

    elseif typ == "drawableFunction" then
        -- Handles colors itself
        table.insert(self._drawables, drawable)
    end

    self._lastType = typ
end

function orderedDrawingBatchMt.__index:draw()
    -- Initial and previous color
    local ir, ig, ib, ia
    local pr, pg, pb, pa
    local changedColor = false

    for _, drawable in ipairs(self._drawables) do
        local typ = utils.typeof(drawable)

        if typ == "drawableFunction" then
            drawable:draw()

        else
            love.graphics.draw(drawable, 0, 0)
        end
    end

    if changedColor then
        love.graphics.setColor(ir, ig, ib, ia)
    end
end

function orderedDrawingBatchMt.__index:clear()
    self._drawables = {}

    self._imagesCurrentBatch = 0
    self._lastBatch = nil
    self._lastImage = nil
    self._batchTarget = nil
    self._lastColor = nil
    self._lastType = nil
end

function orderedDrawingBatchMt.__index:release()
    for _, drawable in ipairs(self._drawables) do
        if utils.typeof(drawable) == "SpriteBatch" then
            drawable:release()
        end
    end

    return true
end

function smartDrawingBatch.createOrderedBatch()
    local res = {
        _type = "orderedDrawingBatch",
    }

    local layeredImage = getLayeredImage()

    res._drawables = {}

    res._imagesCurrentBatch = 0
    res._batchTarget = nil
    res._lastBatch = nil
    res._lastImage = nil
    res._lastColor = nil
    res._lastType = nil
    res._layeredImage = layeredImage

    return setmetatable(res, orderedDrawingBatchMt)
end


local unorderedDrawingBatchMt = {}
unorderedDrawingBatchMt.__index = {}

function unorderedDrawingBatchMt.__index:add(meta, quad, x, y, r, sx, sy, jx, jy, ox, oy)
    local image = meta.image
    local layer = meta.layer

    local batch = self._lookup[image]

    if not batch then
        batch = love.graphics.newSpriteBatch(image, spriteBatchSize, spriteBatchMode)

        self._lookup[image] = batch
        self._lookupRemovedIndices[image] = {}
    end

    local removedIndices = self._lookupRemovedIndices[image]

    -- Check for open slot, use if it exists
    if #removedIndices > 0 then
        local replaceId = table.remove(removedIndices)

        return self:set(replaceId, meta, quad, x, y, r, sx, sy, jx, jy, ox, oy)
    end

    local offsetX = ox or ((jx or 0.0) * meta.realWidth + meta.offsetX)
    local offsetY = oy or ((jy or 0.0) * meta.realHeight + meta.offsetY)

    if layer then
        return batch:addLayer(layer, quad, x or 0, y or 0, r or 0, sx or 1, sy or 1, offsetX, offsetY)

    else
        return batch:add(quad, x or 0, y or 0, r or 0, sx or 1, sy or 1, offsetX, offsetY)
    end
end

function unorderedDrawingBatchMt.__index:set(id, meta, quad, x, y, r, sx, sy, jx, jy, ox, oy)
    local image = meta.image
    local layer = meta.layer

    local offsetX = ox or ((jx or 0.0) * meta.realWidth + meta.offsetX)
    local offsetY = oy or ((jy or 0.0) * meta.realHeight + meta.offsetY)

    local batch = self._lookup[image]

    if batch then
        if layer then
            batch:setLayer(id, layer, quad, x or 0, y or 0, r or 0, sx or 1, sy or 1, offsetX, offsetY)

        else
            return batch:set(id, quad, x or 0, y or 0, r or 0, sx or 1, sy or 1, offsetX, offsetY)
        end

        return id
    end

    return false
end

function unorderedDrawingBatchMt.__index:remove(id, meta)
    local image = meta.image
    local layer = meta.layer
    local batch = self._lookup[image]
    local removedIndices = self._lookupRemovedIndices[image]

    if layer then
        batch:setLayer(id, layer, 0, 0, 0, 0, 0)

    else
        batch:set(id, 0, 0, 0, 0, 0)
    end

    table.insert(removedIndices, id)
end

function unorderedDrawingBatchMt.__index:setColor(meta, r, g, b, a)
    if type(r) == "table" then
        r, g, b, a = unpack(r)
    end

    local image = meta.image
    local batch = self._lookup[image]

    batch:setColor(r, g, b, a)
end

function unorderedDrawingBatchMt.__index:getColor(meta)
    local image = meta.image
    local batch = self._lookup[image]

    return batch:getColor()
end

function unorderedDrawingBatchMt.__index:addFromDrawable(drawable)
    if utils.typeof(drawable) == "drawableSprite" then
        return self:add(drawable.meta, drawable.quad, drawable.x, drawable.y, drawable.rotation, drawable.scaleX, drawable.scaleY, drawable.justificationX, drawable.justificationY, drawable.offsetX, drawable.offsetY)
    end
end

function unorderedDrawingBatchMt.__index:setFromDrawable(id, drawable)
    if utils.typeof(drawable) == "drawableSprite" then
        return self:set(id, drawable.meta, drawable.quad, drawable.x, drawable.y, drawable.rotation, drawable.scaleX, drawable.scaleY, drawable.justificationX, drawable.justificationY, drawable.offsetX, drawable.offsetY)
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
    res._lookupRemovedIndices = {}

    return setmetatable(res, unorderedDrawingBatchMt)
end


local function getSectorCoordinate(x, y, sectorWidth, sectorHeight)
    return math.floor((x - 1) / sectorWidth) + 1, math.floor((y - 1) / sectorHeight) + 1
end

local matrixDrawingBatchMt = {}
matrixDrawingBatchMt.__index = {}

function matrixDrawingBatchMt.__index:set(x, y, meta, quad, drawX, drawY, r, sx, sy, jx, jy, ox, oy)
    if meta then
        local previousValue = self._matrix:get(x, y)

        if previousValue then
            self:remove(x, y, meta)
        end

        local id = self._batch:add(meta, quad, drawX, drawY, r, sx, sy, jx, jy, ox, oy)

        self._matrix:set(x, y, true)
        self._idMatrix:set(x, y, id)

    else
        self:remove(x, y, meta)
    end
end

function matrixDrawingBatchMt.__index:get(x, y, default)
    return self._matrix:get(x, y, default)
end

function matrixDrawingBatchMt.__index:remove(x, y, meta)
    local id = self._idMatrix:get(x, y, false)
    local batch = self._batch

    if id then
        batch:remove(id, meta)

        self._idMatrix:set(x, y, false)
        self._matrix:set(x, y, false)
    end
end

function matrixDrawingBatchMt.__index:setColor(meta, r, g, b, a)
    local batch = self._batch

    return batch:setColor(meta, r, g, b, a)
end

function matrixDrawingBatchMt.__index:getColor(meta)
    local batch = self._batch

    return batch:getColor(meta)
end

function matrixDrawingBatchMt.__index:draw()
    self._batch:draw()
end

function matrixDrawingBatchMt.__index:release()
    self._batch:release()
end

-- Only works with textures
function smartDrawingBatch.createMatrixBatch(default, width, height, cellWidth, cellHeight)
    local res = {
        _type = "matrixDrawingBatch",
    }

    res._width = width
    res._height = height

    res._cellWidth = cellWidth
    res._cellHeight = cellHeight

    res._matrix = matrix.filled(default, width, height)

    -- Track where the cells are drawn
    res._idMatrix = matrix.filled(false, width, height)
    res._batch = smartDrawingBatch.createUnorderedBatch()

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

    local image = meta.image
    local layer = meta.layer

    if layer then
        love.graphics.drawLayer(image, layer, quad, sectionX, sectionY, rot or 0, sx or 1, sy or 1, offsetX, offsetY)

    else
        love.graphics.draw(image, quad, sectionX, sectionY, rot or 0, sx or 1, sy or 1, offsetX, offsetY)
    end
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

        local image = meta.image
        local layer = meta.layer

        if layer then
            love.graphics.drawLayer(image, layer, quad, sectionX, sectionY, rot or 0, sx or 1, sy or 1, offsetX, offsetY)

        else
            love.graphics.draw(image, quad, sectionX, sectionY, rot or 0, sx or 1, sy or 1, offsetX, offsetY)
        end
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
        self:remove(x, y)
    end
end

function gridCanvasBatchMt.__index:remove(x, y)
    self._matrix:set(x, y, false)

    table.insert(self._dirtyScissorCells, {x, y, clearCanvasArea})
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
    if self._canvas then
        self:updateDirtyRegions()

        love.graphics.draw(self._canvas, 0, 0)
    end
end

function gridCanvasBatchMt.__index:release()
    local released = self._canvas:release()

    if released then
        self._canvas = nil
    end

    return released
end

-- Works like the matrix drawing batch, but assumes that a "cell" can be replaced by painting over its space and then drawn again
-- Does not work when the grid items can cause overlapping
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