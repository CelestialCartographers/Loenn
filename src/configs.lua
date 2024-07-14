-- Load user settings and default to internal settings
-- Should be easily accessible from code

local utils = require("utils")
local config = require("utils.config")
local fileLocations = require("file_locations")

local configs = config.readConfig(fileLocations.getSettingsPath())
local defaultConfigData = require("default_config")

local mergedDefaults = utils.mergeTables(defaultConfigData, configs)

if mergedDefaults then
    config.writeConfig(configs, true)
end

return configs