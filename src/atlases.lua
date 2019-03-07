local fileLocations = require("file_locations")
local spriteLoader = require("sprite_loader")

local atlases = {}

local celesteAtlasFolder = fileLocations.getResourceDir() .. "/Atlases/"
local gameplayMeta = fileLocations.getResourceDir() .. "/Atlases/Gameplay.meta"

atlases.gameplay = spriteLoader.loadSpriteAtlas(gameplayMeta, celesteAtlasFolder)

return atlases