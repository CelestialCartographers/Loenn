local fileLocations = {}

fileLocations.useInternal = false

local loennUpper = "L" .. string.char(148) .. "nn"
local loennLower = "l" .. string.char(148) .. "nn"

-- Temporary for now
function fileLocations.getResourceDir()
    if useInternal then
        return "celesteResources"

    else
        local appdata = os.getenv("LocalAppData")
        local home = os.getenv("HOME")

        if appdata then
            return appdata .. "/Loenn"

        else
            return home .. "/.loenn"
        end
    end
end

-- TODO - Figure out how to create this folder automatically
-- Problems with love2d filesystem
-- Assume user has the folder at the moment
function fileLocations.getStorageDir()
    local userOS = love.system.getOS()

    if userOS == "Windows" then
        return os.getenv("LocalAppData"):gsub("\\", "/") .. "/" .. loennUpper

    elseif userOS == "Linux" then
        -- TODO - Is this good enough? Better alternative?
        return os.getenv("HOME") .. "/." .. loennLower

    elseif userOS == "OS X" then
        -- TODO

    elseif userOS == "Android" then
        -- TODO

    elseif userOS == "iOS" then
        -- TODO
    end
end

return fileLocations