local threadHandler = {}

threadHandler._threads = {}

function threadHandler.createStartWithCallback(threadCode, callback, ...)
    local thread = love.thread.newThread(threadCode)
    local channel = love.timer.getTime()

    threadHandler._threads[channel] = {thread = thread, callback = callback, channel = channel}
    thread:start(channel, ...)

    return channel, thread
end

function threadHandler.release(channelName)
    if threadHandler._threads[channelName] then
        local channel = love.thread.getChannel(channelName)
        local thread = threadHandler._threads[channelName].thread

        channel:release()
        thread:release()

        threadHandler._threads[channelName] = nil
    end
end

function threadHandler.update(dt)
    local removed = {}

    for channelName, data <- threadHandler._threads do
        local thread = data.thread
        local callback = data.callback

        if not thread:isRunning() then
            local channel = love.thread.getChannel(channelName)
            local res = channel:pop()

            table.insert(removed, channelName)

            callback(res)
        end
    end

    for i, channelName <- removed do
        threadHandler.release(channelName)
    end
end

return threadHandler