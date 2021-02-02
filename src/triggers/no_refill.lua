local noRefill = {}

noRefill.name = "noRefillTrigger"
noRefill.placements = {
    {
        name = "disable_refills",
        data = {
            state = true
        }
    },
    {
        name = "enable_refills",
        data = {
            state = false
        }
    }
}

return noRefill