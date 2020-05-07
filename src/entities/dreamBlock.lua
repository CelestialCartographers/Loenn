local drawing = require("drawing")
local utils = require("utils")

local dreamBlock = {}

dreamBlock.depth = -2000000
function dreamBlock.draw(room, entity)
    local pr, pg, pb, pa = love.graphics.getColor()

   
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", entity.x, entity.y, entity.width, entity.height )
    math.randomseed(entity.x + entity.y)
   
    love.graphics.setColor(0, 0, 0)
    
    love.graphics.rectangle("fill", entity.x+1, entity.y+1, entity.width-2, entity.height-2 )
 
    for i=1,10+((entity.width+1) * (entity.height+1))/(2000) do 
        
        love.graphics.setColor(math.random(0,255)/255,math.random(0,255)/255, math.random(0,255)/255)
        love.graphics.rectangle("fill", math.random(entity.x+1,entity.x+entity.width-2), math.random(entity.y+1,entity.y+entity.height-2), 1,1 )
        end
    love.graphics.setColor(pr, pg, pb, pa)
end

return dreamBlock