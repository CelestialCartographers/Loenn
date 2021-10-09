local utils = require("utils")
local tasks = require("utils.tasks")

local pluginLoader = {}

-- If extension is false all files are allowed
-- Otherwise make sure ext of filename matches the expected one
local function extentionCheck(ext, filename)
    return not ext or utils.fileExtension(filename) == ext
end

-- Path can either be a path to list items from or a list of prefound filenames
function pluginLoader.loadPlugins(path, registerAt, loadFunction, shouldYield, ext)
    ext = ext == nil and "lua" or ext
    shouldYield = shouldYield or shouldYield == nil

    local filenames = path

    if type(path) == "string" then
        filenames = {}

        for _, filename in ipairs(love.filesystem.getDirectoryItems(path)) do
            local pluginPath = utils.convertToUnixPath(utils.joinpath(path, filename))

            table.insert(filenames, pluginPath)
        end
    end

    for _, filename in ipairs(filenames) do
        -- Make sure we only load valid plugins for the load function
        if extentionCheck(ext, filename) then
            loadFunction(filename, registerAt)
        end

        if shouldYield then
            tasks.yield()
        end
    end

    if shouldYield then
        tasks.update(registerAt)
    end
end

return pluginLoader