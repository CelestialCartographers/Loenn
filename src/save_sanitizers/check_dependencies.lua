local sceneHandler = require("scene_handler")
local dependencyFinder = require("dependencies")
local configs = require("configs")
local persistence = require("persistence")
local mods = require("mods")

local sanitizer = {}

local function preparePersistence()
    if not persistence.dependencySaveSanitizer then
        persistence.dependencySaveSanitizer = {}
    end

    if not persistence.dependencySaveSanitizer.remindMeLater then
        persistence.dependencySaveSanitizer.remindMeLater = {}
    end

    -- Clean up any expired checks
    for filename, _ in pairs(persistence.dependencySaveSanitizer.remindMeLater) do
        if sanitizer.shouldSendEvent(filename, false) then
            persistence.dependencySaveSanitizer.remindMeLater[filename] = nil
        end
    end
end

function sanitizer.shouldSendEvent(filename, prepare)
    if prepare ~= false then
        preparePersistence()
    end

    local laterTime = persistence.dependencySaveSanitizer.remindMeLater[filename] or 0
    local checkTime = laterTime + configs.updater.remindMeLaterDelay

    if os.time() < checkTime then
        return false
    end

    return true
end

function sanitizer.disableEventFor(filename)
    preparePersistence()

    persistence.dependencySaveSanitizer.remindMeLater[filename] = os.time()
end

function sanitizer.beforeSave(filename, state)
    if configs.editor.checkDependenciesOnSave then
        if not sanitizer.shouldSendEvent(filename) then
            return
        end

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
                if not dependedOnLookup[modName] then
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