-- TODO - Should work without Everest.yaml
-- TODO - Makeit possible to update versions

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local loadedState = require("loaded_state")
local languageRegistry = require("language_registry")
local utils = require("utils")
local form = require("ui.forms.form")
local configs = require("configs")
local yaml = require("lib.yaml")
local notifications = require("ui.notification")

local mods = require("mods")
local dependencyEditor = require("ui.dependency_editor")
local dependencyFinder = require("dependencies")

local listWidgets = require("ui.widgets.lists")
local collapsableWidget = require("ui.widgets.collapsable")
local widgetUtils = require("ui.widgets.utils")
local gridElement = require("ui.widgets.grid")

local dependencyWindow = {}

local activeWindows = {}
local windowPreviousX = 0
local windowPreviousY = 0

local dependencyWindowGroup = uiElements.group({}):with({

})

local everestModName = "Everest"

local function localizeModName(modName, language)
    local language = language or languageRegistry.getLanguage()
    local modNameLanguage = language.mods[modName].name

    if modNameLanguage._exists then
        return tostring(modNameLanguage)
    end

    return tostring(modName)
end

local function prepareMetadataForSaving(metadata, newDependencies)
    local newMetadata = utils.deepcopy(metadata)

    -- Remove editor specific information
    for k, v in pairs(newMetadata) do
        if type(k) == "string" and utils.startsWith(k, "_") then
            newMetadata[k] = nil
        end
    end

    -- Sort dependencies by name
    newDependencies = table.sortby(newDependencies, function(dependency)
        return dependency.Name
    end)()

    local firstMetadata = newMetadata[1] or {}

    firstMetadata.Dependencies = newDependencies

    return newMetadata
end

local function updateMetadataFile(metadata, newDependencies)
    local path = metadata._path
    local mountPoint = metadata._mountPoint
    local folderName = metadata._folderName
    local filename

    if not filename then
        filename = mods.findEverestYamlOrDefault(mountPoint)
    end

    if filename then
        local realFilename = utils.joinpath(love.filesystem.getRealDirectory(mountPoint), filename)
        local newMetadata = prepareMetadataForSaving(metadata, newDependencies)
        local success, reason = yaml.write(realFilename, newMetadata)

        -- Update metadata in cache
        mods.readModMetadata(path, mountPoint, folderName)

        return success
    end

    return false
end

local function updateSections(interactionData)
    -- TODO - Keep expand status when moving?

    local window = interactionData.window
    local windowContentScrollable = interactionData.windowContentScrollable
    local modPath = interactionData.modPath
    local side = interactionData.side

    local previousScrollAmount = windowContentScrollable.inner.y
    local newContentScrollable, newContent = dependencyWindow.getWindowContent(modPath, side, interactionData)

    newContentScrollable.inner.y = previousScrollAmount

    interactionData.windowContent = newContent
    interactionData.windowContentScrollable = newContentScrollable

    windowContentScrollable:removeSelf()
    window:addChild(newContentScrollable)
    window:layout()
end

local function getDependenciesList(modName)
    local currentModMetadata = mods.getModMetadataFromPath(modName)
    local firstMetadata = currentModMetadata and currentModMetadata[1] or {}
    local dependencies = firstMetadata.Dependencies or {}

    return dependencies, currentModMetadata
end

local function addDependencyCallback(modName, interactionData)
    return function()
        local dependencies, currentModMetadata = getDependenciesList(interactionData.modPath)
        local modInfo, modMetadata = mods.findLoadedMod(modName)
        local modVersion = modInfo and modInfo.Version

        table.insert(dependencies, {
            Name = modName,
            Version = modVersion
        })

        updateMetadataFile(currentModMetadata, dependencies)
        updateSections(interactionData)
    end
end

local function removeDependencyCallback(modName, interactionData)
    return function()
        local dependencies, currentModMetadata = getDependenciesList(interactionData.modPath)

        for i = #dependencies, 1, -1 do
            local dependency = dependencies[i]

            if dependency.Name == modName then
                table.remove(dependencies, i)
            end
        end

        updateMetadataFile(currentModMetadata, dependencies)
        updateSections(interactionData)
    end
end

local function generateCollapsableTree(data)
    local dataType = type(data)

    if dataType == "table" then
        local column = uiElements.column({})

        if #data == 0 then
            for text, subData in pairs(data) do
                local content = generateCollapsableTree(subData)

                if content then
                    local collapsable = collapsableWidget.getCollapsable(tostring(text), content)

                    column:addChild(collapsable)
                end
            end

        else
            for _, subData in ipairs(data) do
                column:addChild(uiElements.label(subData))
            end
        end

        return column

    elseif dataType == "string" then
        return uiElements.label(data)
    end
end

local function getModSection(modName, localizedModName, reasons, groupName, interactionData)
    local language = languageRegistry.getLanguage()
    local buttonAdds = groupName ~= "depended_on"
    local buttonLanguageKey = buttonAdds and "add_dependency" or "remove_dependency"
    local buttonText = tostring(language.ui.dependency_window[buttonLanguageKey])

    local buttonCallbackWrapper = buttonAdds and addDependencyCallback or removeDependencyCallback
    local buttonCallback = buttonCallbackWrapper(modName, interactionData)

    local modContent

    if reasons then
        modContent = generateCollapsableTree({[localizedModName] = reasons})

    else
        modContent = uiElements.label(localizedModName)
    end

    local actionButton = uiElements.button(buttonText, buttonCallback)
    local column = uiElements.column({
        modContent,
        actionButton
    })

    return column
end

local function getModSections(groupName, mods, addPadding, interactionData)
    local language = languageRegistry.getLanguage()
    local labelText = tostring(language.ui.dependency_window.group[groupName])

    local separator = uiElements.lineSeparator(labelText, 16, true)
    local column = uiElements.column({separator})

    if addPadding then
        separator:addBottomPadding()
    end

    local orderedSections = {}

    -- Sort by mod name
    for modName, reasons in pairs(mods) do
        local localizedModName = localizeModName(modName)
        local modSection = getModSection(modName, localizedModName, reasons, groupName, interactionData)

        if modSection then
            table.insert(orderedSections, {localizedModName, modSection})
        end
    end

    orderedSections = table.sortby(orderedSections, function(entry)
        return entry[1]
    end)()

    for _, entry in ipairs(orderedSections) do
        column:addChild(entry[2])
    end

    return column
end

function dependencyWindow.getWindowContent(modPath, side, interactionData)
    local currentModMetadata = mods.getModMetadataFromPath(modPath)
    local currentModNames = mods.getModNamesFromMetadata(currentModMetadata)
    local currentModNamesLookup = table.flip(currentModNames)
    local dependedOnModNames = mods.getDependencyModNames(currentModMetadata)
    local availableModNames = mods.getAvailableModNames()
    local dependedOnModsLookup = table.flip(dependedOnModNames)

    local usedMods = dependencyFinder.analyzeSide(side)
    local missingMods = {}
    local dependedOnMods = {}
    local uncategorized = {}

    -- Mods with known usage
    for modName, reasons in pairs(usedMods) do
        if not currentModNamesLookup[modName] then
            if not dependedOnModsLookup[modName] then
                missingMods[modName] = reasons

            else
                dependedOnMods[modName] = reasons
            end
        end
    end

    -- Add Everest as target if missing
    local localizedEverestName = localizeModName(everestModName)
    local hasEverest = dependedOnModsLookup[everestModName] or dependedOnModsLookup[localizedEverestName]

    if not hasEverest and not missingMods[everestModName] then
        missingMods[everestModName] = false
    end

    -- Anything depended on but with no known usage
    for _, modName in ipairs(dependedOnModNames) do
        if not dependedOnMods[modName] then
            if not currentModNamesLookup[modName] then
                dependedOnMods[modName] = false
            end
        end
    end

    -- Anything not already added to the other categories
    for _, modName in ipairs(availableModNames) do
        if not currentModNamesLookup[modName] then
            if not missingMods[modName] and not dependedOnMods[modName] then
                uncategorized[modName] = false
            end
        end
    end

    local hasMissingMods = utils.countKeys(missingMods) > 0
    local hasDependedOnMods = utils.countKeys(dependedOnMods) > 0
    local hasUncategorized = utils.countKeys(uncategorized) > 0

    local missingModsSection = getModSections("missing_mods", missingMods, false, interactionData)
    local dependedOnSection = getModSections("depended_on", dependedOnMods, hasMissingMods, interactionData)
    local uncategorizedSection = getModSections("available_mods", uncategorized, hasUncategorized, interactionData)

    local sections = {}

    local column = uiElements.column({})
    local scrollableColumn = uiElements.scrollbox(column)

    column.style.padding = 8

    if hasMissingMods then
        table.insert(sections, missingModsSection)
    end

    if hasDependedOnMods then
        table.insert(sections, dependedOnSection)
    end

    if hasUncategorized then
        table.insert(sections, uncategorizedSection)
    end

    -- Add all section children to our main column
    -- Ended up being easier than figuring out layouting to match column widths
    for _, section in ipairs(sections) do
        for _, child in ipairs(section.children) do
            column:addChild(child)
        end
    end

    scrollableColumn:hook({
        calcWidth = function(orig, self)
            return self.inner.width
        end
    })
    scrollableColumn:with(uiUtils.fillHeight(true))

    interactionData.sectionsColumn = column
    interactionData.missingModsSection = missingModsSection
    interactionData.dependedOnSection = dependedOnSection
    interactionData.uncategorizedSection = uncategorizedSection
    interactionData.windowContentScrollable = scrollableColumn
    interactionData.windowContent = column

    return scrollableColumn, column
end

local function createStartingEverestYaml(filename, side, metadata)
    local modName = metadata._folderName or side.map.package
    local everestVersion = mods.getEverestVersion()

    local newMetadata = utils.deepcopy(metadata)
    local dependencies = {}

    if everestVersion then
        table.insert(dependencies, {
            Name = everestModName,
            Version = everestVersion
        })
    end

    newMetadata[1] = {
        Name = modName,
        Version = "0.0.1"
    }

    updateMetadataFile(newMetadata, dependencies)
end

local function showMissingEverestYamlNotification(language, filename, side, metadata)
    notifications.notify(function(popup)
        return uiElements.column({
            uiElements.label(tostring(language.ui.dependency_window.no_everest_yaml)),
            uiElements.row({
                uiElements.button(tostring(language.ui.button.yes), function()
                    createStartingEverestYaml(filename, side, metadata)
                    dependencyWindow.editDependencies(filename, side)
                    popup:close()
                end),
                uiElements.button(tostring(language.ui.button.cancel), function()
                    popup:close()
                end),
            })
        })
    end, -1)
end

function dependencyWindow.editDependencies(filename, side)
    local language = languageRegistry.getLanguage()
    local modPath = mods.getFilenameModPath(filename)

    if not side then
        notifications.notify(tostring(language.ui.dependency_window.no_map_loaded))

        return
    end

    if not modPath then
        notifications.notify(tostring(language.ui.dependency_window.requires_packaged_mod))

        return
    end

    local currentModMetadata = mods.getModMetadataFromPath(modPath)

    -- Naive check if the metadata contains Everest.yaml data
    if not currentModMetadata or not currentModMetadata[1] then
        showMissingEverestYamlNotification(language, filename, side, currentModMetadata)

        return
    end

    local window
    local interactionData = {
        modPath = modPath,
        side = side,
    }

    local layout = dependencyWindow.getWindowContent(modPath, side, interactionData)

    local language = languageRegistry.getLanguage()
    local windowTitle = tostring(language.ui.dependency_window.window_title)

    local windowX = windowPreviousX
    local windowY = windowPreviousY

    -- Don't stack windows on top of each other
    if #activeWindows > 0 then
        windowX, windowY = 0, 0
    end

    window = uiElements.window(windowTitle, layout):with({
        x = windowX,
        y = windowY
    })

    interactionData.window = window

    table.insert(activeWindows, window)
    dependencyWindowGroup.parent:addChild(window)
    widgetUtils.addWindowCloseButton(window)
    window:with(widgetUtils.fillHeightIfNeeded())

    return window
end

-- Group to get access to the main group and sanely inject windows in it
function dependencyWindow.getWindow()
    dependencyEditor.dependencyWindow = dependencyWindow

    return dependencyWindowGroup
end

return dependencyWindow