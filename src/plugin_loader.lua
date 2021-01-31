local utils = require("utils")
local tasks = require("task")

local pluginLoader = {}

-- Path can either be a path to list items from or a list of prefound filenames
function pluginLoader.loadPlugins(path, registerAt, loadFunction)
    local filenames = path

    if type(path) == "string" then
        filenames = {}

        for _, filename in ipairs(love.filesystem.getDirectoryItems(path)) do
            local entityPath = utils.convertToUnixPath(utils.joinpath(path, filename))

            table.insert(filenames, entityPath)
        end
    end

    for _, filename in ipairs(filenames) do
        loadFunction(filename, registerAt)
        tasks.yield()
    end

    tasks.update(registerAt)
end

return pluginLoader