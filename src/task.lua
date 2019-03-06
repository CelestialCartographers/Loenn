local globalTasks = {}

-- Processes tasks from table for at around calcTime (default until done) and atmost maxTasks (default all)
-- Returns processingStatus, timeSpent
local function processTasks(calcTime, maxTasks, customTasks)
    local timeSpent = 0
    local calcTime = calcTime or math.huge
    local tasksAllowed = maxTasks or math.huge
    local tasks = customTasks or globalTasks

    while #tasks > 0 and tasksAllowed > 0 do
        local task = tasks[1]

        while coroutine.status(task.coroutine) ~= "dead" do
            if timeSpent >= calcTime then
                return false, timeSpent
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

        task.callback()
        table.remove(tasks, 1)
        tasksAllowed -= 1
    end

    return #tasks == 0, timeSpent
end

local function newTask(func, callback, tasks)
    local tasks = tasks or globalTasks
    local task = {
        coroutine = coroutine.create(func),
        callback = callback or function() end,
        timeTotal = 0
    }
    
    table.insert(tasks, task)

    return task
end

return {
    processTasks = processTasks,
    newTask = newTask
}