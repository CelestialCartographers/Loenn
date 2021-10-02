local tasks = require("utils.tasks")
local utils = require("utils")
local mapStruct = require("structs.map")

local sideStruct = {}

local decoderBlacklist = {
    Filler = true,
    Style = true,
    levels = true
}

local encoderBlacklist = {
    map = true,
    _type = true
}

local function tableify(data, t)
    t = t or {}

    local name = data.__name
    local children = data.__children or {}

    t[name] = {}

    for k, v in pairs(data) do
        if k:sub(1, 1) ~= "_" then
            t[name][k] = v
        end
    end

    for i, child in ipairs(children) do
        tableify(child, t[name])
    end

    return t
end

local function binfileify(name, data)
    local res = {
        __name = name,
        __children = {}
    }

    for k, v in pairs(data) do
        if type(v) == "table" then
            table.insert(res.__children, binfileify(k, v))

        else
            res[k] = v
        end
    end

    if #res.__children == 0 then
        res.__children = nil
    end

    return res
end

function sideStruct.decode(data)
    local side = {
        _type = "side"
    }

    for i, v in ipairs(data.__children or {}) do
        local name = v.__name

        if not decoderBlacklist[name] then
            tableify(v, side)
        end
    end

    side.map = mapStruct.decode(data)

    tasks.update(side)

    return side
end

function sideStruct.decodeTaskable(data, tasksTarget)
    local sideTask = tasks.newTask(
        function(task)
            local side = {}
            local mapTask = tasks.newTask(-> mapStruct.decode(data), nil, tasksTarget)

            task:waitFor(mapTask)
            side.map = mapTask.result

            for i, v in ipairs(data.__children or {}) do
                local name = v.__name

                if not decoderBlacklist[name] then
                    tableify(v, side)
                end
            end

            tasks.update(side)
        end,
        nil,
        tasksTarget
    )

    tasks.waitFor(sideTask)
    tasks.update(sideTask.result)
end

function sideStruct.encode(side)
    local res = mapStruct.encode(side.map)

    for k, v in pairs(side) do
        if not encoderBlacklist[k] then
            table.insert(res.__children, binfileify(k, v))
        end
    end

    return res
end

function sideStruct.encodeTaskable(side, tasksTarget)
    local sideTask = tasks.newTask(
        function(task)
            local mapTask = tasks.newTask(-> mapStruct.encode(side.map), nil, tasksTarget)

            tasks.waitFor(mapTask)
            local res = mapTask.result

            for k, v in pairs(side) do
                if not encoderBlacklist[k] then
                    table.insert(res.__children, binfileify(k, v))
                end
            end

            tasks.update(res)
        end,
        nil,
        tasksTarget
    )

    tasks.waitFor(sideTask)
    tasks.update(sideTask.result)
end

return sideStruct