local fileLocations = require("file_locations")
local spriteLoader = require("sprite_loader")

local atlases = {}

local celesteAtlasFolder = fileLocations.getStorageDir() .. "/Atlases/"
local gameplayMeta = fileLocations.getStorageDir() .. "/Atlases/Gameplay.meta"

atlases.gameplay = spriteLoader.loadSpriteAtlas(gameplayMeta, celesteAtlasFolder)

return atlases