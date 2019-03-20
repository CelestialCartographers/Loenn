local fileLocations = {}

fileLocations.useInternal = false

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

function fileLocations.getStorageDir()
    local userOS = love.system.getOS()

    if userOS == "Windows" then
        return os.getenv("LocalAppData") .. "/Lönn"

    elseif userOS == "Linux" then
        -- TODO - Is this good enough? Better alternative?
        -- Doesn't work on Linux when creating folders for some reason?
        return os.getenv("HOME") .. "/.lönn"

    elseif userOS == "OS X" then
        -- TODO

    elseif userOS == "Android" then
        -- TODO

    elseif userOS == "iOS" then
        -- TODO
    end
end

return fileLocations