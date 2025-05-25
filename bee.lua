local Bee = {}
Bee.__index = Bee

function Bee.new(startX, startY, targetX, targetY, beeCount, gameState)
    -- First check if source and target are in unlocked areas
    local sourceNode = nil
    local targetNode = nil
    
    for _, node in ipairs(gameState.nodes) do
        if node.x == startX and node.y == startY then
            sourceNode = node
        end
        if node.x == targetX and node.y == targetY then
            targetNode = node
        end
        if sourceNode and targetNode then
            break
        end
    end
    
    -- If either node is not found or is in a locked area, return nil
    if not sourceNode or not targetNode or 
       not table.contains(gameState.unlockedAreas, sourceNode.section) or 
       not table.contains(gameState.unlockedAreas, targetNode.section) then
        print("Cannot create bee - source or target node is in locked area or not found")
        return nil
    end
    
    local self = setmetatable({}, Bee)
    self.x = startX
    self.y = startY
    self.targetX = targetX
    self.targetY = targetY
    self.beeCount = beeCount
    self.speed = 200
    self.owner = sourceNode.owner -- Set owner based on source node
    self.gameState = gameState
    
    -- Calculate initial angle with small random deviation
    local baseAngle = math.atan2(targetY - startY, targetX - startX)
    local randomAngle = (love.math.random() - 0.5) * (math.pi / 12) -- Random angle between -15 and +15 degrees
    self.angle = baseAngle + randomAngle
    self.currentAngle = self.angle
    self.targetAngle = self.angle
    self.arrived = false
    
    -- Store target node
    self.targetNode = targetNode
    
    -- Buzzing motion parameters
    self.buzzTime = 0
    self.buzzAmplitude = 100
    self.buzzFrequency = 25
    self.buzzOffset = love.math.random() * math.pi * 2
    self.buzzDirection = love.math.random() * math.pi * 2
    
    -- Jitter parameters
    self.jitterTimer = 0
    self.jitterFrequency = 0.02
    self.jitterX = 0
    self.jitterY = 0
    self.jitterAmount = 1  -- Reduced from 100 to 1 for minimal jitter
    
    -- Random direction change parameters
    self.directionChangeTimer = 0
    self.directionChangeFrequency = 1.0  -- Increased from 0.8 to 1.0 for even less frequent changes
    self.angleChangeSpeed = 12  -- Increased from 8 to 12 for much faster correction
    self.maxAngleDeviation = math.pi * 0.0005  -- Reduced from 0.001 to 0.0005 for extremely minimal deviation
    
    -- Trail parameters
    self.trail = {}
    self.trailDelay = 0.2
    self.trailPositions = {}
    self.maxTrailLength = 20
    
    return self
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function Bee:update(dt)
    -- Store current position in history
    table.insert(self.trailPositions, {x = self.x, y = self.y, time = love.timer.getTime()})
    
    -- Remove old positions
    while #self.trailPositions > 0 and love.timer.getTime() - self.trailPositions[1].time > self.trailDelay do
        table.remove(self.trailPositions, 1)
    end
    
    -- Update trail with delayed positions
    self.trail = {}
    for _, pos in ipairs(self.trailPositions) do
        table.insert(self.trail, {x = pos.x, y = pos.y})
    end
    
    -- Update buzzing motion
    self.buzzTime = self.buzzTime + dt * self.buzzFrequency
    local buzzX = math.sin(self.buzzTime + self.buzzOffset) * self.buzzAmplitude
    local buzzY = math.cos(self.buzzTime + self.buzzOffset) * self.buzzAmplitude
    
    -- Update jitter with smoother transitions
    self.jitterTimer = self.jitterTimer + dt
    if self.jitterTimer >= self.jitterFrequency then
        self.jitterTimer = 0
        -- Smoother jitter by interpolating between current and target values
        self.jitterX = self.jitterX + (love.math.random() - 0.5) * self.jitterAmount
        self.jitterY = self.jitterY + (love.math.random() - 0.5) * self.jitterAmount
        -- Clamp jitter values
        self.jitterX = math.max(-self.jitterAmount, math.min(self.jitterAmount, self.jitterX))
        self.jitterY = math.max(-self.jitterAmount, math.min(self.jitterAmount, self.jitterY))
    end
    
    if not self.arrived then
        -- Calculate base movement towards target
        local dx = self.targetX - self.x
        local dy = self.targetY - self.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist < 30 then
            self.x = self.targetX
            self.y = self.targetY
            self.arrived = true
            self:arriveAtTarget()
            return true -- Remove bee after arrival
        else
            -- Calculate direct angle to target
            local targetAngle = math.atan2(dy, dx)
            
            -- Update random direction changes less frequently
            self.directionChangeTimer = self.directionChangeTimer + dt
            if self.directionChangeTimer >= self.directionChangeFrequency then
                self.directionChangeTimer = 0
                -- Add extremely small random deviation to target angle
                self.targetAngle = targetAngle + (love.math.random() - 0.5) * self.maxAngleDeviation
            end
            
            -- Smoothly interpolate current angle towards target angle
            local angleDiff = self.targetAngle - self.currentAngle
            -- Normalize angle difference to [-pi, pi]
            while angleDiff > math.pi do angleDiff = angleDiff - 2 * math.pi end
            while angleDiff < -math.pi do angleDiff = angleDiff + 2 * math.pi end
            self.currentAngle = self.currentAngle + angleDiff * dt * self.angleChangeSpeed
            
            -- Calculate perpendicular direction for buzzing
            local perpX = -dy / dist
            local perpY = dx / dist
            
            -- Calculate movement direction based on current angle
            local moveX = math.cos(self.currentAngle)
            local moveY = math.sin(self.currentAngle)
            
            -- Apply movement plus minimal buzzing and jitter
            self.x = self.x + moveX * self.speed * dt + 
                    perpX * buzzX * dt * 0.5 +  -- Reduced from 0.8 to 0.5
                    self.jitterX * dt * 0.5     -- Reduced from 1.0 to 0.5
            self.y = self.y + moveY * self.speed * dt + 
                    perpY * buzzY * dt * 0.5 +  -- Reduced from 0.8 to 0.5
                    self.jitterY * dt * 0.5     -- Reduced from 1.0 to 0.5
        end
    end
    
    return false
end

function Bee:draw()
    -- Draw trail
    for i, pos in ipairs(self.trail) do
        local alpha = i / #self.trail * 0.5
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.circle("fill", pos.x, pos.y, 2)
    end

    -- Draw bee body with black outline
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("fill", self.x, self.y, 4)
    
    love.graphics.setColor(0.8, 0.8, 0.2)
    love.graphics.circle("fill", self.x, self.y, 3)
    
    -- Calculate movement direction
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local angle = math.atan2(dy, dx) + math.pi/2
    
    -- Draw bee wings with rotation and movement
    local wingOffset = math.sin(self.buzzTime * 1.5) * 2
    
    -- Save current transform
    love.graphics.push()
    
    -- Move to bee position and rotate
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(angle)
    
    -- Wing outlines
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.ellipse("fill", -3, -wingOffset, 4, 2)
    love.graphics.ellipse("fill", 3, wingOffset, 4, 2)
    
    -- Wing fill
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.ellipse("fill", -3, -wingOffset, 3, 1.5)
    love.graphics.ellipse("fill", 3, wingOffset, 3, 1.5)
    
    -- Restore transform
    love.graphics.pop()
end

function Bee:arriveAtTarget()
    if self.targetNode then
        -- Just update the bee count, ownership changes are handled in main.lua
        if self.targetNode.owner == self.owner then
            self.targetNode.beeCount = self.targetNode.beeCount + 1
        else
            self.targetNode.beeCount = self.targetNode.beeCount - 1
        end
    end
end

return Bee 