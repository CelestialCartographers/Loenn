-- TODO - Hide material list if no materials?

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local widgetUtils = require("ui.widgets.utils")
local lists = require("ui.widgets.lists")
local simpleDocks = require("ui.widgets.simple_docks")
local contextMenu = require("ui.context_menu")
local listItemUtils = require("ui.utils.list_item")

local configs = require("configs")
local languageRegistry = require("language_registry")
local toolHandler = require("tools")
local toolUtils = require("tool_utils")
local persistence = require("persistence")
local textSearching = require("utils.text_search")
local utils = require("utils")
local hotkeyHandler = require("hotkey_handler")
local loadedState = require("loaded_state")
local subLayers = require("sub_layers")

local toolWindow = {}

toolWindow.toolList = false
toolWindow.toolPanel = false

toolWindow.layerList = false
toolWindow.layerPanel = false
toolWindow.layerPanelVisible = true

toolWindow.modeList = false
toolWindow.modePanel = false
toolWindow.modePanelVisible = true

toolWindow.materialList = false
toolWindow.materialSearch = false
toolWindow.materialPanel = false

toolWindow.subLayers = {}

toolWindow.eventStates = {}

local layersWithSubLayers = {
    entities = true,
    triggers = true,
    decalsFg = true,
    decalsBg = true,
}

local function getLanguageOrDefault(languagePath, default)
    if languagePath._exists then
        return tostring(languagePath)
    end

    return default
end

local function updateListItemFavoriteVisuals(listItem)
    local favorite = listItem.itemFavorited

    if favorite then
        listItemUtils.setIcon(listItem, "favorite")

    else
        listItemUtils.clearIcon(listItem)
    end
end

local function updateListItemVisibleVisuals(listItem)
    local visible = listItem.layerVisible
    local iconName = visible and "visible" or "hidden"

    listItemUtils.setIcon(listItem, iconName)
end

local function materialSortFunction(lhs, rhs)
    if lhs.itemFavorited ~= rhs.itemFavorited then
        return lhs.itemFavorited
    end

    if configs.ui.searching.sortByScore then
        if lhs._filterScore ~= rhs._filterScore then
            return lhs._filterScore > rhs._filterScore
        end
    end

    local lhsText = lhs.originalText or lhs.text
    local rhsText = rhs.originalText or rhs.text

    return lhsText < rhsText
end

-- TODO - Config for text vs textNoMods?
-- TODO - Score checks could potentially be cached, for mod names there is a lot of redundant checks
local function getMaterialScore(item, searchParts, caseSensitive, fuzzy)
    local totalScore = 0
    local hasMatch = false

    -- Always match with empty search
    if #searchParts == 0 then
        return math.huge
    end

    for _, part in ipairs(searchParts) do
        local mode = part.mode

        if mode == "name" then
            local search = part.text
            local text = item.textNoMods
            local score = textSearching.searchScore(text, search, caseSensitive, fuzzy)

            if item.alternativeNames then
                for _, altName in ipairs(item.alternativeNames) do
                    local altScore = textSearching.searchScore(altName, search, caseSensitive, fuzzy)

                    if altScore then
                        score = math.max(score or altScore, altScore)
                    end
                end
            end

            if score then
                totalScore += score
                hasMatch = true
            end

        elseif mode == "modName" then
            -- If we have additional search text it should search for entries within the given mod
            local associatedMods = item.associatedMods
            local searchModName = part.text
            local search = part.additional
            local text = item.textNoMods

            -- Assume that mods with no associatedMods is from Celeste
            if not associatedMods or #associatedMods == 0 then
                associatedMods = {"Celeste", "Vanilla"}
            end

            for _, modName in ipairs(associatedMods) do
                local modScore = textSearching.searchScore(modName, searchModName, caseSensitive, fuzzy)
                local score = textSearching.searchScore(text, search, caseSensitive, fuzzy)

                -- Only include the additional search if it matches
                if modScore and (score or #search == 0) then
                    totalScore += modScore + (score or 0)
                    hasMatch = true
                end
            end
        end
    end

    if hasMatch then
        return totalScore
    end
end

local function prepareMaterialSearch(search)
    local parts = {}
    local searchStringParts = search:split("|")()

    for _, searchPart in ipairs(searchStringParts) do
        if utils.startsWith(searchPart, "@") then
            -- First space or the end of the string, used to extract additional search terms
            local spaceIndex = utils.findCharacter(searchPart, " ") or #searchPart + 1

            table.insert(parts, {
                mode = "modName",
                text = string.sub(searchPart, 2, spaceIndex - 1),
                additional = string.sub(searchPart, spaceIndex + 1)
            })

        else
            table.insert(parts, {
                mode = "name",
                text = searchPart
            })
        end
    end

    -- Remove empty entries, just causes issues
    for i = #parts, 1, -1 do
        if #parts[i].text == 0 then
            table.remove(parts, i)
        end
    end

    return parts
end

local function updateFavorite(materialList, itemData, tool, layer, material, favorite)
    if favorite then
        toolUtils.addPersistenceFavorites(tool, layer, material)

    else
        toolUtils.removePersistenceFavorites(tool, layer, material)
    end

    itemData.itemFavorited = favorite

    materialList:sort()
end

local function materialFavoriteDoubleClickedCallback(self, button)
    if button ~= 1 then
        return
    end

    local tool = toolHandler.currentTool
    local layer = toolHandler.getLayer()

    local material = self.data
    local favorited = self.itemFavorited

    updateFavorite(self.parent, self.itemData, tool, layer, material, not favorited)
end

local function addMaterialContextMenu(language, tool, layer, listItem)
    local material = listItem.data
    local itemData = listItem.itemData
    local favorite = itemData.itemFavorited

    local favoriteText = tostring(language.ui.tools_window.favorite)
    local favoriteCheckbox = uiElements.checkbox(favoriteText, favorite, function(checkbox, newFavorite)
        updateFavorite(listItem.parent, itemData, tool, layer, material, newFavorite)
    end)

    listItem._favoriteCheckbox = favoriteCheckbox

    local content = uiElements.row({
        favoriteCheckbox
    })

    return contextMenu.addContextMenu(listItem, content)
end

local function materialDataToElement(list, data, element)
    if not element then
        element = uiElements.listItem()
    end

    if data then
        -- Prevent crash the next render frame if interacted with
        element.parent = list
        element.owner = list

        element.text = data.text
        element.data = data.data
        element.tooltipText = data.tooltip
        element.itemFavorited = data.itemFavorited
        element.originalText = data.text
        element.itemData = data

        updateListItemFavoriteVisuals(element)

        if not element._addedHooks then
            -- TODO - Reimplement this, syncing checkbox state is more effort now
            --addMaterialContextMenu(language, data.currentToolName, data.currentLayer, element)

            element._addedHooks = true
        end
    end

    return element
end

local function getMaterialItems(layer)
    local currentTool = toolHandler.currentTool
    local currentLayer = layer or toolHandler.getLayer(currentTool)
    local materials = toolHandler.getMaterials(nil, layer or currentLayer)
    local materialItems = {}
    local favorites = toolUtils.getPersistenceFavorites(currentTool, currentLayer) or {}
    local favoritesLookup = table.flip(favorites)
    local language = languageRegistry.getLanguage()

    for i, material in ipairs(materials or {}) do
        local materialTooltip
        local materialText = material
        local materialTextNoMods = material
        local materialData = material
        local materialType = type(material)

        if materialType == "table" then
            materialText = material.displayName or material.name
            materialTextNoMods = material.displayNameNoMods or materialText
            materialData = material.name
            materialTooltip = material.tooltipText
        end

        local itemFavorited = not not favoritesLookup[materialData]
        local item = {
            text = materialText,
            textNoMods = materialTextNoMods,
            alternativeNames = material.alternativeDisplayNames,
            data = materialData,
            tooltip = materialTooltip,
            itemFavorited = itemFavorited,
            currentTool = currentTool,
            currentToolName = currentTool.name,
            currentLayer = currentLayer,
            associatedMods = material.associatedMods
        }

        table.insert(materialItems, item)
    end

    return materialItems
end

local function materialCallback(list, material)
    local sameMaterial = material == toolWindow.eventStates.material

    if not sameMaterial then
        toolWindow.eventStates.material = material

        toolHandler.setMaterial(material)
    end
end

local function toolMaterialChangedCallback(self, tool, layer, material)
    toolWindow.eventStates.layer = layer
    toolWindow.eventStates.material = material

    toolWindow.layerList:setSelection(subLayers.formatLayerName(layer, tool.subLayer), true)

    local selectedMaterial = toolWindow.materialList:setSelection(material, true)

    if not selectedMaterial then
        toolWindow.materialList:clearSelection()
    end
end

local function layerVisbilityDoubleClickCallback(self, button)
    if button ~= 1 then
        return
    end

    local layerName = self.data
    local newVisible = not loadedState.getLayerVisible(layerName)

    self.layerVisible = newVisible

    loadedState.setLayerVisible(layerName, newVisible)
end

local function getLayerItems(toolName)
    local language = languageRegistry.getLanguage()
    local layers = toolHandler.getLayers(toolName) or {}
    local layerItems = {}

    local layersNames = language.layers.name
    local layersDescriptions = language.layers.description

    local allSubLayers = toolWindow.subLayers

    for _, layer in ipairs(layers) do
        local displayName = getLanguageOrDefault(layersNames[layer], layer)
        local tooltipText = getLanguageOrDefault(layersDescriptions[layer])

        -- Layer with -1 means all layers
        local item = {
            text = displayName,
            data = subLayers.formatLayerName(layer, -1),
            layerVisible = loadedState.getLayerVisible(layer),
            tooltipText = tooltipText,
            subLayer = -1,
        }

        table.insert(layerItems, item)

        if layersWithSubLayers[layer] then
            -- Convert from lookup table into sorted list
            local subLayerNames = table.keys(allSubLayers[layer] or {})

            table.sort(subLayerNames)

            -- No need to show sub layers if we only have one
            if #subLayerNames > 1 then
                for _, subLayer in ipairs(subLayerNames) do
                    local layerName = subLayers.formatLayerName(layer, subLayer)
                    local subItem = {
                        text = string.format(" %s %s", displayName, subLayer + 1),
                        data = layerName,
                        layerVisible = loadedState.getLayerVisible(layerName),
                        tooltipText = tooltipText,
                        subLayer = subLayer,
                    }

                    table.insert(layerItems, subItem)
                end
            end
        end
    end

    return layerItems
end

local function addSublayer(layer, subLayer)
    if not layersWithSubLayers[layer] then
        return
    end

    if not toolWindow.subLayers[layer] then
        toolWindow.subLayers[layer] = {}
    end

    local targetLayer = toolWindow.subLayers[layer]
    local layerCount = #targetLayer

    -- Special case for when no editor layers are found at all
    if layerCount == 0 then
        targetLayer[0] = 0
        targetLayer[1] = 1

        return 1
    end

    targetLayer[layerCount + 1] = layerCount + 1

    return layerCount + 1
end

local function addLayerContextMenu(listItem)
    local function contentFunction()
        local layerName = listItem.data

        if not layerName then
            return
        end

        local layer, subLayer = subLayers.parseLayerName(layerName)

        if not layersWithSubLayers[layer] then
            return false
        end

        local language = languageRegistry.getLanguage()
        local addButton = uiElements.button(tostring(language.ui.tools_window.add_sub_layer), function()
            local newSubLayer = addSublayer(layer, subLayer)

            if newSubLayer then
                toolWindow.layerList:updateItems(getLayerItems(), subLayers.formatLayerName(layer, newSubLayer))
            end
        end)

        local content = uiElements.row({
            addButton,
        })

        return content
    end

    return contextMenu.addContextMenu(listItem, contentFunction)
end

local function layerDataToElement(list, data, element)
    if not element then
        element = uiElements.listItem()

        element:layout()
    end

    if data then
        -- Prevent crash the next render frame if interacted with
        element.parent = list
        element.owner = list

        element.text = data.text
        element.data = data.data
        element.tooltipText = data.tooltip
        element.layerVisible = data.layerVisible
        element.itemData = data
        element.subLayer = data.subLayer

        updateListItemVisibleVisuals(element)

        if not element._addedHooks then
            addLayerContextMenu(element)

            element._addedHooks = true
        end
    end

    return element
end

local function layerCallback(list, layerName)
    local layer, subLayer = subLayers.parseLayerName(layerName)

    local sameTool = toolWindow.eventStates.tool == toolHandler.currentToolName
    local sameLayer = toolWindow.eventStates.layer == layer
    local sameSubLayer = not sameLayer and toolWindow.eventStates.subLayer == subLayer

    if not sameLayer or not sameTool or not sameSubLayer then
        local targetMaterial = toolUtils.getPersistenceMaterial(toolHandler.currentTool, layer)

        toolWindow.eventStates.tool = toolHandler.currentToolName
        toolWindow.eventStates.layer = layer
        toolWindow.eventStates.subLayer = subLayer
        toolWindow.eventStates.searchTerm = nil
        toolWindow.eventStates.material = nil

        toolHandler.setLayer(layer, subLayer)

        if not sameLayer then
            toolWindow.materialList:updateItems(getMaterialItems(layer), targetMaterial)
        end
    end
end

local function toolLayerChangedCallback(self, tool, layer, subLayer)
    local searchText = toolUtils.getPersistenceSearch(tool, layer) or ""
    local sameLayer = toolWindow.eventStates.layer == layer
    local sameSubLayer = not sameLayer and toolWindow.eventStates.subLayer == subLayer
    local sameSearch = toolWindow.eventStates.searchTerm == searchText
    local targetMaterial = nil

    if not sameLayer then
        targetMaterial = toolUtils.getPersistenceMaterial(tool, layer)
    end

    if not sameLayer or not sameSubLayer or not sameSearch then
        toolWindow.eventStates.searchTerm = searchText
        toolWindow.eventStates.layer = layer
        toolWindow.eventStates.subLayer = subLayer

        toolWindow.materialList:setFilterText(searchText, true)
        toolWindow.layerList:setSelection(subLayers.formatLayerName(layer, subLayer), true)

        if not sameLayer then
            toolWindow.materialList:updateItems(getMaterialItems(layer), targetMaterial)
        end
    end
end

local function updateLayerList(toolName, tool, targetLayer)
    local items = getLayerItems(toolName)

    if toolName and not tool then
        tool = toolHandler.tools[toolName]
    end

    if tool and not targetLayer then
        targetLayer = toolUtils.getPersistenceLayer(tool)
    end

    toolWindow.layerList:updateItems(items, targetLayer)

    local newVisible = #items > 0

    if newVisible ~= toolWindow.layerPanelVisible then
        if newVisible then
            toolWindow.leftColumn:addChild(toolWindow.layerPanel, 2)

        else
            toolWindow.layerPanel:removeSelf()

            -- Always update material list if the layer list is invisible
            -- Layer item callback will never happen and the material list will be stuck
            toolWindow.materialList:updateItems(getMaterialItems("fake_layer_name"))
        end

        toolWindow.layerPanelVisible = newVisible
    end
end

local function layerInformationChangedCallback(window, key, value)
    -- Only update if its a visibility/render change
    if key ~= "visible" and key ~= "forceRender" then
        return
    end

    local toolName = toolWindow.eventStates.tool
    local layer = toolWindow.eventStates.layer
    local subLayer = toolWindow.eventStates.subLayer
    local layerName = subLayers.formatLayerName(layer, subLayer)

    updateLayerList(toolName, toolHandler.tools[toolName], layerName)
    widgetUtils.updateHoveredTarget()
end

local function getModeItems(toolName)
    local language = languageRegistry.getLanguage()
    local modes = toolHandler.getModes(toolName) or {}
    local modeItems = {}

    if not toolName then
        toolName = toolHandler.currentToolName
    end

    for _, mode in pairs(modes) do
        local displayName = getLanguageOrDefault(language.tools[toolName].modes.name[mode], mode)
        local tooltipText = getLanguageOrDefault(language.tools[toolName].modes.description[mode], mode)

        local item = uiElements.listItem({
            text = displayName,
            data = mode
        })

        table.insert(modeItems, item)

        if tooltipText then
            item.tooltipText = tooltipText
        end
    end

    return modeItems
end

local function modeCallback(list, mode)
    local sameMode = mode == toolWindow.eventStates.mode

    if not sameMode then
        toolWindow.eventStates.mode = mode
        toolWindow.eventStates.layer = nil
        toolWindow.eventStates.searchTerm = ""
        toolWindow.eventStates.material = nil

        toolHandler.setMode(mode)
    end
end

local function toolModeChangedCallback(self, tool, mode)
    toolWindow.eventStates.mode = mode

    toolWindow.modeList:setSelection(mode, true)
end

local function updateToolModeList(name)
    local items = getModeItems(name)

    toolWindow.modeList:updateItems(items)

    local newVisible = #items > 0

    if newVisible ~= toolWindow.modePanelVisible then
        if newVisible then
            toolWindow.leftColumn:addChild(toolWindow.modePanel)

        else
            toolWindow.modePanel:removeSelf()
        end

        toolWindow.modePanelVisible = newVisible
    end
end

local function getToolItems(sortItems)
    local language = languageRegistry.getLanguage()
    local tools = toolHandler.tools
    local toolItems = {}

    local toolNames = language.tools.name
    local toolDescriptions = language.tools.description

    for name, tool in pairs(tools) do
        local displayName = getLanguageOrDefault(toolNames[name], name)
        local tooltipText = getLanguageOrDefault(toolDescriptions[name])

        local item = uiElements.listItem({
            text = displayName,
            data = name
        })

        table.insert(toolItems, item)

        if tooltipText then
            item.tooltipText = tooltipText
        end
    end

    if sortItems ~= false then
        table.sort(toolItems, function(lhs, rhs)
            local lhsGroup = tools[lhs.data].group or ""
            local rhsGroup = tools[rhs.data].group or ""

            return lhsGroup == rhsGroup and lhs.text < rhs.text or lhsGroup < rhsGroup
        end)
    end

    return toolItems
end

local function toolCallback(list, toolName)
    local sameTool = toolName == toolWindow.eventStates.tool

    if not sameTool then
        toolWindow.eventStates.tool = toolName
        toolWindow.eventStates.mode = nil
        toolWindow.eventStates.searchTerm = ""
        toolWindow.eventStates.layer = nil
        toolWindow.eventStates.material = nil

        toolHandler.selectTool(toolName)
        updateLayerList(toolName, toolHandler.tools[toolName])
        updateToolModeList(toolName)
    end
end

local function toolChangedCallback(self, tool)
    toolWindow.toolList:setSelection(tool.name)
end

local function updateLayerAndPlacementsCallback(list, layer, value)
    -- We get the event before the main editor
    -- Placements for example will be out of date if we update now
    ui.runLate(function()
        toolWindow.layerList:updateItems(getLayerItems())

        if layer == toolWindow.eventStates.layer then
            toolWindow.materialList:updateItems(getMaterialItems())
        end
    end)
end

local function mapLoadedCallback(list)
    toolWindow.subLayers = loadedState.subLayers or {}
    updateLayerAndPlacementsCallback(list)
end

local function materialSearchFieldChanged(element, new, old)
    local tool = toolHandler.currentTool
    local layer = toolHandler.getLayer()

    toolUtils.setPersistenceSearch(tool, layer, new)
end

local function focusMaterialSearchHandler()
    if toolWindow.materialSearch then
        widgetUtils.focusElement(toolWindow.materialSearch)
    end
end

function toolWindow.getWindow()
    local toolListOptions = {
        initialItem = toolHandler.currentToolName
    }

    local modeListOptions = {
        initialItem = toolHandler.getMode()
    }

    local layerListOptions = {
        initialItem = toolHandler.getLayer(),
        dataToElement = layerDataToElement,
        listItemDoubleClicked = layerVisbilityDoubleClickCallback
    }

    local currentTool = toolHandler.currentTool
    local currentLayer = toolHandler.getLayer()

    local materialListOptions = {
        searchBarLocation = "below",
        searchBarCallback = materialSearchFieldChanged,
        initialSearch = toolUtils.getPersistenceSearch(currentTool, currentLayer),
        initialItem = toolHandler.getMaterial(),
        listItemDoubleClicked = materialFavoriteDoubleClickedCallback,
        dataToElement = materialDataToElement,
        sortingFunction = materialSortFunction,
        searchScore = getMaterialScore,
        searchRawItem = true,
        searchPreprocessor = prepareMaterialSearch,
        sort = true
    }

    local toolItems = getToolItems()
    local scrolledToolList, toolList = lists.getList(toolCallback, toolItems, toolListOptions)

    local modeItems = getModeItems()
    local scrolledModeList, modeList = lists.getList(modeCallback, modeItems, modeListOptions)

    local layerItems = getLayerItems()
    local scrolledLayerList, layerList = lists.getMagicList(layerCallback, layerItems, layerListOptions)

    local materialItems = getMaterialItems()
    local scrolledMaterialList, materialList, materialSearchField = lists.getMagicList(materialCallback, materialItems, materialListOptions)

    hotkeyHandler.addHotkey("global", configs.ui.hotkeys.focusMaterialSearch, focusMaterialSearchHandler)

    -- Make sure lists are visually updated
    -- This does some extra logic to hide the lists if they are empty
    ui.runLate(function()
        updateLayerList()
        updateToolModeList()
    end)

    toolWindow.toolList = toolList
    toolWindow.layerList = layerList
    toolWindow.materialList = materialList
    toolWindow.modeList = modeList
    toolWindow.toolPanel = uiElements.panel({toolList})
    toolWindow.layerPanel = uiElements.panel({layerList})
    toolWindow.modePanel = uiElements.panel({modeList})
    toolWindow.leftColumn = uiElements.column({
        toolWindow.toolPanel,
        toolWindow.layerPanel,
        toolWindow.modePanel
    })
    toolWindow.materialSearch = materialSearchField

    local row = uiElements.row({
        toolWindow.leftColumn,
        uiElements.panel({scrolledMaterialList}):with(uiUtils.fillHeight(false))
    }):with(uiUtils.fillHeight(true))

    local window = uiElements.window("Tools", row):with(uiUtils.fillHeight(false))

    window:with({
        editorToolChanged = toolChangedCallback,
        editorToolLayerChanged = toolLayerChangedCallback,
        editorToolMaterialChanged = toolMaterialChangedCallback,
        editorToolModeChanged = toolModeChangedCallback,
        editorMapLoaded = mapLoadedCallback,
        editorShownDependenciesChanged = updateLayerAndPlacementsCallback,
        editorLayerInformationChanged = layerInformationChangedCallback,

        interactive = 0
    })

    window.style.bg = {}
    window.style.border = {}
    window.style.padding = row.style.spacing

    widgetUtils.removeWindowTitlebar(window)

    return simpleDocks.pinWidgetToEdge("right", window)
end

return toolWindow
