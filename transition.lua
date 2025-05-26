local Transition = {
    currentState = "idle", -- idle, transitioning
    alpha = 0,
    duration = 0.5, -- seconds
    time = 0,
    onComplete = nil
}

function Transition.start(duration, onComplete)
    Transition.currentState = "transitioning"
    Transition.time = 0
    Transition.alpha = 0
    Transition.duration = duration or 0.5
    Transition.onComplete = onComplete
end

function Transition.draw()
    if Transition.currentState == "transitioning" then
        love.graphics.setColor(0, 0, 0, Transition.alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
end

function Transition.update(dt)
    if Transition.currentState == "transitioning" then
        Transition.time = Transition.time + dt
        Transition.alpha = Transition.time / Transition.duration
        
        if Transition.time >= Transition.duration then
            Transition.currentState = "idle"
            if Transition.onComplete then
                Transition.onComplete()
            end
            return true -- Signal that transition is complete
        end
    end
    return false
end

function Transition.isTransitioning()
    return Transition.currentState == "transitioning"
end

return Transition 