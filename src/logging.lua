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

function logging.log(status, message, filename, force)
    local formattedMessage = message

    if status and message then
        formattedMessage = string.format("[%s] %s", status, message)
    end

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
        local level = logging.logLevels[status] or logging.logLevels.INFO

        shouldLog = level >= levelThreshold
        shouldFlush = level >= flushImmediatelyLevel
    end

    if shouldLog or force then
        -- Both print the message and add it to the queue
        print(formattedMessage)

        if filename then
            logging.bufferAddMessage(filename, formattedMessage)

            -- In case of errors the log must be flushed immediately
            if shouldFlush or force then
                logging.bufferWrite(filename)
            end
        end
    end
end

function logging.debug(...)
    return logging.log("DEBUG", ...)
end

function logging.info(...)
    return logging.log("INFO", ...)
end

function logging.warning(...)
    return logging.log("WARNING", ...)
end

function logging.error(...)
    return logging.log("ERROR", ...)
end

return logging