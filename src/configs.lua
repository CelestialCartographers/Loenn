-- Load user settings and default to internal settings
-- Should be easily accessible from code

local utils = require("utils")
local config = require("utils.config")
local fileLocations = require("file_locations")

local defaultsPath = "defaults/config"
local defaultsUIPath = "ui/defaults/config"

local configs = config.readConfig(fileLocations.getSettingsPath())

local function readDefaultData(path)
    local data = {}

    for _, file in ipairs(love.filesystem.getDirectoryItems(path)) do
        local filenameNoExt = utils.stripExtension(file)
        local default = require(path .. "." .. filenameNoExt)

        data[filenameNoExt] = default
    end

    return data
end

local defaultData = readDefaultData(defaultsPath)
local defaultUIData = readDefaultData(defaultsUIPath)

local mergedDefaults = utils.mergeTables(defaultData, configs)
local mergedUIDefaults = utils.mergeTables({ui = defaultUIData}, configs)

if mergedDefaults or mergedUIDefaults then
    config.writeConfig(configs, true)
end

-- Full config as standard table for default values, matching structure of the config itself
local defaultDataComplete = utils.deepcopy(defaultData)

defaultDataComplete.ui = defaultUIData

return configs, defaultDataComplete