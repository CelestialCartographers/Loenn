local window = {}

window.x = 200
window.y = 200

window.width = 400
window.height = 300

function window:loaded()
    self.image = love.graphics.newImage("assets/logo-256.png")
end

function window:draw()
    love.graphics.draw(self.image, -20, -20)
    love.graphics.setColor(1.0, 0.7, 0.7)
    love.graphics.print("Hello, thing", 20, 256, 0, 4, 4)
end

function window:update(dt)
    --print(self.x, self.y, self.width, self.height, dt)
end

return window