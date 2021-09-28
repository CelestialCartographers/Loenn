-- Not placeable, too hardcoded for general use

local summitGemManager = {}

summitGemManager.name = "summitGemManager"
summitGemManager.depth = 0
summitGemManager.texture = "@Internal@/summit_gem_manager"
summitGemManager.nodeVisibility = "always"
summitGemManager.nodeDepth = -10010

function summitGemManager.nodeTexture(room, entity, node, index)
    return string.format("collectables/summitgems/%s/gem00", index - 1)
end

return summitGemManager