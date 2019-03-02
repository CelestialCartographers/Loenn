-- love.load() is not called again, put stuff here.

local utils = require("utils")
local serialization = require("serialization")

local mapcoder = require("mapcoder")
local spriteMeta = require("sprite_meta")
local drawing = require("drawing")
local autotiler = require("autotiler")

love.window.setTitle("Lönn Demo")

-- Edit manually for now
local gameplayMeta = "C:/Users/GT/AppData/Local/Ahorn/Sprites/Gameplay.meta"
local gameplayPng = "C:/Users/GT/AppData/Local/Ahorn/Sprites/Gameplay.png"
local mapFile = "E:/Games/Celeste/Content/Maps/0-Intro.bin"
local tilesetFileFg = "C:/Users/GT/AppData/Local/Ahorn/XML/ForegroundTiles.xml"
local tilesetFileBg = "C:/Users/GT/AppData/Local/Ahorn/XML/BackgroundTiles.xml"

fgTilesMeta = autotiler.loadTilesetXML(tilesetFileFg)

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