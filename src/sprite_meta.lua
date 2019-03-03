local utils = require("utils")
local binfile = require("binfile")

local function loadSprites(metaFn, spritesFn)
    fh = io.open(metaFn, "rb")

    spritesImage = utils.loadImageAbsPath(spritesFn)
    spritesWidth, spritesHeight = spritesImage:getDimensions

    res = {
        _image = spritesImage,
        _width = spritesWidth,
        _height = spritesHeight
    }

    -- Get rid of headers
    binfile.readSignedLong(fh)
    binfile.readString(fh)
    binfile.readSignedLong(fh)

    count = binfile.readShort(fh)

    for i = 1, count do
        dataFile = binfile.readString(fh)
        sprites = binfile.readSignedShort(fh)

        for j = 1, sprites do
            pathRaw = binfile.readString(fh)
            path = pathRaw:gsub("\\", "/")

            sprite = {
                x = binfile.readSignedShort(fh),
                y = binfile.readSignedShort(fh),
                
                width = binfile.readSignedShort(fh),
                height = binfile.readSignedShort(fh),
                
                offsetX = binfile.readSignedShort(fh),
                offsetY = binfile.readSignedShort(fh),
                realWidth = binfile.readSignedShort(fh),
                realHeight = binfile.readSignedShort(fh),

                image = spritesImage,
                filename = spritesFn
            }

            sprite.quad = love.graphics.newQuad(sprite.x, sprite.y, sprite.width, sprite.height, spritesWidth, spritesHeight)
            res[path] = sprite
        end
    end

    fh:close()

    return res
end

return {
    loadSprites = loadSprites
}