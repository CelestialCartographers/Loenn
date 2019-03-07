local font = {}

font.fontString = [=[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"'`-_/1234567890!?[](){}.,;:<>+=%#^*~ ]=]
font.font = love.graphics.newImageFont("fonts/pico8_font.png", font.fontString, 1)
font.fontScale = 4

-- TODO - Figure out font spacing
-- Just add row in font image?

return font