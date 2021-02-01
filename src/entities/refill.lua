local refill = {}

refill.depth = -100
refill.placements = {
    {
        name = "Refill",
        data = {
            twoDash = false
        }
    },
    {
        name = "Refill (Two Dashes)",
        data = {
            twoDash = true
        }
    }
}

function refill.texture(room, entity)
    return entity.twoDash and "objects/refillTwo/idle00" or "objects/refill/idle00"
end

return refill