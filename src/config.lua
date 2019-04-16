local utils = require("utils")

local config = {}

local configMt = {}
configMt.__index = {}

-- TODO - Make it possible to check file on disk for changes on read and write changes to disk on write

function config.readConfig(filename)
    local res
    local fh = io.open(filename, "rb")

    if fh then
        local content = fh:read("*a")

        res = utils.unserialize(content)
    end

    fh:close()

    return res
end

-- TODO - Currently assuming directory exists
function config.writeConfig(filename, data, pretty)
    local pretty = pretty == nil or pretty
    local success, content = false, nil

    if data then
        success, content = utils.serialize(data, pretty)

        if success then
            fh = io.open(filename, "wb")
            
            if fh then
                fh:write(content)
                fh:close()

            else
                success = false
            end
        end

    end

    return success
end

return config