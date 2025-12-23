local event = {}
event.__index = event

function event.new()
    return setmetatable({ listeners = {} }, event)
end

function event:add(listener)
    table.insert(self.listeners, listener)
    return listener
end

function event:remove(listener)
    for i, l in ipairs(self.listeners) do
        if l == listener then
            table.remove(self.listeners, i)
            return true
        end
    end
    return false
end

function event:invoke(...)
    for _, l in ipairs(self.listeners) do
        l(...)
    end
end

return event
