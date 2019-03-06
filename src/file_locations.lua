local useInternal = false

-- Temporary for now
local function getResourceDir()
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

return {
    getResourceDir = getResourceDir,
    useInternal = useInternal
}