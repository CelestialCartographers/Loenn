-- TODO - Hide material list if no materials?

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local widgetUtils = require("ui.widgets.utils")
local listWidgets = require("ui.widgets.lists")
local simpleDocks = require("ui.widgets.simple_docks")

local languageRegistry = require("language_registry")
local toolHandler = require("tool_handler")

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

local function getMaterialItems(layer, sortItems)
    local materials = toolHandler.getMaterials(nil, layer)
    local materialItems = {}

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

        local listItem = uiElements.listItem({
            text = materialText,
            data = materialData
        })

        listItem.tooltipText = materialTooltip
        table.insert(materialItems, listItem)
    end

    if sortItems or sortItems == nil then
        table.sort(materialItems, function(lhs, rhs)
            return lhs.text < rhs.text
        end)
    end

    return materialItems
end

local function materialCallback(list, material)
    toolHandler.setMaterial(material)
end

local function toolMaterialChangedCallback(self, tool, layer, material)
    listWidgets.setSelection(toolWindow.layerList, layer, true)
    listWidgets.setSelection(toolWindow.materialList, material, true)
end

local function getLanguageOrDefault(languagePath, default)
    if languagePath._exists then
        return tostring(languagePath)
    end

    return default
end

local function getLayerItems(toolName)
    local language = languageRegistry.getLanguage()
    local layers = toolHandler.getLayers(toolName) or {}
    local layerItems = {}

    for _, layer in ipairs(layers) do
        local displayName = getLanguageOrDefault(language.layers[layer].name, layer)
        local tooltipText = getLanguageOrDefault(language.layers[layer].description)

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
    toolHandler.setLayer(layer)
    listWidgets.updateItems(toolWindow.materialList, getMaterialItems(layer))
end

local function toolLayerChangedCallback(self, tool, layer)
    listWidgets.setSelection(toolWindow.layerList, layer, true)
    listWidgets.updateItems(toolWindow.materialList, getMaterialItems(layer))
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

    for _, mode in pairs(modes) do
        local displayName = getLanguageOrDefault(language.tools[toolName].modes[mode].name, mode)
        local tooltipText = getLanguageOrDefault(language.tools[toolName].modes[mode].description, mode)

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
    toolHandler.setMode(mode)
end

local function toolModeChangedCallback(self, tool, mode)
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

    for name, tool in pairs(tools) do
        local displayName = getLanguageOrDefault(language.tools[name].name, name)
        local tooltipText = getLanguageOrDefault(language.tools[name].description)

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
    toolHandler.selectTool(toolName)
    listWidgets.updateItems(toolWindow.layerList, getLayerItems(toolName))
end

local function toolChangedCallback(self, tool)
    listWidgets.setSelection(toolWindow.toolList, tool.name, true)
    updateLayerList(tool.name)
    updateToolModeList(tool.name)
end

function toolWindow.getWindow()
    local materialListOptions = {
        searchBarLocation = "below"
    }

    local toolItems = getToolItems()
    local layerItems = getLayerItems()
    local materialItems = getMaterialItems()
    local modeItems = getModeItems()

    local scrolledMaterialList, materialList = listWidgets.getList(materialCallback, materialItems, materialListOptions)
    local scrolledLayerList, layerList = listWidgets.getList(layerCallback, layerItems)
    local scrolledToolList, toolList = listWidgets.getList(toolCallback, toolItems)
    local scrolledModeList, modeList = listWidgets.getList(modeCallback, modeItems)

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

        interactive = 0
    })

    window.style.bg = {}
    window.style.border = {}

    widgetUtils.removeWindowTitlebar(window)

    return simpleDocks.pinWidgetToEdge("right", window)
end

return toolWindow