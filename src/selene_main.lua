-- love.load() is not called again, put stuff here.

local utils = require("utils")
local serialization = require("serialization")

local mapcoder = require("mapcoder")
local spriteMeta = require("sprite_meta")
local drawing = require("drawing")

love.window.setTitle("Lönn Demo")

local gameplayMeta = "/home/gt/.config/Ahorn/Sprites/Gameplay.meta"
local gameplayPng = "/home/gt/.config/Ahorn/Sprites/Gameplay.png"

-- Only works on Windows before graphics dumping is added
--local gameplayAtlas = utils.loadImageAbsPath(os.getenv("LOCALAPPDATA") .. "/Ahorn/Sprites/Gameplay.png")

--mapcoder.decodeFile("E:/Games/Celeste/Content/Maps/0-Intro.bin")
mapcoder.decodeFile("/home/gt/Celeste/Celeste/Content/Maps/0-Intro.bin")
gameplayAtlas = spriteMeta.loadSprites(gameplayMeta, gameplayPng)

spinner = gameplayAtlas["danger/crystal/fg_red00"]

function love.draw()
    love.graphics.print("FPS " .. tostring(love.timer.getFPS()), 20, 40)

    for i = 1, 10 do
        for j = 1, 10 do
            drawing.drawSprite(spinner, 50 + 16 * i, 50 + 16 * j)
        end
    end
end