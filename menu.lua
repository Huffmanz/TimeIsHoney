local Transition = require("transition")

local Menu = {
    currentState = "menu", -- menu, playing
    menuIcon = nil,
    timerFont = nil
}

function Menu.load()
    -- Load assets
    Menu.menuIcon = love.graphics.newImage("assets/icon.png")
    Menu.timerFont = love.graphics.newFont(48)
end

function Menu.draw()
    if Menu.currentState == "menu" or Transition.isTransitioning() then
        -- Draw menu
        local iconWidth = Menu.menuIcon:getWidth()
        local iconHeight = Menu.menuIcon:getHeight()
        local scale = 0.25
        local scaledWidth = iconWidth * scale
        local scaledHeight = iconHeight * scale
        local centerX = love.graphics.getWidth() / 2 - scaledWidth / 2
        local centerY = love.graphics.getHeight() / 2 - scaledHeight / 2
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(Menu.menuIcon, centerX, 0, 0, scale, scale)
        
        love.graphics.setColor(0, 0, 0)
        love.graphics.print("Click to Start", 350, centerY + scaledHeight + 20)
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