function love.filedropped(file)
    local filename = file:getFilename()

    print("FILE", filename)
end

function love.directorydropped(path)
    print("PATH", path)
end