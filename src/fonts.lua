local configs = require("configs")
local HI_RES_FONT = configs.editor.fontType ~= "pico8"

local font = {}


if (HI_RES_FONT) then
    font.fontString = [=[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`'*#=[]"_{}<>^~ ]=]
    font.font = love.graphics.newImageFont("fonts/hi-res_pixel_font.png", font.fontString, 1)
    -- 以 pico8 的 scale 为 基准
    font.fontScale = 0.5
else
    font.fontString = [=[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"'`-_/1234567890!?[](){}.,;:<>+=%#^*~ ]=]
    font.font = love.graphics.newImageFont("fonts/pico8_font.png", font.fontString, 1)
    font.fontScale = 1
end
font.font:setLineHeight(1.25)

return font
