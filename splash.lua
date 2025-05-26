local Transition = require("transition")

local Splash = {
    currentState = "showing", -- showing, done
    time = 0,
    duration = 2, -- Show splash for 2 seconds
    assets = {
        titleFont = nil,
        subtitleFont = nil
    }
}

function Splash.load()
    -- Load fonts
    Splash.assets.titleFont = love.graphics.newFont("assets/KenneyPixel.ttf", 48)
    Splash.assets.subtitleFont = love.graphics.newFont("assets/KenneyPixel.ttf", 72)
end

function Splash.draw()
    -- Draw title
    love.graphics.setFont(Splash.assets.titleFont)
    local titleText = "Made with"
    local titleWidth = Splash.assets.titleFont:getWidth(titleText)
    local titleHeight = Splash.assets.titleFont:getHeight()
    
    -- Draw title shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.print(titleText, love.graphics.getWidth()/2 - titleWidth/2 + 4, love.graphics.getHeight()/3 - titleHeight/2 + 4)
    
    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(titleText, love.graphics.getWidth()/2 - titleWidth/2, love.graphics.getHeight()/3 - titleHeight/2)
    
    -- Draw LÖVE text
    love.graphics.setFont(Splash.assets.subtitleFont)
    local loveText = "LÖVE"
    local loveWidth = Splash.assets.subtitleFont:getWidth(loveText)
    local loveHeight = Splash.assets.subtitleFont:getHeight()
    
    -- Draw LÖVE shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.print(loveText, love.graphics.getWidth()/2 - loveWidth/2 + 3, love.graphics.getHeight()/2 - loveHeight/2 + 3)
    
    -- Draw LÖVE text
    love.graphics.setColor(1, 0.3, 0.3) -- Red color for LÖVE
    love.graphics.print(loveText, love.graphics.getWidth()/2 - loveWidth/2, love.graphics.getHeight()/2 - loveHeight/2)
    
    -- Draw transition overlay
    Transition.draw()
end

function Splash.update(dt)
    if Splash.currentState == "showing" then
        Splash.time = Splash.time + dt
        if Splash.time >= Splash.duration and not Transition.isTransitioning() then
            Transition.start(0.5, function()
                Splash.currentState = "done"
            end)
        end
    end
    
    -- Update transition
    Transition.update(dt)
    
    -- Return true when we're done
    if Splash.currentState == "done" then
        return true
    end
    return false
end

function Splash.isShowing()
    return Splash.currentState == "showing"
end

return Splash 