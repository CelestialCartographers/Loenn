-- TODO - Swaping timeline direction "lags" behind

local timeline = {}

timeline._MT = {}
timeline._MT.__index = {}

function timeline._MT.__index:forward()
    if self.skip then
        self.skip = false

        self.index += 1
    end

    if self.index <= #self.snapshots then
        local snapshot = self.snapshots[self.index]

        if snapshot then
            snapshot.forward(snapshot.data)

            self.index = math.min(self.index + 1, #self.snapshots)

            return true
        end
    end

    return false
end

function timeline._MT.__index:backward()
    if self.index >= 1 then
        local snapshot = self.snapshots[self.index]

        if snapshot then
            snapshot.backward(snapshot.data)

            self.skip = true
            self.index -= 1

            return true
        end
    end

    return false
end

function timeline._MT.__index:addSnapshot(snapshot)
    if self.index < #self.snapshots then
        for i = self.index + 1, #self.snapshots do
            self.snapshots[i] = nil
        end
    end

    self.index += 1

    table.insert(self.snapshots, snapshot)

    return true
end

function timeline.create()
    local res = {
        _type = "timeline"
    }

    res.snapshots = {}
    res.index = 0
    res.skip = false

    return setmetatable(res, timeline._MT)
end

return timeline