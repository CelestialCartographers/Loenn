local utils = require("utils")
local config = require("config")

local configs = {}

configs._defaultPath = "defaults/config"

-- TODO - Merge user configs on top
for i, file <- love.filesystem.getDirectoryItems(configs._defaultPath) do
    local filenameNoExt = utils.stripExtension(file)

    configs[filenameNoExt] = require(configs._defaultPath .. "/" .. filenameNoExt)
end

return configs