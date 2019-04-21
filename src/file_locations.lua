local filesystem = require("filesystem")

local fileLocations = {}

-- TODO - Sorta deprecated, keep around for now
fileLocations.useInternal = false

local loennUpper = "Loenn"
local loennLower = "loenn"

function fileLocations.getStorageDir()
    local userOS = love.system.getOS()

    if userOS == "Windows" then
        return filesystem.joinpath(os.getenv("LocalAppData"), loennUpper)

    elseif userOS == "Linux" then
        -- TODO - Is this good enough? Better alternative?
        return filesystem.joinpath(os.getenv("HOME"), "." .. loennLower)

    elseif userOS == "OS X" then
        -- TODO

    elseif userOS == "Android" then
        -- TODO

    elseif userOS == "iOS" then
        -- TODO
    end
end

return fileLocations