-- TODO - Swaping timeline direction "lags" behind

local timeline = {}

timeline._MT = {}
timeline._MT.__index = {}

function timeline._MT.__index:forward()
    if self.index == 0 and self.direction == "backward" then
        self.index = 1
    end

    if self.index <= #self.snapshots then
        local snapshot = self.snapshots[self.index]

        if snapshot then
            if self.direction == "forward" then
                self.index = self.index + 1
                snapshot = self.snapshots[self.index]

                if snapshot then
                    snapshot.forward(snapshot.data)
                end

            else
                snapshot.forward(snapshot.data)
            end

            self.direction = "forward"

            return true
        end
    end

    return false
end

function timeline._MT.__index:backward()
    if self.index == #self.snapshots + 1 and self.direction == "forward" then
        self.index = #self.snapshots
    end

    if self.index >= 1 then
        local snapshot = self.snapshots[self.index]

        if snapshot then
            if self.direction == "backward" then
                self.index -= 1
                snapshot = self.snapshots[self.index]

                if snapshot then
                    snapshot.backward(snapshot.data)
                end

            else
                snapshot.backward(snapshot.data)
            end

            self.direction = "backward"

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

    self.direction = "forward"
    self.index += 1

    table.insert(self.snapshots, snapshot)

    if self.limit and self.limit > 0 then
        while #self.snapshots > self.limit do
            table.remove(self.snapshots, 1)

            self.index -= 1
        end
    end

    return true
end

function timeline.create(snapshotLimit)
    local res = {
        _type = "timeline"
    }

    res.snapshots = {}
    res.index = 0
    res.direction = false
    res.limit = snapshotLimit

    return setmetatable(res, timeline._MT)
end

return timeline