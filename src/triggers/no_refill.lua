local noRefill = {}

noRefill.name = "noRefillTrigger"
noRefill.placements = {
    {
        name = "No Refill (Disabled)",
        data = {
            state = true
        }
    },
    {
        name = "No Refill (Enabled)",
        data = {
            state = false
        }
    }
}

return noRefill