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

return fileLocations