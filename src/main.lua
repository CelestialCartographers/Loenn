function love.load()
    require("selene_main")
end

-- Globals for main loop
DRAW_INTERVAL = false
UPDATE_INTERVAL = false
MAIN_LOOP_SLEEP = 0.001

function love.run()
    if love.load then
        love.load(love.arg.parseGameArguments(arg), arg)
    end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then
        love.timer.step()
    end

    local dt = 0

    local drawAcc = 0
    local updateAcc = 0

    return function()
        if love.event then
            love.event.pump()

            for name, a, b, c, d, e, f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end

                love.handlers[name](a, b, c, d, e, f)
            end
        end

        if love.timer then
            dt = love.timer.step()

            if DRAW_INTERVAL then
                drawAcc = drawAcc + dt
            end

            if UPDATE_INTERVAL then
                updateAcc = updateAcc + dt
            end
        end

        if love.update then
            if UPDATE_INTERVAL then
                while updateAcc >= UPDATE_INTERVAL do
                    love.update(UPDATE_INTERVAL)

                    updateAcc = updateAcc - UPDATE_INTERVAL
                end

            else
                love.update(dt)
            end
        end

        if love.graphics and love.graphics.isActive() then
            if DRAW_INTERVAL then
                if drawAcc >= DRAW_INTERVAL then
                    love.graphics.origin()
                    love.graphics.clear(love.graphics.getBackgroundColor())

                    if love.draw then
                        love.draw()
                    end

                    love.graphics.present()

                    drawAcc = drawAcc - DRAW_INTERVAL
                end

            else
                love.graphics.origin()
                love.graphics.clear(love.graphics.getBackgroundColor())

                if love.draw then
                    love.draw()
                end

                love.graphics.present()
            end
        end

        if MAIN_LOOP_SLEEP and love.timer then
            love.timer.sleep(MAIN_LOOP_SLEEP)
        end
    end
end
