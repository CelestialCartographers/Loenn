local globalTasks = {}

local tasksHandler = {}

function tasksHandler.processTask(task, time)
    local timeSpent = 0
    local calcTime = time or math.huge

    while coroutine.status(task.coroutine) ~= "dead" do
        if timeSpent >= calcTime then
            return false, timeSpent
        end

        local start = love.timer.getTime()
        local success, res = coroutine.resume(task.coroutine)

        if not success then
            print("! Task Failed:", res)

            task.done = true
            task.success = false
        end

        if success and res then
            task.result = res
        end

        local stop = love.timer.getTime()
        local deltaTime = stop - start
        timeSpent += deltaTime
        task.timeTotal += deltaTime
    end

    task.done = true
    task.success = true

    task:callback()

    return true, timeSpent
end

-- Processes tasks from table for at around calcTime (default until done) and atmost maxTasks (default all)
-- Returns processingStatus, timeSpent, tasksCompleted
function tasksHandler.processTasks(time, maxTasks, customTasks)
    local tasks = customTasks or globalTasks

    local timeSpent = 0
    local tasksDone = 0

    local calcTime = time or math.huge
    local tasksAllowed = maxTasks or math.huge

    while #tasks > 0 and tasksDone < tasksAllowed do
        local task = tasks[1]
        local finished, taskTime = tasksHandler.processTask(task, calcTime - timeSpent)

        if not finished then
            break
        end

        table.remove(tasks, 1)
        tasksDone += 1
        timeSpent += taskTime
    end

    return #tasks == 0, timeSpent, tasksDone
end

-- TODO - Unwrap lambda properly
-- TODO - Make arguments more sane?
function tasksHandler.newTask(func, callback, tasks, data)
    tasks = tasks or globalTasks

    local task = {
        coroutine = coroutine.create(function() func() end),
        callback = callback or function() end,
        timeTotal = 0,
        done = false,
        success = false,
        data = data or {}
    }

    table.insert(tasks, task)

    return task
end

return tasksHandler