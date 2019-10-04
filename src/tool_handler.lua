local utils = require("utils")
local tasks = require("task")

local toolHandler = {}

toolHandler.tools = {}
toolHandler.currentTool = nil
toolHandler.currentToolName = nil

function toolHandler.selectTool(name)
    local handler = toolHandler.tools[name]

    if handler then
        toolHandler.currentTool = handler
        toolHandler.currentToolName = name
    end

    return handler ~= nil
end

function toolHandler.loadTool(fn)
    local pathNoExt = utils.stripExtension(fn)
    local filenameNoExt = utils.filename(pathNoExt, "/")

    local handler = utils.rerequire(pathNoExt)
    local name = handler.name or filenameNoExt

    print("! Loaded tool '" .. name ..  "'")

    toolHandler.tools[name] = handler

    if not toolHandler.currentTool then
        toolHandler.selectTool(name)
    end

    return name
end

function toolHandler.loadInternalTools(path)
    path = path or "tools"

    for i, file <- love.filesystem.getDirectoryItems(path) do
        -- Always use Linux paths here
        toolHandler.loadTool(utils.joinpath(path, file):gsub("\\", "/"))

        tasks.yield()
    end

    tasks.update(toolHandler.tools)
end

return toolHandler