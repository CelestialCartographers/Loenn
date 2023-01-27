-- TODO - Hide material list if no materials?

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local widgetUtils = require("ui.widgets.utils")
local listWidgets = require("ui.widgets.lists")
local simpleDocks = require("ui.widgets.simple_docks")
local contextMenu = require("ui.context_menu")
local iconUtils = require("ui.utils.icons")

local languageRegistry = require("language_registry")
local toolHandler = require("tools")
local toolUtils = require("tool_utils")
local persistence = require("persistence")

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
toolWindow.materialPanel = false

toolWindow.eventStates = {}

local function getLanguageOrDefault(languagePath, default)
    if languagePath._exists then
        return tostring(languagePath)
    end

    return default
end

local function updateListItemFavorite(listItem)
    local favorite = listItem.itemFavorited
    local text = listItem.originalText
    local children = listItem.children
    local label = uiElements.label(text)

    listItem.label = label

    for i = 1, #children do
        children[i] = nil
    end

    if favorite then
        local iconMaxSize = listItem.height - listItem.style.padding * 2
        local favoriteIcon, iconSize = iconUtils.getIcon("favorite", iconMaxSize)

        if favoriteIcon then
            local centerOffset = math.floor((listItem.height - iconSize) / 2)
            local imageElement = uiElements.image(favoriteIcon)

            imageElement = imageElement:with(uiUtils.at(listItem.style.padding, centerOffset))

            table.insert(children, imageElement)
        end
    end

    local favoriteCheckbox = listItem._favoriteCheckbox

    if favoriteCheckbox and favoriteCheckbox:getValue() ~= favorite then
        -- Prevent callback
        favoriteCheckbox._value = favorite
        favoriteCheckbox:updateIcon()
    end

    table.insert(children, label)
    listItem:reflow()
end

local function materialSortFunction(lhs, rhs)
    if lhs.itemFavorited ~= rhs.itemFavorited then
        return lhs.itemFavorited
    end

    local lhsText = lhs.originalText or lhs.text
    local rhsText = rhs.originalText or rhs.text

    return lhsText < rhsText
end

local function updateFavorite(listItem, tool, layer, material, favorite)
    local materialList = listItem.parent
    local materialListItems = materialList.children

    if favorite then
        toolUtils.removePersistenceFavorites(tool, layer, material)

    else
        toolUtils.addPersistenceFavorites(tool, layer, material)
    end

    listItem.itemFavorited = favorite

    updateListItemFavorite(listItem)
    table.sort(materialListItems, materialSortFunction)
    materialList:layout()
end

local function materialFavoriteOnPressHandler(tool, layer)
    return function(orig, self, x, y, button, isDrag, presses)
        -- Favorite on every double click
        if presses % 2 == 0 then
            local material = self.data
            local favorited = self.itemFavorited

            updateFavorite(self, tool, layer, material, not favorited)

        else
            orig(self, x, y, button, isDrag, presses)
        end
    end
end

local function addMaterialContextMenu(language, tool, layer, listItem)
    local material = listItem.data
    local favorite = listItem.itemFavorited

    local favoriteText = tostring(language.ui.tools_window.favorite)
    local favoriteCheckbox = uiElements.checkbox(favoriteText, favorite, function(checkbox, newFavorite)
        updateFavorite(listItem, tool, layer, material, newFavorite)
    end)

    listItem._favoriteCheckbox = favoriteCheckbox

    local content = uiElements.row({
        favoriteCheckbox
    })

    return contextMenu.addContextMenu(listItem, content)
end

local function getMaterialItems(layer, sortItems)
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
        local materialData = material
        local materialType = type(material)

        if materialType == "table" then
            materialText = material.displayName or material.name
            materialData = material.name
            materialTooltip = material.tooltipText
        end

        local itemFavorited = not not favoritesLookup[materialData]
        local listItem = uiElements.listItem({
            text = materialText,
            data = materialData,
        }):hook({
            onPress = materialFavoriteOnPressHandler(currentTool, currentLayer)
        })

        listItem.itemFavorited = itemFavorited
        listItem.tooltipText = materialTooltip
        listItem.originalText = materialText

        table.insert(materialItems, addMaterialContextMenu(language, currentTool, currentLayer, listItem))
    end

    if sortItems ~= false then
        table.sort(materialItems, materialSortFunction)
    end

    ui.runLate(function()
        for _, listItem in ipairs(materialItems) do
            updateListItemFavorite(listItem)
        end
    end)

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

    listWidgets.setSelection(toolWindow.layerList, layer, true)
    listWidgets.setSelection(toolWindow.materialList, material, true)
end

local function getLayerItems(toolName)
    local language = languageRegistry.getLanguage()
    local layers = toolHandler.getLayers(toolName) or {}
    local layerItems = {}

    local layersNames = language.layers.name
    local layersDescriptions = language.layers.description

    for _, layer in ipairs(layers) do
        local displayName = getLanguageOrDefault(layersNames[layer], layer)
        local tooltipText = getLanguageOrDefault(layersDescriptions[layer])

        local item = uiElements.listItem({
            text = displayName,
            data = layer
        })

        table.insert(layerItems, item)

        if tooltipText then
            item.tooltipText = tooltipText
        end
    end

    return layerItems
end

local function layerCallback(list, layer)
    local sameTool = toolWindow.eventStates.tool == toolHandler.currentToolName
    local sameLayer = toolWindow.eventStates.layer == layer

    if not sameLayer or not sameTool then
        toolWindow.eventStates.tool = toolHandler.currentToolName
        toolWindow.eventStates.layer = layer
        toolWindow.eventStates.searchTerm = nil
        toolWindow.eventStates.material = nil

        toolHandler.setLayer(layer)
        listWidgets.updateItems(toolWindow.materialList, getMaterialItems(layer), nil, nil, true)
    end
end

local function toolLayerChangedCallback(self, tool, layer)
    local searchText = toolUtils.getPersistenceSearch(tool, layer) or ""
    local sameLayer = toolWindow.eventStates.layer == layer
    local sameSearch = toolWindow.eventStates.searchTerm == searchText

    if not sameLayer or not sameSearch then
        toolWindow.eventStates.searchTerm = searchText
        toolWindow.eventStates.layer = layer

        local searchField = toolWindow.materialList.searchField

        searchField:setText(searchText)
        searchField.index = #searchField

        listWidgets.setSelection(toolWindow.layerList, layer, true)
        listWidgets.updateItems(toolWindow.materialList, getMaterialItems(layer), nil, nil, true)
    end
end

local function updateLayerList(name)
    local items = getLayerItems(name)

    listWidgets.updateItems(toolWindow.layerList, items)

    local newVisible = #items > 0

    if newVisible ~= toolWindow.layerPanelVisible then
        if newVisible then
            toolWindow.leftColumn:addChild(toolWindow.layerPanel, 2)

        else
            toolWindow.layerPanel:removeSelf()
        end

        toolWindow.layerPanelVisible = newVisible
    end
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

    listWidgets.setSelection(toolWindow.modeList, mode, true)
end

local function updateToolModeList(name)
    local items = getModeItems(name)

    listWidgets.updateItems(toolWindow.modeList, items)

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
        listWidgets.updateItems(toolWindow.layerList, getLayerItems(toolName))
    end
end

local function toolChangedCallback(self, tool)
    toolWindow.eventStates.tool = tool.name

    listWidgets.setSelection(toolWindow.toolList, tool.name, true)
    updateLayerList(tool.name)
    updateToolModeList(tool.name)
end

local function updateLayerAndPlacementsCallback(list, filename)
    -- We get the event before the main editor
    -- Placements for example will be out of date if we update now
    ui.runLate(function()
        listWidgets.updateItems(toolWindow.layerList, getLayerItems())
        listWidgets.updateItems(toolWindow.materialList, getMaterialItems())
    end)
end

local function materialSearchFieldChanged(element, new, old)
    local tool = toolHandler.currentTool
    local layer = toolHandler.getLayer()

    toolUtils.setPersistenceSearch(tool, layer, new)

    if toolWindow.materialList then
        ui.runLate(function()
            local materialListItems = toolWindow.materialList.children

            for _, listItem in ipairs(materialListItems) do
                updateListItemFavorite(listItem)
            end

            table.sort(materialListItems, materialSortFunction)
        end)
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
        initialItem = toolHandler.getLayer()
    }

    local materialListOptions = {
        searchBarLocation = "below",
        searchBarCallback = materialSearchFieldChanged,
        initialSearch = toolUtils.getPersistenceSearch(toolHandler.currentTool, toolHandler.getLayer()),
        initialItem = toolHandler.getMaterial()
    }

    local toolItems = getToolItems()
    local scrolledToolList, toolList = listWidgets.getList(toolCallback, toolItems, toolListOptions)

    local modeItems = getModeItems()
    local scrolledModeList, modeList = listWidgets.getList(modeCallback, modeItems, modeListOptions)

    local layerItems = getLayerItems()
    local scrolledLayerList, layerList = listWidgets.getList(layerCallback, layerItems, layerListOptions)

    local materialItems = getMaterialItems()
    local scrolledMaterialList, materialList = listWidgets.getList(materialCallback, materialItems, materialListOptions)

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
        editorMapLoaded = updateLayerAndPlacementsCallback,
        editorShownDependenciesChanged = updateLayerAndPlacementsCallback,

        interactive = 0
    })

    window.style.bg = {}
    window.style.border = {}

    widgetUtils.removeWindowTitlebar(window)

    return simpleDocks.pinWidgetToEdge("right", window)
end

return toolWindow