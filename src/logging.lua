local logging = {}

logging.logLevels = {
    DEBUG = 0,
    INFO = 1,
    WARNING = 2,
    ERROR = 3
}

local logBuffers = {}
local logBuffersModified = {}
local logBuffersMode = {}
local lastBufferCheck = -1

local logBufferCheckRate = 2.5
local logBufferInactive = 10

function logging.update(dt)
    local now = love.timer.getTime()

    if now > lastBufferCheck + logBufferCheckRate then
        for filename, buffer in pairs(logBuffers) do
            if now > logBuffersModified[filename] + logBufferInactive then
                logging.bufferWrite(filename)
            end
        end

        lastBufferCheck = now
    end
end

function logging.bufferAddMessage(filename, message)
    logBuffers[filename] = logBuffers[filename] or {}
    logBuffersModified[filename] = love.timer.getTime()

    table.insert(logBuffers[filename], message)
end

function logging.bufferWrite(filename)
    local buffer = logBuffers[filename]

    if buffer and #buffer > 0 then
        local mode = logBuffersMode[filename] or "wb"
        local fh = io.open(filename, mode)

        if fh then
            fh:write(table.concat(buffer, "\n") .. "\n")
            fh:close()
        end

        -- New buffer writes should append to the file
        logBuffersMode[filename] = "ab"
        logBuffers[filename] = nil
    end
end

function logging.log(status, message, filename)
    -- These don't exist when the program has just started
    local fileLocations = require("file_locations")
    local configs = require("configs")

    local levelThreshold = configs.debug.loggingLevel
    local flushImmediatelyLevel = configs.debug.loggingFlushImmediatelyLevel
    local level = logging.logLevels[status]

    if level >= levelThreshold then
        filename = filename or fileLocations.getLogPath()

        local formattedMessage = string.format("[%s] %s", status, message)

        -- Both print the message and add it to the queue
        print(formattedMessage)
        logging.bufferAddMessage(filename, formattedMessage)

        -- In case of errors the log must be flushed immediately
        if level >= flushImmediatelyLevel then
            logging.bufferWrite(filename)
        end
    end
end

function logging.debug(message, filename)
    return logging.log("DEBUG", message, filename)
end

function logging.info(message, filename)
    return logging.log("INFO", message, filename)
end

function logging.warning(message, filename)
    return logging.log("WARNING", message, filename)
end

function logging.error(message, filename)
    return logging.log("ERROR", message, filename)
end

return logging