local Transition = require("transition")
local Bee = require("bee")

local Menu = {
    currentState = "menu", -- menu, playing
    assets = {
        titleFont = nil,
        subtitleFont = nil,
        buttonFont = nil
    },
    bees = {},
    titleOffset = 0,
    titleDirection = 1,
    selectedButton = nil,
    buttonHoverTime = 0,
    totalTime = 0,  -- Add total time tracking
    isHovering = false  -- Store hover state
}

function Menu.load()
    -- Load fonts
    Menu.assets.titleFont = love.graphics.newFont("assets/KenneyPixel.ttf", 72)
    Menu.assets.subtitleFont = love.graphics.newFont("assets/KenneyPixel.ttf", 48)
    Menu.assets.buttonFont = love.graphics.newFont("assets/KenneyPixel.ttf", 32)
    
    -- Initialize menu bees
    for i = 1, 20 do
        local startX = love.math.random(0, love.graphics.getWidth())
        local startY = love.math.random(0, love.graphics.getHeight())
        local targetX = love.math.random(0, love.graphics.getWidth())
        local targetY = love.math.random(0, love.graphics.getHeight())
        
        local bee = Bee.new(startX, startY, targetX, targetY, 1, {nodes = {}})
        if bee then
            table.insert(Menu.bees, bee)
        end
    end
end

function Menu.draw()
    -- Draw background bees
    for _, bee in ipairs(Menu.bees) do
        bee:draw()
    end
    
    -- Draw title with animation
    love.graphics.setFont(Menu.assets.titleFont)
    local titleText = "Time is Honey"
    local titleWidth = Menu.assets.titleFont:getWidth(titleText)
    local titleHeight = Menu.assets.titleFont:getHeight()
    
    -- Draw title shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.print(titleText, love.graphics.getWidth()/2 - titleWidth/2 + 4, love.graphics.getHeight()/3 - titleHeight/2 + Menu.titleOffset + 4)
    
    -- Draw title with honey color
    love.graphics.setColor(1, 0.8, 0.2) -- Honey gold color
    love.graphics.setFont(Menu.assets.titleFont)
    love.graphics.printf(titleText, love.graphics.getWidth()/2 - titleWidth/2, love.graphics.getHeight()/3 - titleHeight/2 + Menu.titleOffset, titleWidth, "center")
    
    -- Draw start button with hover effect
    local buttonText = "Start Game"
    local buttonWidth = 200
    local buttonHeight = 60
    local buttonX = love.graphics.getWidth()/2 - buttonWidth/2
    local buttonY = love.graphics.getHeight()/2 + 50
    
    -- Draw button background with hover effect
    local hoverScale = 1 + math.sin(Menu.buttonHoverTime * 5) * 0.05
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 
        buttonX - (buttonWidth * (hoverScale - 1))/2,
        buttonY - (buttonHeight * (hoverScale - 1))/2,
        buttonWidth * hoverScale,
        buttonHeight * hoverScale,
        10, 10
    )
    
    -- Draw button text
    love.graphics.setFont(Menu.assets.buttonFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(buttonText, buttonX, buttonY + buttonHeight/2 - Menu.assets.buttonFont:getHeight()/2, buttonWidth, "center")
    
    -- Draw transition overlay
    Transition.draw()
end

function Menu.update(dt)
    -- Update total time
    Menu.totalTime = Menu.totalTime + dt
    
    -- Update button hover state
    local buttonWidth = 200
    local buttonHeight = 60
    local buttonX = love.graphics.getWidth()/2 - buttonWidth/2
    local buttonY = love.graphics.getHeight()/2 + 50
    
    -- Check if mouse is over button
    local mouseX, mouseY = love.mouse.getPosition()
    Menu.isHovering = mouseX >= buttonX and mouseX <= buttonX + buttonWidth and
                      mouseY >= buttonY and mouseY <= buttonY + buttonHeight
    
    if Menu.isHovering then
        Menu.selectedButton = "start"
        Menu.buttonHoverTime = Menu.buttonHoverTime + dt
    else
        Menu.selectedButton = nil
        Menu.buttonHoverTime = 0
    end
    
    -- Update bees
    for i = #Menu.bees, 1, -1 do
        local bee = Menu.bees[i]
        if bee:update(dt) then
            -- If bee has arrived, create a new one
            table.remove(Menu.bees, i)
            local startX = love.math.random(0, love.graphics.getWidth())
            local startY = love.math.random(0, love.graphics.getHeight())
            local targetX = love.math.random(0, love.graphics.getWidth())
            local targetY = love.math.random(0, love.graphics.getHeight())
            local newBee = Bee.new(startX, startY, targetX, targetY, 1, {nodes = {}})
            if newBee then
                table.insert(Menu.bees, newBee)
            end
        end
    end
    
    -- Update title animation
    Menu.titleOffset = Menu.titleOffset + Menu.titleDirection * 30 * dt
    if math.abs(Menu.titleOffset) > 5 then
        Menu.titleDirection = -Menu.titleDirection
    end
    
    -- Update transition
    Transition.update(dt)
    
    return false
end

function Menu.handleClick(x, y, button)
    if button == 1 then -- Left click
        local buttonWidth = 200
        local buttonHeight = 60
        local buttonX = love.graphics.getWidth()/2 - buttonWidth/2
        local buttonY = love.graphics.getHeight()/2 + 50
        
        if x >= buttonX and x <= buttonX + buttonWidth and
           y >= buttonY and y <= buttonY + buttonHeight then
            Transition.start(0.5, function()
                Menu.currentState = "playing"
            end)
            return true
        end
    end
    return false
end

function Menu.getFont()
    return Menu.timerFont
end

return Menu 