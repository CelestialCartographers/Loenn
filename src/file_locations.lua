local physfs = require("physfs")

local fileLocations = {}

-- TODO - Sorta deprecated, keep around for now
fileLocations.useInternal = false

local loennUpper = "Loenn"
local loennLower = "loenn"

function fileLocations.getStorageDir()
    local userOS = love.system.getOS()
    local sep = physfs.getDirSeparator()

    if userOS == "Windows" then
        return os.getenv("LocalAppData") .. sep .. loennUpper

    elseif userOS == "Linux" then
        -- TODO - Is this good enough? Better alternative?
        return os.getenv("HOME") .. sep .. "." .. loennLower

    elseif userOS == "OS X" then
        -- TODO

    elseif userOS == "Android" then
        -- TODO

    elseif userOS == "iOS" then
        -- TODO
    end
end

return fileLocations