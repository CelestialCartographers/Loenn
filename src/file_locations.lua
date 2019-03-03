-- Temporary for now
local function getResourceDir()
    local appdata = os.getenv("LocalAppData")
    local home = os.getenv("HOME")

    if appdata then
        return appdata .. "/Loenn"

    else
        return home .. "/.loenn"
    end
end

return {
    getResourceDir = getResourceDir
}