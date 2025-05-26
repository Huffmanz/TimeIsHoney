local Transition = require("transition")

local GameOver = {
    currentState = "idle", -- idle, showing
    winner = nil
}

function GameOver.show(winner)
    GameOver.winner = winner
    GameOver.currentState = "showing"
    -- Start transition from game to game over
    Transition.start(0.5, function()
        -- Transition complete
    end)
end

function GameOver.draw()
    if GameOver.currentState == "showing" then
        -- Draw semi-transparent black background
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        -- Draw winner text
        love.graphics.setColor(1, 1, 1)
        local text = "You Win!"
        if GameOver.winner ~= "player" then
            text = "Enemy " .. GameOver.winner:sub(6) .. " Wins!"
        end
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(text)
        local textHeight = font:getHeight()
        
        love.graphics.print(text, 
            love.graphics.getWidth()/2 - textWidth/2,
            love.graphics.getHeight()/2 - textHeight/2)
        
        love.graphics.print("Click to play again",
            love.graphics.getWidth()/2 - font:getWidth("Click to play again")/2,
            love.graphics.getHeight()/2 + textHeight)
    end
    
    -- Draw transition overlay
    Transition.draw()
end

function GameOver.update(dt)
    return Transition.update(dt)
end

function GameOver.handleClick(x, y, button)
    if button == 1 and GameOver.currentState == "showing" then
        -- Start transition back to game
        Transition.start(0.5, function()
            GameOver.currentState = "idle"
            return true -- Signal that game should restart
        end)
    end
    return false
end

function GameOver.isShowing()
    return GameOver.currentState == "showing"
end

return GameOver 