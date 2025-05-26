local Transition = require("transition")

local Menu = {
    currentState = "menu", -- menu, playing
    assets = {
        titleFont = nil,
        buttonFont = nil
    }
}

function Menu.load()
    -- Load fonts
    Menu.assets.titleFont = love.graphics.newFont("assets/KenneyPixel.ttf", 64)
    Menu.assets.buttonFont = love.graphics.newFont("assets/KenneyPixel.ttf", 32)
end

function Menu.draw()
    if Menu.currentState == "menu" or Transition.isTransitioning() then
        -- Draw title
        love.graphics.setFont(Menu.assets.titleFont)
        local titleText = "Time is Honey"
        local titleWidth = Menu.assets.titleFont:getWidth(titleText)
        local titleHeight = Menu.assets.titleFont:getHeight()
        
        -- Draw title shadow
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.print(titleText, love.graphics.getWidth()/2 - titleWidth/2 + 4, love.graphics.getHeight()/3 - titleHeight/2 + 4)
        
        -- Draw title
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(titleText, love.graphics.getWidth()/2 - titleWidth/2, love.graphics.getHeight()/3 - titleHeight/2)
        
        -- Draw click to start
        love.graphics.setFont(Menu.assets.buttonFont)
        local startText = "Click to Start"
        local startWidth = Menu.assets.buttonFont:getWidth(startText)
        local startHeight = Menu.assets.buttonFont:getHeight()
        
        -- Draw start text shadow
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.print(startText, love.graphics.getWidth()/2 - startWidth/2 + 2, love.graphics.getHeight()*2/3 - startHeight/2 + 2)
        
        -- Draw start text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(startText, love.graphics.getWidth()/2 - startWidth/2, love.graphics.getHeight()*2/3 - startHeight/2)
    end
    
    -- Draw transition overlay
    Transition.draw()
end

function Menu.update(dt)
    if Transition.update(dt) then
        Menu.currentState = "playing"
        return true -- Signal that transition is complete
    end
    return false
end

function Menu.handleClick(x, y, button)
    if button == 1 then -- Left click
        if Menu.currentState == "menu" then
            Transition.start(0.5, function()
                Menu.currentState = "playing"
            end)
            return true -- Signal that game should start
        end
    end
    return false
end

function Menu.getFont()
    return Menu.timerFont
end

return Menu 