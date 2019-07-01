local utils = require("utils")
local lfs = require("lfs_ffi")

local config = {}
local configMt = {}

-- Get raw data out from filename
function config.readConfigData(filename)
    local res
    local tempFilename = filename .. ".saving"

    local tempExists = utils.isFile(tempFilename)
    local targetExists = utils.isFile(filename)

    -- Program terminated before the config got moved
    -- Temporary file holds the correct data
    if not targetExists and tempExists then
        os.rename(tempFilename, filename)
    end

    -- Program was terminated while config was saved
    if tempExists then
        os.remove(tempFilename)
    end

    local fh = io.open(filename, "rb")

    if fh then
        local content = fh:read("*a")
        res = utils.unserialize(content)
        
        fh:close()
    end

    return res
end

-- Save raw data to filename
-- Save to temporary filename first and then move to the correct filename
-- This prevents corruption of data if program is terminated while writing
function config.writeConfigData(filename, data, pretty)
    local pretty = pretty == nil or pretty
    local success, content = false, nil

    if data then
        local tempFilename = filename .. ".saving"
        success, content = utils.serialize(data, pretty)

        if success then
            lfs.mkdir(utils.dirname(filename))
            fh = io.open(tempFilename, "wb")
            
            if fh then
                fh:write(content)
                fh:close()

                os.rename(tempFilename, filename)

            else
                success = false
            end
        end
    end

    return success
end

function config.createConfig(filename, data, bufferTime, matchDisk, pretty)
    local conf = {
        __type = "config"
    }

    conf.filename = filename
    conf.data = data or {}
    conf.bufferTime = bufferTime or -1
    conf.matchDisk = matchDisk == nil or matchDisk
    conf.pretty = pretty == nil or pretty
    conf.mtime = os.time()

    return setmetatable(conf, configMt)
end

function config.readConfig(filename, bufferTime, matchDisk, pretty)
    return config.createConfig(filename, config.readConfigData(filename), bufferTime, matchDisk, pretty)
end

function config.updateConfig(conf)
    local matchDisk = rawget(conf, "matchDisk")

    if matchDisk then
        local mtime = rawget(conf, "mtime") or 0
        local filename = rawget(conf, "filename")
        local attrs = lfs.attributes(filename)

        if attrs and attrs.modification > mtime then
            rawset(conf, "data", config.readConfigData(filename))
            rawset(conf, "mtime", os.time())
        end
    end
end

function config.writeConfig(conf)
    local mtime = rawget(conf, "mtime") or 0
    local bufferTime = rawget(conf, "bufferTime") or -1

    if bufferTime <= 0 or mtime + bufferTime < os.time() then
        local filename = rawget(conf, "filename")
        local pretty = rawget(conf, "pretty")
        local data = rawget(conf, "data")

        config.writeConfigData(filename, data, pretty)

        rawset(conf, "mtime", os.time())
    end
end

function configMt.__index(self, key)
    config.updateConfig(self)

    return self.data[key]
end

function configMt.__newindex(self, key, value)
    local valueChanged = value ~= self[key]

    self.data[key] = value

    if valueChanged then
        config.writeConfig(self)
    end
end

return config