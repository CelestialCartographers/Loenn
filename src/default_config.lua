local utils = require("utils")

local defaultsPath = "defaults/config"
local defaultsUIPath = "ui/defaults/config"

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

defaultData.ui = defaultUIData

return defaultData
