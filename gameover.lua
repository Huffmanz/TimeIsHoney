local Transition = require("transition")

local GameOver = {
    currentState = "idle", -- idle, showing
    winner = nil,
    assets = {
        titleFont = nil,
        buttonFont = nil
    }
}

function GameOver.load()
    -- Load fonts
    GameOver.assets.titleFont = love.graphics.newFont("assets/KenneyPixel.ttf", 64)
    GameOver.assets.buttonFont = love.graphics.newFont("assets/KenneyPixel.ttf", 32)
end

function GameOver.show(winner)
    GameOver.currentState = "showing"
    GameOver.winner = winner
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
        
        -- Draw game over text
        love.graphics.setFont(GameOver.assets.titleFont)
        local gameOverText = "Game Over"
        local winnerText = GameOver.winner .. " Wins!"
        local gameOverWidth = GameOver.assets.titleFont:getWidth(gameOverText)
        local winnerWidth = GameOver.assets.titleFont:getWidth(winnerText)
        
        -- Draw text shadows
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.print(gameOverText, love.graphics.getWidth()/2 - gameOverWidth/2 + 4, love.graphics.getHeight()/3 - 50 + 4)
        love.graphics.print(winnerText, love.graphics.getWidth()/2 - winnerWidth/2 + 4, love.graphics.getHeight()/3 + 4)
        
        -- Draw main text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(gameOverText, love.graphics.getWidth()/2 - gameOverWidth/2, love.graphics.getHeight()/3 - 50)
        love.graphics.print(winnerText, love.graphics.getWidth()/2 - winnerWidth/2, love.graphics.getHeight()/3)
        
        -- Draw click to restart
        love.graphics.setFont(GameOver.assets.buttonFont)
        local restartText = "Click to Restart"
        local restartWidth = GameOver.assets.buttonFont:getWidth(restartText)
        
        -- Draw restart text shadow
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.print(restartText, love.graphics.getWidth()/2 - restartWidth/2 + 2, love.graphics.getHeight()*2/3 + 2)
        
        -- Draw restart text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(restartText, love.graphics.getWidth()/2 - restartWidth/2, love.graphics.getHeight()*2/3)
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