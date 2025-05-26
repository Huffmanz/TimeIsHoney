local Transition = require("transition")
local Music = require("music")

local Splash = {
    currentState = "showing", -- showing, done
    time = 0,
    duration = 2, -- Show splash for 2 seconds
    assets = {
        titleFont = nil,
        subtitleFont = nil,
        logo = nil
    },
    alpha = 0,
    fadeInTime = 1,
    fadeOutTime = 1,
    state = "fadeIn", -- fadeIn, hold, fadeOut
    animations = {
        title = {
            scale = 0,
            targetScale = 1,
            popScale = 1.2,
            duration = 0.5,
            time = 0
        },
        love = {
            scale = 0,
            targetScale = 1,
            popScale = 1.2,
            duration = 0.5,
            time = 0.2 -- Start after title
        }
    },
    logoScale = 0,
    logoStartTime = 0.7,
    logoDuration = 0.5,
    logoAnimated = false,
    logoBaseScale = 0.15
}

function Splash.load()
    -- Load fonts
    Splash.assets.titleFont = love.graphics.newFont("assets/KenneyPixel.ttf", 64)
    Splash.assets.subtitleFont = love.graphics.newFont("assets/KenneyPixel.ttf", 96)
    
    -- Load logo
    Splash.assets.logo = love.graphics.newImage("assets/love-logo.png")
    
    -- Start playing music
    Music.play()
end

function Splash.draw()
    -- Draw title
    love.graphics.setFont(Splash.assets.titleFont)
    local titleText = "Made with"
    local titleWidth = Splash.assets.titleFont:getWidth(titleText)
    local titleHeight = Splash.assets.titleFont:getHeight()
    
    -- Calculate title scale
    local titleScale = Splash.animations.title.scale
    
    -- Draw title shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/4)
    love.graphics.scale(titleScale, titleScale)
    love.graphics.print(titleText, -titleWidth/2 + 4, -titleHeight/2 + 4)
    love.graphics.pop()
    
    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/4)
    love.graphics.scale(titleScale, titleScale)
    love.graphics.print(titleText, -titleWidth/2, -titleHeight/2)
    love.graphics.pop()
    
    -- Draw logo with animation
    local logoWidth = Splash.assets.logo:getWidth()
    local logoHeight = Splash.assets.logo:getHeight()
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    love.graphics.scale(Splash.logoScale, Splash.logoScale)
    love.graphics.draw(Splash.assets.logo, -logoWidth/2, -logoHeight/2)
    love.graphics.pop()
    
    -- Draw LÖVE text
    love.graphics.setFont(Splash.assets.subtitleFont)
    local loveText = "LÖVE"
    local loveWidth = Splash.assets.subtitleFont:getWidth(loveText)
    local loveHeight = Splash.assets.subtitleFont:getHeight()
    
    -- Calculate LÖVE scale
    local loveScale = Splash.animations.love.scale
    
    -- Draw LÖVE shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()*3/4)
    love.graphics.scale(loveScale, loveScale)
    love.graphics.print(loveText, -loveWidth/2 + 3, -loveHeight/2 + 3)
    love.graphics.pop()
    
    -- Draw LÖVE text
    love.graphics.setColor(1, 0.3, 0.3) -- Red color for LÖVE
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()*3/4)
    love.graphics.scale(loveScale, loveScale)
    love.graphics.print(loveText, -loveWidth/2, -loveHeight/2)
    love.graphics.pop()
    
    -- Draw transition overlay
    Transition.draw()
end

function Splash.update(dt)
    -- Update text animations
    for _, anim in pairs(Splash.animations) do
        if anim.time < anim.duration then
            anim.time = anim.time + dt
            local progress = anim.time / anim.duration
            
            -- Pop-in effect: scale up past target, then settle
            if progress < 0.5 then
                -- Scale up to pop scale
                anim.scale = anim.popScale * (progress * 2)
            else
                -- Scale down to target
                local popProgress = (progress - 0.5) * 2
                anim.scale = anim.popScale - (anim.popScale - anim.targetScale) * popProgress
            end
        else
            anim.scale = anim.targetScale
        end
    end
    
    -- Update logo animation
    if not Splash.logoAnimated and Splash.time >= Splash.logoStartTime then
        local logoProgress = (Splash.time - Splash.logoStartTime) / Splash.logoDuration
        if logoProgress < 0.3 then
            -- Scale up to 120%
            Splash.logoScale = Splash.logoBaseScale * 1.2 * (logoProgress / 0.3)
        elseif logoProgress < 1 then
            -- Scale back down to 100% with cubic easing
            local popProgress = (logoProgress - 0.3) / 0.7
            local easedProgress = 1 - (1 - popProgress) * (1 - popProgress) * (1 - popProgress) -- Cubic ease out
            Splash.logoScale = Splash.logoBaseScale * (1.2 - 0.2 * easedProgress)
        else
            -- Set to final size and mark as animated
            Splash.logoScale = Splash.logoBaseScale
            Splash.logoAnimated = true
        end
    end
    
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