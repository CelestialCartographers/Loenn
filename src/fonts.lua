local fontString = [=[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"'`-_/1234567890!?[](){}.,;:<>+=%#^*~ ]=]
local font = love.graphics.newImageFont("fonts/pico8_font.png", fontString, 1)
local fontScale = 4

return {
    fontString = fontString,
    font = font,
    fontScale = fontScale
}