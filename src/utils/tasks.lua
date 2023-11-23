local utils = require("utils")
local logging = require("logging")

local taskUtils = {}

local globalTasks = {}
local waitingForTask = {}
local waitingForResume = {}

local function emptyCallback()

end

-- Update variables to see if this lets any tasks run
local function updateWaitingForTaskDone(task)
    if waitingForTask[task] then
        for waiting, value in pairs(waitingForTask[task]) do
            waitingForResume[waiting] -= 1

            if waitingForResume[waiting] == 0 then
                waitingForResume[waiting] = nil
            end
        end

        waitingForTask[task] = nil
    end
end

-- Wait for the given task (or list of tasks) to finish before resuming
local function addWaitingFor(task, waitingFor)
    local typ = utils.typeof(waitingFor)

    if typ == "task" then
        if waitingFor and waitingForTask[waitingFor] and not waitingForTask[waitingFor][task] and not waitingFor.done then
            waitingForTask[waitingFor][task] = true
            waitingForResume[task] = (waitingForResume[task] or 0) + 1
        end

    elseif #waitingFor > 0 then
        for i, waiting in ipairs(waitingFor) do
            addWaitingFor(task, waiting)
        end
    end
end

function taskUtils.waitFor(task)
    coroutine.yield("waitFor", task)
end

-- Added for consistency sake
taskUtils.yield = coroutine.yield

-- Update the value in the task result
function taskUtils.update(...)
    coroutine.yield("update", ...)
end

function taskUtils.delayProcessing()
    coroutine.yield("delayProcessing")
end

-- Returns completion status, if the process needs to wait for a different process, and the time it spent processing
function taskUtils.processTask(task, time)
    local timeSpent = 0
    local calcTime = time or math.huge

    while coroutine.status(task.coroutine) ~= "dead" do
        local waiting = waitingForResume[task] and waitingForResume[task] > 0

        -- Can't process if we are over the time limit, or waiting for another task
        if timeSpent >= calcTime or waiting then
            task.processedCount += 1

            if waiting then
                task.processedWaitingCount += 1
            end

            return false, waiting, timeSpent
        end

        local start = love.timer.getTime()
        local success, status, res = coroutine.resume(task.coroutine, task)

        if success then
            if status == "waitFor" then
                task.processedYieldCount += 1
                task.processedWaitingCount += 1

                addWaitingFor(task, res)

            elseif status == "update" then
                task.result = res

            elseif status == "delayProcessing" then
                task.processedWaitingCount += 1

                return false, true, timeSpent
            end

        else
            logging.warning(string.format("Task Failed: %s", status))
            logging.warning(debug.traceback(task.coroutine))

            task.timeFinished = love.timer.getTime()
            task.timeTotal = task.timeFinished - task.timeStart
            task.done = true
            task.success = false
        end

        local stop = love.timer.getTime()
        local deltaTime = stop - start

        timeSpent += deltaTime
        task.timeProcessed += deltaTime
        task.processedYieldCount += 1
    end

    if not task.done then
        task.timeFinished = love.timer.getTime()
        task.timeTotal = task.timeFinished - task.timeStart
        task.done = true
        task.success = true
    end

    task.processedCount += 1

    task:callback()

    return true, false, timeSpent
end

-- Processes tasks from table for at around calcTime (default until done) and atmost maxTasks (default all)
-- Returns processingStatus, timeSpent, tasksCompleted
function taskUtils.processTasks(time, maxTasks, customTasks)
    local tasks = customTasks or globalTasks

    local timeSpent = 0
    local tasksDone = 0

    local calcTime = time or math.huge
    local tasksAllowed = maxTasks or math.huge

    local taskIndex = 1

    while #tasks > 0 and tasksDone < tasksAllowed and timeSpent < calcTime do
        local task = tasks[taskIndex]
        local finished, delayProcessing, taskTime = taskUtils.processTask(task, calcTime - timeSpent)

        timeSpent += taskTime

        if delayProcessing then
            local lastIndex = taskIndex
            taskIndex = utils.mod1(taskIndex + 1, #tasks)

            -- If this doesn't update the index then we should exit out, there are no tasks ready to run
            if lastIndex == taskIndex then
                break
            end
        end

        if finished then
            table.remove(tasks, taskIndex)
            updateWaitingForTaskDone(task)

            tasksDone += 1

            taskIndex = utils.mod1(taskIndex, #tasks)
        end
    end

    return #tasks == 0, timeSpent, tasksDone
end

local taskMt = {}

taskMt.__index = {}

function taskMt.__index:update(value)
    taskUtils.update(value)
end

function taskMt.__index:waitFor(waitingFor)
    taskUtils.waitFor(waitingFor)
end

function taskMt.__index:yield()
    taskUtils.yield()
end

function taskMt.__index:delayProcessing()
    taskUtils.delayProcessing()
end

taskMt.__index.process = taskUtils.processTask

-- TODO - Make arguments more sane?
function taskUtils.newTask(func, callback, tasks, data)
    tasks = tasks or globalTasks

    local task = setmetatable({}, taskMt)

    task._type = "task"
    task.coroutine = coroutine.create(function(task) func(task) end)
    task.callback = callback or emptyCallback
    task.timeStart = love.timer.getTime()
    task.timeFinished = nil
    task.timeTotal = 0
    task.timeProcessed = 0
    task.processedCount = 0
    task.processedYieldCount = 0
    task.processedWaitingCount = 0
    task.done = false
    task.success = false
    task.data = data or {}
    task.tasks = tasks

    table.insert(tasks, task)
    waitingForTask[task] = {}

    return task
end

return taskUtils
