local key = {}

key.name = "key"
key.depth = -1000000
key.nodeLineRenderType = "line"
key.texture = "collectables/key/idle00"

-- Node with return just needs to have two nodes
-- Placements will update their position correctly
-- This is required since there is no one node key, only zero or two
key.placements = {
    {
        name = "normal"
    },
    {
        name = "with_return",
        data = {
            nodes = {
                {x = 0, y = 0},
                {x = 0, y = 0}
            }
        }
    }
}

function key.nodeLimits(room, entity)
    local nodes = entity.nodes or {}

    if #nodes > 0 then
        return 2, 2

    else
        return 0, 0
    end
end

return key