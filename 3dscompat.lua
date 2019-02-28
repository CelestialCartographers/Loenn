local OS = love.system.getOS()

local _love = {
    graphics = {},
    window = {}
}

_love.graphics.getDimensions = love.graphics.getDimensions
_love.window.setTitle = love.window.setTitle
_love.graphics.setScreen = love.graphics.setScreen

function love.graphics.getDimensions(screen)
    if OS == "3ds" then
        if screen == "bottom" then
            return 320, 240
        else
            return 400, 240
        end

    else
        return _love.graphics.getDimensions()
    end
end

function love.window.setTitle(s)
    if OS ~= "3ds" then
        return _love.window.setTitle(s)
    end

    return true
end

function love.graphics.setScreen(s)
    if OS == "3ds" then
        return _love.graphics.setScreen(s)
    end

    return true
end