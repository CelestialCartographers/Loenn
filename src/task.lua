local globalTasks = {}

local tasks = {}

-- Processes tasks from table for at around calcTime (default until done) and atmost maxTasks (default all)
-- Returns processingStatus, timeSpent
function tasks.processTasks(calcTime, maxTasks, customTasks)
    local tasks = customTasks or globalTasks

    local timeSpent = 0
    local tasksDone = 0

    local calcTime = calcTime or math.huge
    local tasksAllowed = maxTasks or math.huge

    while #tasks > 0 and tasksDone < tasksAllowed do
        local task = tasks[1]

        while coroutine.status(task.coroutine) ~= "dead" do
            if timeSpent >= calcTime then
                return false, timeSpent, tasksDone
            end

            local start = love.timer.getTime()
            local success, res = coroutine.resume(task.coroutine)

            if not success then
                print("! Task Failed:", res)
            end

            if success and res then
                task.result = res
            end

            local stop = love.timer.getTime()
            local deltaTime = stop - start
            timeSpent += deltaTime
            task.timeTotal += deltaTime
        end

        task:callback()
        table.remove(tasks, 1)
        tasksDone += 1
    end

    return #tasks == 0, timeSpent, tasksDone
end

-- TODO - Unwrap lambda properly
function tasks.newTask(func, callback, tasks)
    local tasks = tasks or globalTasks
    local task = {
        coroutine = coroutine.create(function() func() end),
        callback = callback or function() end,
        timeTotal = 0
    }
    
    table.insert(tasks, task)

    return task
end

return tasks