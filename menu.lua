local Transition = require("transition")
local Bee = require("bee")
local SFX = require("sfx")

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
    buttonHoverTimes = {}, -- Track hover time per button
    buttonHoverStates = {}, -- Track if button has been hovered
    totalTime = 0,  -- Add total time tracking
    isHovering = false,  -- Store hover state
    honeyParticles = {}, -- Add honey particles
    glowIntensity = 0,  -- Add glow intensity
    glowDirection = 1,   -- Add glow direction
    wasHovering = false,  -- Track previous hover state
    buttons = {
        start = {
            text = "Start Game",
            y = 50,
            action = function()
                Transition.start(0.5, function()
                    Menu.currentState = "playing"
                end)
                return true
            end,
            colors = {
                normal = {0.2, 0.2, 0.2, 0.8},
                hover = {0.3, 0.3, 0.3, 0.9},
                text = {1, 1, 1},
                textHover = {1, 0.8, 0.2},
                glow = {1, 0.8, 0.2}
            }
        },
        quit = {
            text = "Quit",
            y = 130,
            action = function()
                love.event.quit()
                return false
            end,
            colors = {
                normal = {0.4, 0.1, 0.1, 0.8},
                hover = {0.6, 0.2, 0.2, 0.9},
                text = {1, 1, 1},
                textHover = {1, 0.3, 0.3},
                glow = {1, 0.3, 0.3}
            }
        }
    }
}

function Menu.load()
    -- Initialize hover states for all buttons
    for buttonId, _ in pairs(Menu.buttons) do
        Menu.buttonHoverTimes[buttonId] = 0
        Menu.buttonHoverStates[buttonId] = false
    end
    
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
    
    -- Initialize honey particles
    for i = 1, 50 do
        table.insert(Menu.honeyParticles, {
            x = love.math.random(0, love.graphics.getWidth()),
            y = love.math.random(0, love.graphics.getHeight()),
            size = love.math.random(4, 8),
            speed = love.math.random(20, 40),
            angle = love.math.random() * math.pi * 2,
            alpha = love.math.random(0.3, 0.7),
            rotation = love.math.random() * math.pi * 2,
            rotationSpeed = (love.math.random() - 0.5) * 2
        })
    end
end

function Menu.draw()
    -- Draw honey background
    love.graphics.setColor(0.95, 0.9, 0.7, 0.3)
    for _, particle in ipairs(Menu.honeyParticles) do
        love.graphics.push()
        love.graphics.translate(particle.x, particle.y)
        love.graphics.rotate(particle.rotation)
        love.graphics.setColor(1, 0.8, 0.2, particle.alpha)
        love.graphics.rectangle("fill", -particle.size/2, -particle.size/2, particle.size, particle.size)
        love.graphics.pop()
    end
    
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
    
    -- Draw buttons
    local buttonWidth = 200
    local buttonHeight = 60
    local centerX = love.graphics.getWidth()/2 - buttonWidth/2
    
    for buttonId, button in pairs(Menu.buttons) do
        local buttonY = love.graphics.getHeight()/2 + button.y
        local isHovering = Menu.selectedButton == buttonId
        local hoverTime = Menu.buttonHoverTimes[buttonId] or 0
        
        -- Draw button glow when hovering
        if isHovering then
            local glowAlpha = 0.3 + math.sin(hoverTime * 5) * 0.2
            love.graphics.setColor(button.colors.glow[1], button.colors.glow[2], button.colors.glow[3], glowAlpha)
            love.graphics.rectangle("fill", 
                centerX - 10,
                buttonY - 10,
                buttonWidth + 20,
                buttonHeight + 20,
                15, 15
            )
        end
        
        -- Calculate squash and stretch effect
        local scaleX, scaleY = 1, 1
        if isHovering and hoverTime < 0.3 then -- Only animate for first 0.3 seconds
            -- Create a bouncy squash and stretch effect
            local progress = hoverTime / 0.3 -- Normalize to 0-1
            local bounce = math.sin(progress * math.pi) * 0.1 -- One complete bounce
            scaleX = 1 + bounce
            scaleY = 1 - bounce * 0.5 -- Squash vertically while stretching horizontally
        end
        
        -- Draw button background with squash and stretch effect
        local buttonColor = isHovering and button.colors.hover or button.colors.normal
        love.graphics.setColor(buttonColor)
        
        -- Calculate new dimensions and position for squash and stretch
        local newWidth = buttonWidth * scaleX
        local newHeight = buttonHeight * scaleY
        local newX = centerX - (newWidth - buttonWidth) / 2
        local newY = buttonY - (newHeight - buttonHeight) / 2
        
        love.graphics.rectangle("fill", 
            newX,
            newY,
            newWidth,
            newHeight,
            10, 10
        )
        
        -- Draw button text with enhanced hover effect
        love.graphics.setFont(Menu.assets.buttonFont)
        local textColor = isHovering and button.colors.textHover or button.colors.text
        love.graphics.setColor(textColor)
        love.graphics.printf(button.text, newX, newY + newHeight/2 - Menu.assets.buttonFont:getHeight()/2, newWidth, "center")
    end
    
    -- Draw transition overlay
    Transition.draw()
end

function Menu.update(dt)
    -- Update total time
    Menu.totalTime = Menu.totalTime + dt
    
    -- Update title animation (slower movement)
    Menu.titleOffset = Menu.titleOffset + Menu.titleDirection * 10 * dt
    if math.abs(Menu.titleOffset) > 3 then
        Menu.titleDirection = -Menu.titleDirection
    end
    
    -- Update honey particles
    for _, particle in ipairs(Menu.honeyParticles) do
        particle.x = particle.x + math.cos(particle.angle) * particle.speed * dt
        particle.y = particle.y + math.sin(particle.angle) * particle.speed * dt
        particle.rotation = particle.rotation + particle.rotationSpeed * dt
        
        -- Wrap particles around screen
        if particle.x < -particle.size then particle.x = love.graphics.getWidth() + particle.size end
        if particle.x > love.graphics.getWidth() + particle.size then particle.x = -particle.size end
        if particle.y < -particle.size then particle.y = love.graphics.getHeight() + particle.size end
        if particle.y > love.graphics.getHeight() + particle.size then particle.y = -particle.size end
    end
    
    -- Update button hover states
    local buttonWidth = 200
    local buttonHeight = 60
    local centerX = love.graphics.getWidth()/2 - buttonWidth/2
    local mouseX, mouseY = love.mouse.getPosition()
    local wasHovering = Menu.selectedButton ~= nil
    Menu.selectedButton = nil
    
    -- Update hover times for all buttons
    for buttonId, button in pairs(Menu.buttons) do
        local buttonY = love.graphics.getHeight()/2 + button.y
        if mouseX >= centerX and mouseX <= centerX + buttonWidth and
           mouseY >= buttonY and mouseY <= buttonY + buttonHeight then
            Menu.selectedButton = buttonId
            if not Menu.buttonHoverStates[buttonId] then
                -- Reset hover time when first hovering
                Menu.buttonHoverTimes[buttonId] = 0
                Menu.buttonHoverStates[buttonId] = true
            end
            Menu.buttonHoverTimes[buttonId] = Menu.buttonHoverTimes[buttonId] + dt
        else
            Menu.buttonHoverStates[buttonId] = false
            Menu.buttonHoverTimes[buttonId] = 0
        end
    end
    
    -- Play hover sound when mouse enters any button
    if Menu.selectedButton and not wasHovering then
        SFX.play("uiHover")
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
    
    -- Update transition
    Transition.update(dt)
    
    return false
end

function Menu.handleClick(x, y, button)
    if button == 1 then -- Left click
        local buttonWidth = 200
        local buttonHeight = 60
        local centerX = love.graphics.getWidth()/2 - buttonWidth/2
        
        for buttonId, menuButton in pairs(Menu.buttons) do
            local buttonY = love.graphics.getHeight()/2 + menuButton.y
            if x >= centerX and x <= centerX + buttonWidth and
               y >= buttonY and y <= buttonY + buttonHeight then
                -- Play click sound
                SFX.play("uiClick")
                return menuButton.action()
            end
        end
    end
    return false
end

function Menu.getFont()
    return Menu.timerFont
end

return Menu 