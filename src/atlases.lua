local fileLocations = require("file_locations")
local spriteLoader = require("sprite_loader")
local utils = require("utils")

local atlases = {}

local celesteAtlasFolder = utils.joinpath(fileLocations.getCelesteDir(), "Content", "Graphics", "Atlases")
local gameplayMeta = utils.joinpath(celesteAtlasFolder, "Gameplay.meta")

atlases.gameplay = spriteLoader.loadSpriteAtlas(gameplayMeta, celesteAtlasFolder)

return atlases