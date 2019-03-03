-- Temporary for now
local function getResourceDir()
    local appdata = os.getenv("LocalAppData")
    local home = os.getenv("home")

    if appdata then
        return appdata .. "/Loenn"

    else
        return home .. "/.loenn"
    end
end

return {
    getResourceDir = getResourceDir
}