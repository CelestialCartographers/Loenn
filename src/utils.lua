function loadImageAbsPath(path)
    local file = io.open(path, "rb")
    local data = love.filesystem.newFileData(file:read("*a"), "image.png")
    file:close()

    return love.graphics.newImage(data)
end

return {
    loadImageAbsPath = loadImageAbsPath
}