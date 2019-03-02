local function loadImageAbsPath(path)
    local file = io.open(path, "rb")
    local data = love.filesystem.newFileData(file:read("*a"), "image.png")
    file:close()

    return love.graphics.newImage(data)
end

local function twosCompliment(n, power)
    if n >= 2^(power - 1) then
        return n - 2^power

    else
        return n
    end
end

local function stripByteOrderMark(s)
    if s:byte(1) == 0xEF and s:byte(2) == 0xBB and s:byte(3) == 0xBF then
        return s:sub(4, #s)
    end

    return s
end

return {
    loadImageAbsPath = loadImageAbsPath,
    twosCompliment = twosCompliment,
    stripByteOrderMark = stripByteOrderMark
}