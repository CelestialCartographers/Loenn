local configs = require("configs")
local event = require("event")

local font = {}

function font:useFont(fontName)
    local HI_RES_FONT = fontName ~= "pico8"

    if (HI_RES_FONT) then
        self.fontString =
        [=[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`'*#=[]"_{}<>^~ ]=]
        self.font = love.graphics.newImageFont("fonts/hi-res_pixel_font.png", self.fontString, 1)
        -- based on fontScale of pico8 font
        self.fontScale = 0.5
    else
        self.fontString =
        [=[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"'`-_/1234567890!?[](){}.,;:<>+=%#^*~ ]=]
        self.font = love.graphics.newImageFont("fonts/pico8_font.png", self.fontString, 1)
        self.fontScale = 1
    end
    font.font:setLineHeight(1.25)
    if (self.font ~= love.graphics.getFont()) then
        love.graphics.setFont(self.font)
        font.onChanged:invoke()
    end
end

font.onChanged = event.new()

font:useFont(configs.editor.fontType)

return font
