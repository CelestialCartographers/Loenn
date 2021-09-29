local font = {}

font.fontString = [=[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"'`-_/1234567890!?[](){}.,;:<>+=%#^*~ ]=]
font.font = love.graphics.newImageFont("fonts/pico8_font.png", font.fontString, 1)
font.fontScale = 4
font.font:setLineHeight(1.25)

return font