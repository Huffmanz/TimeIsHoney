local Transition = {
    active = false,
    progress = 0,
    duration = 0,
    onComplete = nil
}

function Transition.start(duration, onComplete)
    Transition.active = true
    Transition.progress = 0
    Transition.duration = duration
    Transition.onComplete = onComplete
end

function Transition.update(dt)
    if Transition.active then
        Transition.progress = Transition.progress + dt
        if Transition.progress >= Transition.duration then
            Transition.active = false
            if Transition.onComplete then
                local result = Transition.onComplete()
                return result
            end
        end
    end
    return false
end

function Transition.draw()
    if Transition.active then
        local alpha = Transition.progress / Transition.duration
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
end

function Transition.isTransitioning()
    return Transition.active
end

return Transition 