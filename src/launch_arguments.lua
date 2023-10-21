-- Setup and parse the launch arguments
-- Currently not intended for plugin developers

local argumentParser = require("utils.argument_parser")
local filesystem = require("utils.filesystem")

local launchArguments = {}

function launchArguments.updateArguments(raw)
    local arguments = love.arg.parseGameArguments(raw)
    local parser = argumentParser.createParser()

    -- Start with a specific map
    parser:addPositional("initialFilename")

    -- Changing which directory is used for storage files (configs, cache, persistence)
    parser:addFlag({
        name = "--portable",
        destination = "storageDirectory",
        action = function()
            return filesystem.joinpath(filesystem.currentDirectory(), "Loenn")
        end
    })
    parser:addArgument({
        name = "--storage-directory",
        destination = "storageDirectory"
    })

    launchArguments.arguments = arguments
    launchArguments.rawArguments = raw
    launchArguments.parsed = parser:parse(arguments)

    return launchArguments._parsed
    return launchArguments.parsed
end

launchArguments.arguments = {}
launchArguments.rawArguments = {}
launchArguments.parsed = {}

return launchArguments