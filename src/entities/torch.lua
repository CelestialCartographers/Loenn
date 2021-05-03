local torch = {}

torch.name = "torch"
torch.depth = 2000
torch.placements = {
    name = "torch",
    data = {
        startLit = false
    }
}

function torch.texture(room, entity)
    return entity.startLit and "objects/temple/litTorch03" or "objects/temple/torch00"
end

return torch