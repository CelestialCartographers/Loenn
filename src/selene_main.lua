-- love.load() is not called again, put stuff here.

local utils = require("utils")

local mapcoder = require("mapcoder")

love.window.setTitle("Lönn Demo")

-- Only works on Windows before graphics dumping is added
local gameplayAtlas = utils.loadImageAbsPath(os.getenv("LOCALAPPDATA") .. "/Ahorn/Sprites/Gameplay.png")
local spinnerQuad = love.graphics.newQuad(237, 1138, 19, 19, gameplayAtlas:getDimensions())

mapcoder.decodeFile("E:/Games/Celeste/Content/Maps/0-Intro.bin")

function love.draw()
    love.graphics.print("FPS " .. tostring(love.timer.getFPS()), 20, 40)

    for i = 1, 25 do
        for j = 1, 25 do
            love.graphics.draw(gameplayAtlas, spinnerQuad, 20 + i * 16, 80 + j * 16)
        end
    end
end