local fileLocations = require("file_locations")
local spriteLoader = require("sprite_loader")
local utils = require("utils")
local tasks = require("task")

local atlases = {}

local celesteAtlasFolder = utils.joinpath(fileLocations.getCelesteDir(), "Content", "Graphics", "Atlases")
local gameplayMeta = "Gameplay.meta"

-- TODO - Add config option to disable caching?
function atlases.startAtlasLoadingTask(atlasKey, metaFn, atlasDir)
    tasks.newTask(
        (-> spriteLoader.getCacheOrLoadSpriteAtlas(metaFn, atlasDir)),
        function(task)
            atlases[atlasKey] = task.result
        end
    )
end

function atlases.initCelesteAtlasesTask()
    atlases.startAtlasLoadingTask("gameplay", gameplayMeta, celesteAtlasFolder)
end

return atlases