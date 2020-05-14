-- Load user settings and default to internal settings
-- Should be easily accessible from code

local utils = require("utils")
local config = require("config")
local fileLocations = require("file_locations")

local defaultsPath = "defaults/config"
local defaultValues = {}

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

for _, file in ipairs(love.filesystem.getDirectoryItems(defaultsPath)) do
    local filenameNoExt = utils.stripExtension(file)
    local default = require(defaultsPath .. "." .. filenameNoExt)

    defaultValues[filenameNoExt] = default
end

if mergeIfMissing(defaultValues, configs) then
    config.writeConfig(configs, true)
end

return configs