local Transition = require("transition")
local SFX = require("sfx")

local HowToPlay = {
    selectedButton = nil,
    buttonHoverTimes = {},
    buttonHoverStates = {},
    buttons = {
        backToMenu = {
            text = "Back to Menu",
            x = 20, -- Position from left edge
            y = 20, -- Position from bottom
            action = function()
                Transition.start(0.5, function()
                    return "menu"
                end)
                return false
            end,
            colors = {
                normal = {0.97, 0.73, 0.06, 0.8}, -- #F7B910 with alpha
                hover = {1, 0.8, 0.1, 0.9},      -- Slightly brighter
                text = {0.2, 0.2, 0.2},          -- Dark text
                textHover = {0.1, 0.1, 0.1},     -- Darker text on hover
                glow = {0.97, 0.73, 0.06}        -- Same as normal color
            }
        }
    }
}

function HowToPlay.load(assets)
    HowToPlay.assets = assets
    -- Initialize hover states
    for buttonId, _ in pairs(HowToPlay.buttons) do
        HowToPlay.buttonHoverTimes[buttonId] = 0
        HowToPlay.buttonHoverStates[buttonId] = false
    end
end

function HowToPlay.draw()
    if not HowToPlay.assets then
        return
    end
    
    -- Draw title
    love.graphics.setFont(HowToPlay.assets.titleFont)
    local titleText = "How to Play"
    local titleWidth = HowToPlay.assets.titleFont:getWidth(titleText)
    
    -- Draw title shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.print(titleText, love.graphics.getWidth()/2 - titleWidth/2 + 4, 100 + 4)
    
    -- Draw title with honey color
    love.graphics.setColor(1, 0.8, 0.2) -- Honey gold color
    love.graphics.printf(titleText, 0, 100, love.graphics.getWidth(), "center")
    
    -- Draw instructions
    love.graphics.setFont(HowToPlay.assets.buttonFont)
    local instructions = {
        "• Click on your nodes to select them",
        "• Click on an enemy node to capture it",
        "• Capture all nodes to win",
        "• Watch out for enemy hives!",
        "• They will try to capture your nodes",
        "• Use arrow keys to move the camera",
        "",
        "Tips:",
        "• Keep your nodes connected",
        "• Protect your hives",
        "• Plan your captures carefully"
    }
    
    love.graphics.setColor(1, 1, 1)
    for i, instruction in ipairs(instructions) do
        love.graphics.printf(instruction, 0, 200 + (i-1) * 40, love.graphics.getWidth(), "center")
    end
    
    -- Draw back button
    local buttonWidth = 200
    local buttonHeight = 60
    local button = HowToPlay.buttons.backToMenu
    local buttonX = button.x
    local buttonY = love.graphics.getHeight() - button.y - buttonHeight -- Position from bottom
    local isHovering = HowToPlay.selectedButton == "backToMenu"
    local hoverTime = HowToPlay.buttonHoverTimes["backToMenu"] or 0
    
    -- Draw button glow when hovering
    if isHovering then
        local glowAlpha = 0.3 + math.sin(hoverTime * 5) * 0.2
        love.graphics.setColor(button.colors.glow[1], button.colors.glow[2], button.colors.glow[3], glowAlpha)
        love.graphics.rectangle("fill", 
            buttonX - 10,
            buttonY - 10,
            buttonWidth + 20,
            buttonHeight + 20,
            15, 15
        )
    end
    
    -- Calculate squash and stretch effect
    local scaleX, scaleY = 1, 1
    if isHovering and hoverTime < 0.3 then
        local progress = hoverTime / 0.3
        local bounce = math.sin(progress * math.pi) * 0.1
        scaleX = 1 + bounce
        scaleY = 1 - bounce * 0.5
    end
    
    -- Draw button background
    local buttonColor = isHovering and button.colors.hover or button.colors.normal
    love.graphics.setColor(buttonColor)
    
    local newWidth = buttonWidth * scaleX
    local newHeight = buttonHeight * scaleY
    local newX = buttonX - (newWidth - buttonWidth) / 2
    local newY = buttonY - (newHeight - buttonHeight) / 2
    
    love.graphics.rectangle("fill", 
        newX,
        newY,
        newWidth,
        newHeight,
        10, 10
    )
    
    -- Draw button text
    love.graphics.setFont(HowToPlay.assets.buttonFont)
    local textColor = isHovering and button.colors.textHover or button.colors.text
    love.graphics.setColor(textColor)
    love.graphics.printf(button.text, newX, newY + newHeight/2 - HowToPlay.assets.buttonFont:getHeight()/2, newWidth, "center")
end

function HowToPlay.update(dt)
    -- Update button hover states
    local buttonWidth = 200
    local buttonHeight = 60
    local button = HowToPlay.buttons.backToMenu
    local buttonX = button.x
    local buttonY = love.graphics.getHeight() - button.y - buttonHeight -- Position from bottom
    local mouseX, mouseY = love.mouse.getPosition()
    local wasHovering = HowToPlay.selectedButton ~= nil
    HowToPlay.selectedButton = nil
    
    -- Update hover times for all buttons
    for buttonId, button in pairs(HowToPlay.buttons) do
        local buttonX = button.x
        local buttonY = love.graphics.getHeight() - button.y - buttonHeight
        if mouseX >= buttonX and mouseX <= buttonX + buttonWidth and
           mouseY >= buttonY and mouseY <= buttonY + buttonHeight then
            HowToPlay.selectedButton = buttonId
            if not HowToPlay.buttonHoverStates[buttonId] then
                HowToPlay.buttonHoverTimes[buttonId] = 0
                HowToPlay.buttonHoverStates[buttonId] = true
            end
            HowToPlay.buttonHoverTimes[buttonId] = HowToPlay.buttonHoverTimes[buttonId] + dt
        else
            HowToPlay.buttonHoverStates[buttonId] = false
            HowToPlay.buttonHoverTimes[buttonId] = 0
        end
    end
    
    -- Play hover sound when mouse enters any button
    if HowToPlay.selectedButton and not wasHovering then
        SFX.play("uiHover")
    end
    
    return false
end

function HowToPlay.handleClick(x, y, button)
    if button == 1 then -- Left click
        local buttonWidth = 200
        local buttonHeight = 60
        
        for buttonId, menuButton in pairs(HowToPlay.buttons) do
            local buttonX = menuButton.x
            local buttonY = love.graphics.getHeight() - menuButton.y - buttonHeight
            if x >= buttonX and x <= buttonX + buttonWidth and
               y >= buttonY and y <= buttonY + buttonHeight then
                -- Play click sound
                SFX.play("uiClick")
                return menuButton.action()
            end
        end
    end
    return false
end

return HowToPlay 