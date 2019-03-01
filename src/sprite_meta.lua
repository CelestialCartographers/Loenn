local utils = require("utils")
local binfile = require("binfile")

local function loadSprites(metaFn, spritesFn)
    fh = io.open(metaFn)
    res = {}

    spritesImage = utils.loadImageAbsPath(spritesFn)
    spritesWidth, spritesHeight = spritesImage:getDimensions()

    -- Get rid of headers
    binfile.readLong(fh)
    binfile.readString(fh)
    binfile.readLong(fh)

    count = binfile.readShort(fh)

    for i = 1, count do
        dataFile = binfile.readString(fh)
        sprites = binfile.readSignedShort(fh)

        for j = 1, sprites do
            pathRaw = binfile.readString(fh)
            path = ($(pathRaw)):split("\\"):concat("/")

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

            sprite.quad = love.graphics.newQuad(sprite.x - sprite.offsetX, sprite.y - sprite.offsetY, sprite.width, sprite.height, spritesWidth, spritesHeight)
            res[path] = sprite
        end
    end

    fh:close()

    return res
end

return {
    loadSprites = loadSprites
}