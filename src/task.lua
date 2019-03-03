local tasks = {}

local function processTasks(calcTime)
    local calcTime = calcTime or math.inf

    while #tasks > 0 do
        local task = tasks[1]

        while coroutine.status(task.coroutine) ~= "dead" do
            if calcTime < 0 then
                return false
            end

            local start = love.timer.getTime()
            local success, res = coroutine.resume(task.coroutine)

            if res then
                task.result = res
            end

            local stop = love.timer.getTime()
            local deltaTime = stop - start
            calcTime -= deltaTime

            --print("Worked on task for " .. tostring(deltaTime * 1000) .. "ms")
            --print("Timeleft " .. tostring(calcTime * 1000) .. "ms")
        end

        if coroutine.status(task.coroutine) == "dead" then
            task.callback()
            table.remove(tasks, 1)
        end
    end

    return true
end

local function newTask(func, callback)
    local task = {
        coroutine = coroutine.create(func),
        callback = callback or function() end
    }
    
    table.insert(tasks, task)

    return task
end

return {
    processTasks = processTasks,
    newTask = newTask
}