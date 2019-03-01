-- love.load() is not called again, put stuff here.

local utils = require("utils")
local serialization = require("serialization")

local mapcoder = require("mapcoder")
local spriteMeta = require("sprite_meta")
local drawing = require("drawing")

love.window.setTitle("Lönn Demo")

-- Edit manually for now
local gameplayMeta = "/home/gt/.config/Ahorn/Sprites/Gameplay.meta"
local gameplayPng = "/home/gt/.config/Ahorn/Sprites/Gameplay.png"
local mapFile = "/home/gt/Celeste/Celeste/Content/Maps/0-Intro.bin"

mapcoder.decodeFile(mapFile)
gameplayAtlas = spriteMeta.loadSprites(gameplayMeta, gameplayPng)

spinner = gameplayAtlas["danger/crystal/fg_red00"]
    
sprites = $()

for i = 0, 24 do
    for j = 0, 24 do
        sprites += {
            x = 16 * i,
            y = 16 * j,

            meta = spinner
        }
    end
end

batch = drawing.createSpriteBatch(sprites)

function love.draw()
    love.graphics.print("FPS " .. tostring(love.timer.getFPS()), 20, 40)

    love.graphics.draw(batch, 50, 50)
end