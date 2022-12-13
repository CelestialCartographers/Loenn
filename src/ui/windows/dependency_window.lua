-- TODO - Should work without Everest.yaml

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local loadedState = require("loaded_state")
local languageRegistry = require("language_registry")
local utils = require("utils")
local form = require("ui.forms.form")
local configs = require("configs")

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

local function getModSection(modName, reasons, groupName)
    -- TODO - Implement callback (also needs to refresh the window content)

    local language = languageRegistry.getLanguage()
    local buttonLanguageKey = groupName == "missing_mods" and "add_dependency" or "remove_dependency"
    local buttonText = tostring(language.ui.dependency_window[buttonLanguageKey])

    local function buttonCallback()
        print("Not yet implemented")
    end

    local reasonTree = generateCollapsableTree({[modName] = reasons})
    local actionButton = uiElements.button(buttonText, buttonCallback)
    local column = uiElements.column({
        reasonTree,
        actionButton
    })

    return column
end

local function calculateSecitonWidthHook(sections)
    return function(orig, self)
        local width = 0

        for _, section in ipairs(sections) do
            section:layoutLazy()

            width = math.max(width, section.width)
        end

        return width
    end
end

local function localizeModName(modName, language)
    local language = language or languageRegistry.getLanguage()
    local modNameLanguage = language.mods[modName].name

    if modNameLanguage._exists then
        return tostring(modNameLanguage)
    end

    return modName
end

local function getModSections(groupName, mods, addPadding)
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
        local modSection = getModSection(localizedModName, reasons, groupName)

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

function dependencyWindow.getWindowContent(modPath, side)
    local currentModMetadata = mods.getModMetadataFromPath(modPath) or {}
    local dependedOnModNames = dependencyFinder.getDependencyModNames(currentModMetadata)

    local usedMods = dependencyFinder.analyzeSide(side)
    local missingMods = {}
    local dependedOnMods = {}

    for modName, reasons in pairs(usedMods) do
        if not dependedOnModNames[modName] then
            missingMods[modName] = reasons

        else
            dependedOnMods[modName] = reasons
        end
    end

    local hasMissingMods = utils.countKeys(missingMods) > 0
    local hasDependedOnMods = utils.countKeys(dependedOnMods) > 0

    local missingModsSection = getModSections("missing_mods", missingMods)
    local dependedOnSection = getModSections("depended_on", dependedOnMods, hasMissingMods)

    -- TODO - Sections need to have the same width, otherwise the lineSeparator is cut off

    local column = uiElements.column({})
    local scrollableColumn = uiElements.scrollbox(column)

    if hasMissingMods then
        column:addChild(missingModsSection)
    end

    if hasDependedOnMods then
        column:addChild(dependedOnSection)
    end

    scrollableColumn:hook({
        calcWidth = function(orig, element)
            return element.inner.width
        end,
    })
    scrollableColumn:with(uiUtils.fillHeight(true))

    return scrollableColumn
end

function dependencyWindow.editDependencies(filename, side)
    local modPath = mods.getFilenameModPath(filename)

    if not side or not modPath then
        return
    end

    local window
    local layout = dependencyWindow.getWindowContent(modPath, side)

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