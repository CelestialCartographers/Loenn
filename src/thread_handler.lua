local threadHandler = {}

threadHandler._threads = {}

function threadHandler.createStartWithCallback(threadCode, callback, ...)
    local thread = love.thread.newThread(threadCode)
    local channel = love.timer.getTime()

    threadHandler._threads[channel] = {thread = thread, callback = callback, channel = channel}
    thread:start(channel, ...)

    return thread
end

function threadHandler.update(dt)
    for channelName, data <- threadHandler._threads do
        local thread = data.thread
        local callback = data.callback

        if not thread:isRunning() then
            local channel = love.thread.getChannel(channelName)
            local res = channel:pop()

            channel:release()
            thread:release()
            threadHandler._threads[channelName] = nil

            callback(res)
        end
    end
end

return threadHandler