local oshiro = {}

oshiro.name = "oshiroTrigger"
oshiro.placements = {
    {
        name = "oshiro_spawn",
        data = {
            state = true
        }
    },
    {
        name = "oshiro_leave",
        data = {
            state = false
        }
    }
}

return oshiro