-- TODO - Hide material list if no materials?

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local widgetUtils = require("ui.widgets.utils")
local lists = require("ui.widgets.lists")
local simpleDocks = require("ui.widgets.simple_docks")
local contextMenu = require("ui.context_menu")
local listItemUtils = require("ui.utils.list_item")
local notifications = require("ui.notification")

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
local history = require("history")
local selectionUtils = require("selections")
local celesteRender = require("celeste_render")

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

local layersWithBlankIcon = {
    allLayers = true,
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

-- Used for layer icon click and double click
local function layerItemToggleVisibilityHandler(listItem, button)
    if button ~= 1 then
        return false
    end

    local layerName = listItem.data
    local newVisible = not loadedState.getLayerVisible(layerName)

    loadedState.setLayerVisible(layerName, newVisible)
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
        element.text = data.text
        element.data = data.data
        element.tooltipText = data.tooltip
        element.itemFavorited = data.itemFavorited
        element.originalText = data.text
        element.itemData = data

        updateListItemFavoriteVisuals(element)
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

local function getLayerItemName(language, layer, subLayer, noIndent, forceSubLayer)
    local layersNames = language.layers.name
    local displayName = getLanguageOrDefault(layersNames[layer], layer)
    local defaultSubLayer = not subLayer or subLayer == -1

    if not forceSubLayer and defaultSubLayer then
        return displayName
    end

    local layerDisplayName = subLayers.getLayerName(layer, subLayer)

    if not layerDisplayName or utils.trim(layerDisplayName) == "" then
        subLayer = subLayer or 0
        layerDisplayName = string.format("%s %s", displayName, subLayer + 1)
    end

    if noIndent then
        return layerDisplayName
    end

    return string.format("  %s", layerDisplayName)
end

local function getLayerItems(toolName)
    local language = languageRegistry.getLanguage()
    local layers = toolHandler.getLayers(toolName) or {}
    local layerItems = {}

    local layersDescriptions = language.layers.description

    local allSubLayers = toolWindow.subLayers

    for _, layer in ipairs(layers) do
        local tooltipText = getLanguageOrDefault(layersDescriptions[layer])

        local layerBlank = layersWithBlankIcon[layer]
        local layerVisible = loadedState.getLayerVisible(layer)
        local icon = layerVisible and "visible" or "hidden"

        if layerBlank then
            icon = "blank"
        end

        -- Layer with -1 means all layers
        local item = {
            text = getLayerItemName(language, layer),
            data = subLayers.formatLayerName(layer, -1),
            layerVisible = layerVisible,
            tooltipText = tooltipText,
            subLayer = -1,
            icon = icon,
            iconClicked = layerItemToggleVisibilityHandler,
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
                    local subLayerVisible = loadedState.getLayerVisible(layerName)
                    local subItem = {
                        text = getLayerItemName(language, layer, subLayer),
                        data = layerName,
                        layerVisible = subLayerVisible,
                        tooltipText = tooltipText,
                        subLayer = subLayer,
                        icon = subLayerVisible and "visible" or "hidden",
                        iconClicked = layerItemToggleVisibilityHandler,
                    }

                    table.insert(layerItems, subItem)
                end
            end
        end
    end

    return layerItems
end

local function deleteSubLayerInfo(layer, subLayer)
    local layerInfo = toolWindow.subLayers[layer]

    if layerInfo and layerInfo[subLayer] then
        layerInfo[subLayer] = nil

        -- Check if we only have a single layer left and notify the user
        local layerCount = utils.countKeys(layerInfo)

        if layerCount == 0 or layerCount == 1 then
            local language = languageRegistry.getLanguage()
            local existingLayerIndex = next(layerInfo)
            local layerName = getLayerItemName(language, layer, existingLayerIndex, true, true)

            notifications.notify(string.format(tostring(language.ui.tools_window.remove_last_sub_layer), layerName))
        end
    end
end

local function deleteSubLayer(layer, subLayer)
    local map = loadedState.map
    local snapshot, relevantRooms = selectionUtils.deleteSubLayer(map, layer, subLayer)

    if snapshot then
        history.addSnapshot(snapshot)

        for _, room in ipairs(relevantRooms) do
            toolUtils.redrawTargetLayer(room, layer)
            celesteRender.invalidateRoomCache(room, {"canvas", "complete"})
        end

        return true
    end
end

local function addSubLayerInfo(layer, subLayer)
    if not layersWithSubLayers[layer] then
        return
    end

    if not toolWindow.subLayers[layer] then
        toolWindow.subLayers[layer] = {}
    end

    local layerInfo = toolWindow.subLayers[layer]
    local layerCount = #layerInfo
    local layerKeysCount = utils.countKeys(layerInfo)
    local shouldNotifyUser = layerKeysCount == 0 or layerKeysCount == 1

    if shouldNotifyUser then
        local language = languageRegistry.getLanguage()
        local existingLayerIndex = next(layerInfo)
        local layerName = getLayerItemName(language, layer, existingLayerIndex, true, true)

        notifications.notify(string.format(tostring(language.ui.tools_window.add_first_sub_layer), layerName))
    end

    -- Special case for when no editor layers are found at all
    if layerCount == 0 then
        layerInfo[0] = 0
        layerInfo[1] = 1

        return 1
    end

    -- Find first empty layer index
    for i = 0, layerCount + 1 do
        if not layerInfo[i] then
            layerInfo[i] = i

            return i
        end
    end
end

local function layerListInlineRename(layer, subLayer, layerListItem)
    -- Remove the label and insert a textfield in its place
    local oldLabel = layerListItem.label
    local icon = layerListItem.children[1]

    local language = languageRegistry.getLanguage()
    local initialText = getLayerItemName(language, layer, subLayer, true)

    local function layout()
        layerListItem:layout()
        layerListItem:layoutLate()
        layerListItem.parent:layout()
        layerListItem.parent:layoutLate()
    end

    local function unfocusCleanup(field)
        -- Remove field and readd the label
        field:removeSelf()
        layerListItem:addChild(oldLabel)

        layout()
    end

    -- Fill width doesn't work, do some rough calculations
    local fieldWidth = layerListItem.width - icon.width - layerListItem.style.spacing * 3
    local field = uiElements.field(initialText, function(_, text)
        oldLabel.text = text
        subLayers.setLayerName(layer, subLayer, text)
    end):with({
        style = {
            padding = 0,
            spacing = 0,
        }
    }):hook({
        onKeyRelease = function(orig, self, key, ...)
            if key == "return" or key == "escape" then
                return unfocusCleanup(self)
            end

            return orig(self, key, ...)
        end,
        onUnfocus = function(_, self)
            unfocusCleanup(self)
        end,
    }):with({
        width = fieldWidth
    })

    table.remove(layerListItem.children)
    table.insert(layerListItem.children, field)

    widgetUtils.focusElement(field)
    field.index = #initialText

    layout()
end

local function layerContextMenuClickHandler(layer, subLayer, layerListItem)
    return function(element, action)
        local updateList = false
        local listTarget

        if action == "add" then
            local newSubLayer = addSubLayerInfo(layer, subLayer)

            if newSubLayer then
                listTarget = subLayers.formatLayerName(layer, newSubLayer)
                updateList = true
            end

        elseif action == "delete" then
            deleteSubLayer(layer, subLayer)
            deleteSubLayerInfo(layer, subLayer)

            listTarget = layer
            updateList = true

        elseif action == "rename" then
            layerListInlineRename(layer, subLayer, layerListItem)
        end

        if updateList then
            toolWindow.layerList:updateItems(getLayerItems(), listTarget)
        end

        element.parent.parent:removeSelf()
    end
end

local function layerContextMenu(listItem)
    local layerName = listItem.data

    if not layerName then
        return
    end

    local layer, subLayer = subLayers.parseLayerName(layerName)

    if not layersWithSubLayers[layer] then
        return false
    end

    local language = languageRegistry.getLanguage()
    local listItems = {
        uiElements.listItem({
            text = tostring(language.ui.tools_window.add_sub_layer),
            data = "add"
        })
    }

    if subLayer ~= -1 then
        table.insert(listItems, uiElements.listItem({
            text = tostring(language.ui.tools_window.delete_sub_layer),
            data = "delete"
        }))

        table.insert(listItems, uiElements.listItem({
            text = tostring(language.ui.tools_window.rename_sub_layer),
            data = "rename"
        }))
    end

    local content = uiElements.column({
        uiElements.list(
            listItems,
            layerContextMenuClickHandler(layer, subLayer, listItem)
        )
    })

    return content
end

local function layerDataToElement(list, data, element)
    if not element then
        element = uiElements.listItem()

        element:layout()
    end

    if data then
        element.text = data.text
        element.data = data.data
        element.tooltipText = data.tooltip
        element.layerVisible = data.layerVisible
        element.itemData = data
        element.subLayer = data.subLayer
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
        local targetLayerName = subLayers.formatLayerName(layer, subLayer)

        toolWindow.eventStates.searchTerm = searchText
        toolWindow.eventStates.layer = layer
        toolWindow.eventStates.subLayer = subLayer

        toolWindow.materialList:setFilterText(searchText, true)
        toolWindow.layerList:updateItems(getLayerItems(), targetLayerName, nil, true)

        if not sameLayer then
            toolWindow.materialList:updateItems(getMaterialItems(layer), targetMaterial)
        end
    end
end

local function updateLayerList(toolName, tool, targetLayer, preventCallback)
    if not toolName then
        toolName = toolHandler.currentToolName
    end

    local items = getLayerItems(toolName)

    if toolName and not tool then
        tool = toolHandler.tools[toolName]
    end

    if tool and not targetLayer then
        targetLayer = toolUtils.getPersistenceLayer(tool)
    end

    toolWindow.layerList:updateItems(items, targetLayer, nil, preventCallback)

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

    updateLayerList(toolName, toolHandler.tools[toolName], layerName, true)
    widgetUtils.updateHoveredTarget()
end

local function layerAddedCallback(_, layer, subLayer)
    if not toolWindow.subLayers[layer] then
        toolWindow.subLayers[layer] = {}
    end

    toolWindow.subLayers[layer][subLayer] = subLayer
end

local function layerDeletedCallback(_, layer, subLayer)
    if toolWindow.subLayers[layer] then
        toolWindow.subLayers[layer][subLayer] = nil
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

    local currentTool = toolHandler.currentTool
    local currentLayer = toolHandler.getLayer()
    local currentSubLayer = currentTool.subLayer
    local initialLayer = subLayers.formatLayerName(currentLayer, currentSubLayer)
    local layerListOptions = {
        initialItem = initialLayer,
        dataToElement = layerDataToElement,
        listItemDoubleClicked = layerItemToggleVisibilityHandler,
        listItemContextMenu = layerContextMenu,
        listItemContextMenuOptions = {
            mode = "focused"
        }
    }

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
        editorLayerAdded = layerAddedCallback,
        editorLayerDeleted = layerDeletedCallback,

        interactive = 0
    })

    window.style.bg = {}
    window.style.border = {}
    window.style.padding = row.style.spacing

    widgetUtils.removeWindowTitlebar(window)

    return simpleDocks.pinWidgetToEdge("right", window)
end

return toolWindow
