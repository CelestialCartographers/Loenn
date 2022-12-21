local sceneHandler = require("scene_handler")
local dependencyFinder = require("dependencies")
local utils = require("utils")
local configs = require("configs")
local mods = require("mods")

local sanitizer = {}

function sanitizer.beforeSave(filename, state)
    if configs.editor.checkDependenciesOnSave then
        local modPath = mods.getFilenameModPath(filename)

        -- Make sure mod is packaged
        if modPath then
            local currentModMetadata = mods.getModMetadataFromPath(modPath) or {}
            local side = state.side

            local usedMods = dependencyFinder.analyzeSide(side)
            local dependedOnModNames = mods.getDependencyModNames(currentModMetadata)
            local dependedOnLookup = table.flip(dependedOnModNames)
            local missingMods = {}

            for modName, _ in pairs(usedMods) do
                if not dependedOnMods[modName] then
                    table.insert(missingMods, modName)
                end
            end

            if #missingMods > 0 then
                sceneHandler.sendEvent("saveSanitizerDependenciesMissing", missingMods, usedMods, dependedOnMods)
            end
        end
    end
end

return sanitizer