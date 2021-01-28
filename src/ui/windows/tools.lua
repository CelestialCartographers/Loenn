local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")
local listWidgets = require("ui.widgets.lists")
local toolHandler = require("tool_handler")

local toolWindow = {}

toolWindow.toolList = false
toolWindow.layerList = false
toolWindow.materialList = false

-- TODO - Use lang file
local function getMaterialItems(layer)
    local materials = toolHandler.getMaterials(nil, layer)
    local materialItems = {}

    for _, material in ipairs(materials) do
        local materialText = material
        local materialData = material
        local materialType = type(material)

        if materialType == "table" then
            materialText = material.displayName or material.name
            materialData = material.name
        end

        table.insert(materialItems, uiElements.listItem({
            text = materialText,
            data = materialData
        }))
    end

    return materialItems
end

local function materialCallback(list, material)
    toolHandler.setMaterial(material)
end

local function getLayerItems(toolName)
    local layers = toolHandler.getLayers(toolName)
    local layerItems = {}

    for _, layer in ipairs(layers) do
        table.insert(layerItems, uiElements.listItem({
            text = layer,
            data = layer
        }))
    end

    return layerItems
end

local function layerCallback(list, layer)
    toolHandler.setLayer(layer)

    local materialItems = getMaterialItems(layer)

    listWidgets.updateItems(toolWindow.materialList, materialItems)
end

-- TODO - Sort/group results
local function getToolItems()
    local tools = toolHandler.tools
    local toolItems = {}

    for name, tool in pairs(tools) do
        table.insert(toolItems, uiElements.listItem({
            text = name,
            data = name
        }))
    end

    return toolItems
end

local function toolCallback(list, toolName)
    toolHandler.selectTool(toolName)

    local layerItems = getLayerItems(toolName)

    listWidgets.updateItems(toolWindow.layerList, layerItems)
end

function toolWindow.getWindow()
    local toolItems = getToolItems()
    local layerItems = getLayerItems()
    local materialItems = getMaterialItems()

    local scrolledMaterialList, materialList = listWidgets.getList(materialCallback, materialItems)
    local scrolledLayerList, layerList = listWidgets.getList(layerCallback, layerItems)
    local scrolledToolList, toolList = listWidgets.getList(toolCallback, toolItems)

    toolWindow.toolList = toolList
    toolWindow.layerList = layerList
    toolWindow.materialList = materialList

    local row = uiElements.row({
        scrolledToolList,
        scrolledLayerList,
        scrolledMaterialList
    }):with(uiUtils.fillHeight(true))

    return uiElements.window("Tools", row):with(uiUtils.fillHeight(false))
end

return toolWindow