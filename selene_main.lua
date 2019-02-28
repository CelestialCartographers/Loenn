-- love.load() is not called again, put stuff here.

local logo = love.graphics.newImage("logo.png")

function love.draw()    
    love.graphics.setScreen("top")
    love.graphics.print($("Hello", "World!"):concat(" "), 20, 20)   
    love.graphics.setScreen("bottom")  
    love.graphics.draw(logo, 25, -30)
end