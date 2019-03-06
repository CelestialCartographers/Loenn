local fileLocations = require("file_locations")
local spriteLoader = require("sprite_loader")

local celesteAtlasFolder = fileLocations.getResourceDir() .. "/Atlases/"
local gameplayMeta = fileLocations.getResourceDir() .. "/Atlases/Gameplay.meta"

local gameplayAtlas = spriteLoader.loadSpriteAtlas(gameplayMeta, celesteAtlasFolder)

return {
    gameplay = gameplayAtlas
}