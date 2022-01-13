local utils = require("utils")
local configs = require("configs")
local persistence = require("persistence")
local pluginLoader = require("plugin_loader")
local modHandler = require("mods")
local toolUtils = require("tool_utils")
local logging = require("logging")

local toolHandler = {}

toolHandler.tools = {}
toolHandler.currentTool = nil
toolHandler.currentToolName = nil

function toolHandler.selectTool(name)
    local handler = toolHandler.tools[name]
    local currentTool = toolHandler.currentTool

    if handler and currentTool ~= handler then
        if currentTool and currentTool.unselected then
            currentTool.unselected(name)
        end

        toolHandler.currentTool = handler
        toolHandler.currentToolName = name

        if handler.selected then
            handler.selected()
        end

        toolUtils.sendToolEvent(handler)

        -- Load previous mode and layer from persistence

        local modeValue = toolUtils.getPersistenceMode(handler)
        local layerValue = toolUtils.getPersistenceLayer(handler)

        if modeValue then
            toolHandler.setMode(modeValue, name)
        end

        if layerValue then
            toolHandler.setLayer(layerValue, name)
        end
    end

    return handler ~= nil
end

function toolHandler.loadTool(filename)
    local pathNoExt = utils.stripExtension(filename)
    local filenameNoExt = utils.filename(pathNoExt, "/")

    local handler = utils.rerequire(pathNoExt)
    local name = handler.name or filenameNoExt

    -- Make sure tools always have a name
    handler.name = name

    if configs.debug.logPluginLoading then
        logging.info("Loaded tool '" .. name ..  "'")
    end

    toolHandler.tools[name] = handler

    if handler and handler.load then
        handler.load()
    end

    return name
end

function toolHandler.unloadTools()
    toolHandler.currentTool = nil
    toolHandler.currentToolName = nil
    toolHandler.tools = {}
end

local function getHandler(name)
    name = name or toolHandler.currentToolName

    return toolHandler.tools[name], name
end

function toolHandler.getMaterials(name, layer)
    local handler = getHandler(name)

    if handler and handler.getMaterials then
        return handler.getMaterials(layer)
    end

    return {}
end

function toolHandler.setMaterial(material, name)
    local handler, toolName = getHandler(name)

    if handler then
        local result = false
        local oldMaterial = toolHandler.getMaterial(name)

        if handler.setMaterial then
            result = handler.setMaterial(material, oldMaterial)
        end

        if result ~= false then
            local layer = toolHandler.getLayer(name)

            toolUtils.sendMaterialEvent(handler, layer, material)
        end

        return result
    end

    return false
end

function toolHandler.getMaterial(name)
    local handler = getHandler(name)

    if handler then
        if handler.getMaterial then
            return handler.getMaterial()

        else
            return handler.material
        end
    end

    return false
end

function toolHandler.getLayers(name)
    local handler = getHandler(name)

    if handler then
        if handler.getLayers then
            return handler.getLayers()

        else
            return handler.validLayers or {}
        end
    end

    return {}
end

function toolHandler.setLayer(layer, name)
    local handler, toolName = getHandler(name)

    if handler then
        local validLayers = toolHandler.getLayers(name)

        if not utils.contains(layer, validLayers) then
            return false
        end

        local oldLayer = toolHandler.getLayer(name)
        local result = true

        if handler.setLayer then
            result = handler.setLayer(layer, oldLayer)

        elseif handler.layer then
            handler.layer = layer

            local materialValue = toolUtils.getPersistenceMaterial(handler, layer)

            if materialValue then
                toolHandler.setMaterial(materialValue, name)
            end
        end

        if result ~= false then
            toolUtils.sendLayerEvent(handler, layer)
        end

        return result
    end

    return false
end

function toolHandler.getLayer(name)
    local handler = getHandler(name)

    if handler then
        if handler.getLayer then
            return handler.getLayer()

        else
            return handler.layer
        end
    end

    return false
end

function toolHandler.getModes(name)
    local handler = getHandler(name)

    if handler then
        if handler.getModes then
            return handler.getModes()

        else
            return handler.modes or {}
        end
    end

    return {}
end

function toolHandler.setMode(mode, name)
    local handler, toolName = getHandler(name)

    if handler then
        local modes = toolHandler.getModes(name)

        if not utils.contains(mode, modes) then
            return false
        end

        local result = true
        local oldMode = toolHandler.getMode(name)

        if handler.setMode then
            result = handler.setMode(mode, oldMode)

        elseif handler.mode then
            handler.mode = mode
        end

        if result ~= false then
            toolUtils.sendToolModeEvent(handler, mode)
        end

        return result
    end

    return false
end

function toolHandler.getMode(name)
    local handler = getHandler(name)

    if handler then
        if handler.getMode then
            return handler.getMode()

        else
            return handler.mode
        end
    end

    return false
end

function toolHandler.loadInternalTools(path)
    path = path or "tools"
    local previousToolName = persistence.toolName

    pluginLoader.loadPlugins(path, nil, toolHandler.loadTool)
    toolHandler.selectTool(previousToolName)

    -- Select the first tool (alphabetically) if none is selected
    if not toolHandler.currentTool then
        local toolNames = table.keys(toolHandler.tools)

        table.sort(toolNames)
        toolHandler.selectTool(toolNames[1])
    end
end

function toolHandler.loadExternalTools()
    local filenames = modHandler.findPlugins("tools")

    pluginLoader.loadPlugins(filenames, nil, toolHandler.loadTool)
end

return toolHandler