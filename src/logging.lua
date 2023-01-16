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
    local formattedMessage = string.format("[%s] %s", status, message)
    local shouldLog = true
    local shouldFlush = true

    -- These might not be loaded yet, and we can not load them early
    local fileLocations = package.loaded["file_locations"]
    local configs = package.loaded["configs"]

    -- Fallback to log path if posible, file_locations might not be loaded yet
    if not filename and fileLocations then
        filename = fileLocations.getLogPath()
    end

    -- Always log if configs is not loaded yet
    if configs then
        local levelThreshold = configs.debug.loggingLevel
        local flushImmediatelyLevel = configs.debug.loggingFlushImmediatelyLevel
        local level = logging.logLevels[status]

        shouldLog = level >= levelThreshold
        shouldFlush = level >= flushImmediatelyLevel
    end

    if shouldLog then
        -- Both print the message and add it to the queue
        print(formattedMessage)

        if filename then
            logging.bufferAddMessage(filename, formattedMessage)

            -- In case of errors the log must be flushed immediately
            if shouldFlush then
                logging.bufferWrite(filename)
            end
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