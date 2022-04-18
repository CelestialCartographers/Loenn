-- Load user settings and default to internal settings
-- Should be easily accessible from code

local utils = require("utils")
local config = require("utils.config")
local fileLocations = require("file_locations")

local defaultsPath = "defaults/config"
local defaultsUIPath = "ui/defaults/config"

local configs = config.readConfig(fileLocations.getSettingsPath())

local function mergeIfMissing(from, to)
    local madeChanges = false

    for k, v in pairs(from) do
        if to[k] == nil then
            to[k] = v
            madeChanges = true

        elseif type(to[k]) == "table" and type(v) == "table" then
            madeChanges = madeChanges or mergeIfMissing(v, to[k])
        end
    end

    return madeChanges
end

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

local mergedDefaults = mergeIfMissing(defaultData, configs)
local mergedUIDefaults = mergeIfMissing({ui = defaultUIData}, configs)

if mergedDefaults or mergedUIDefaults then
    config.writeConfig(configs, true)
end

return configs