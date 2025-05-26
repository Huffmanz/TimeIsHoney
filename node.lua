local Node = {}
Node.__index = Node
local Bee = require("bee")

function Node.new(x, y, owner, beeCount, gameState)
    local self = setmetatable({}, { __index = Node })
    self.x = x
    self.y = y
    self.owner = owner -- Can be "player", "enemy1", "enemy2", "enemy3", or "neutral"
    self.beeCount = beeCount or 0
    self.radius = 30
    self.spawnTimer = 0
    self.isHive = false
    self.aiTimer = 0
    self.aiDelay = 2 -- AI makes decisions every 2 seconds
    self.lastSpawnTime = 0
    self.pulseTime = 0
    self.pulseSpeed = 1.5 -- Slower pulse for more juice
    self.pulseSize = 0.15 -- Larger pulse for more visibility
    self.isValidTarget = false -- Flag for valid connection target
    self.gameState = gameState
    
    -- Node variety
    self.isResourceNode = false
    self.resourceType = nil
    self.resourceAmount = 0
    self.maxBees = 20 -- Default max bees
    self.spawnRate = 0.8 + (math.random() * 0.4) -- Random spawn rate between 0.8 and 1.2
    
    -- Check if this node is too close to any hive
    local tooCloseToHive = false
    for _, node in ipairs(gameState.nodes) do
        if node.isHive then
            local dx = math.abs(self.x - node.x)
            local dy = math.abs(self.y - node.y)
            if dx <= 140 and dy <= 140 then -- One grid space away
                tooCloseToHive = true
                break
            end
        end
    end
    
    -- Only spawn resource nodes if not too close to a hive
    if not tooCloseToHive and math.random() < 0.2 then
        self.isResourceNode = true
        self.resourceType = "pollen"
        self.resourceAmount = math.random(5, 15) -- Random amount of pollen
        self.spawnRate = 0.8 -- Resource nodes spawn slightly slower
        self.maxBees = 15 -- Resource nodes hold fewer bees
    else
        -- Regular nodes have varied stats
        self.maxBees = 15 + math.random(10) -- Random max bees between 15 and 25
    end
    
    return self
end

function Node:update(dt)
    -- Update pulse effect
    self.pulseTime = self.pulseTime + dt * self.pulseSpeed
    if self.pulseTime > math.pi * 2 then
        self.pulseTime = self.pulseTime - math.pi * 2
    end
    
    -- Generate bees if this is a hive
    if self.isHive and self.owner ~= "neutral" then
        self.spawnTimer = self.spawnTimer + dt
        if self.spawnTimer >= 5.0 then -- Generate a bee every 5 seconds
            self.spawnTimer = 0
            if self.beeCount < self.maxBees then
                self.beeCount = self.beeCount + 1
            end
        end
    end
    
    -- Update resource nodes
    if self.isResourceNode and self.owner ~= "neutral" then
        -- Generate pollen over time
        self.resourceAmount = self.resourceAmount + (dt * 0.5) -- 0.5 pollen per second
        
        -- Convert pollen to bees periodically
        if self.resourceAmount >= 5 then
            self.resourceAmount = self.resourceAmount - 5
            if self.beeCount < self.maxBees then
                self.beeCount = self.beeCount + 1
            end
        end
    end
end

function Node:getColor()
    if self.owner == "player" then
        return 0.9, 0.8, 0.1 -- Yellow for player
    elseif self.owner == "enemy1" then
        return 0.8, 0.1, 0.1 -- Red for enemy1
    elseif self.owner == "enemy2" then
        return 0.1, 0.1, 0.8 -- Blue for enemy2
    elseif self.owner == "enemy3" then
        return 0.1, 0.8, 0.1 -- Green for enemy3
    elseif self.owner == "enemy4" then
        return 0.8, 0.1, 0.8 -- Purple for enemy4
    else
        return 0.7, 0.7, 0.7 -- Gray for neutral
    end
end

function Node:draw()
    -- Draw valid target indicator if this node is a valid target for the selected node
    if self.gameState.selectedNode and self ~= self.gameState.selectedNode then
        if self.gameState.selectedNode.owner == "player" and self.owner ~= "player" then
            -- Check if this is a valid neighbor
            local dx = math.abs(self.x - self.gameState.selectedNode.x)
            local dy = math.abs(self.y - self.gameState.selectedNode.y)
            local spacing = 140
            if dx <= spacing * 1.5 and dy <= spacing * 1.5 then
                -- Draw valid target indicator
                local pulseScale = 1.1 + math.sin(self.pulseTime) * 0.1
                love.graphics.setColor(0.2, 0.8, 0.2, 0.3) -- Green highlight
                love.graphics.circle("fill", self.x, self.y, self.radius * pulseScale)
            end
        end
    end
    
    -- Draw selection highlight
    if self == self.gameState.selectedNode then
        local pulse = math.sin(love.timer.getTime() * 4) * 0.2 + 0.8 -- Pulsing effect
        love.graphics.setColor(1, 0.8, 0, pulse) -- Brighter yellow with pulsing opacity
        love.graphics.circle("fill", self.x, self.y, self.radius + 8) -- Larger highlight
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end
    
    -- Draw node background
    local r, g, b = self:getColor()
    
    -- Draw hive pattern if this is a hive
    if self.isHive then
        -- Draw outer glow
        local glowPulse = 0.3 + math.sin(self.pulseTime * 2) * 0.1
        love.graphics.setColor(r, g, b, glowPulse)
        -- Draw hexagonal glow
        local glowPoints = {}
        for i = 0, 5 do
            local angle = i * math.pi/3
            table.insert(glowPoints, self.x + math.cos(angle) * self.radius * 1.3)
            table.insert(glowPoints, self.y + math.sin(angle) * self.radius * 1.3)
        end
        love.graphics.polygon("fill", glowPoints)
        
        -- Draw main hive body (hexagon)
        love.graphics.setColor(r, g, b)
        local hivePoints = {}
        for i = 0, 5 do
            local angle = i * math.pi/3
            table.insert(hivePoints, self.x + math.cos(angle) * self.radius)
            table.insert(hivePoints, self.y + math.sin(angle) * self.radius)
        end
        love.graphics.polygon("fill", hivePoints)
        
        -- Draw "HIVE" text only for player hive
        if self.owner == "player" then
            love.graphics.setColor(0, 0, 0, 0.8)
            local font = love.graphics.getFont()
            local text = "HIVE"
            local textWidth = font:getWidth(text)
            love.graphics.print(text, self.x - textWidth/2, self.y - self.radius - 20)
        end
    else
        -- Regular node drawing (flower)
        -- Draw petals
        local numPetals = self.isResourceNode and 8 or 5 -- More petals for resource nodes
        local petalLength = self.radius * 0.8
        local petalWidth = self.radius * 0.4
        
        -- Calculate base rotation for all petals using continuous time
        local baseRotation = love.timer.getTime() * (self.isResourceNode and 0.3 or 0.5) -- Slower rotation for resource nodes
        
        -- Draw petal shadows first
        love.graphics.setColor(0, 0, 0, 0.1)
        for i = 1, numPetals do
            local angle = (i-1) * (2 * math.pi / numPetals) + baseRotation
            local x = self.x + math.cos(angle) * self.radius * 0.3
            local y = self.y + math.sin(angle) * self.radius * 0.3
            
            -- Draw petal shadow
            love.graphics.push()
            love.graphics.translate(x, y)
            love.graphics.rotate(angle + math.pi/2) -- Rotate to face center
            love.graphics.ellipse("fill", 0, 0, petalWidth, petalLength)
            love.graphics.pop()
        end
        
        -- Draw petals
        for i = 1, numPetals do
            local angle = (i-1) * (2 * math.pi / numPetals) + baseRotation
            local x = self.x + math.cos(angle) * self.radius * 0.3
            local y = self.y + math.sin(angle) * self.radius * 0.3
            
            -- Draw petal
            love.graphics.push()
            love.graphics.translate(x, y)
            love.graphics.rotate(angle + math.pi/2) -- Rotate to face center
            love.graphics.setColor(r, g, b)
            love.graphics.ellipse("fill", 0, 0, petalWidth, petalLength)
            
            -- Draw petal highlight
            love.graphics.setColor(1, 1, 1, 0.2)
            love.graphics.ellipse("fill", -petalWidth * 0.2, -petalLength * 0.2, petalWidth * 0.3, petalLength * 0.3)
            love.graphics.pop()
        end
        
        -- Draw outer center ring
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.circle("fill", self.x, self.y, self.radius * 0.5)
        
        -- Draw flower center
        love.graphics.setColor(1, 1, 1, 0.95) -- White center
        love.graphics.circle("fill", self.x, self.y, self.radius * 0.35)
        
        -- Draw center highlight
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("fill", self.x - self.radius * 0.1, self.y - self.radius * 0.1, self.radius * 0.15)
    
    -- Draw resource node pattern
    if self.isResourceNode then
            -- Draw pulsing glow
            local glowPulse = 0.3 + math.sin(love.timer.getTime() * 3) * 0.2
            love.graphics.setColor(r, g, b, glowPulse)
            love.graphics.circle("fill", self.x, self.y, self.radius * 1.2)
            
        love.graphics.setColor(1, 1, 1, 0.3)
        for i = 1, 8 do
                local angle = (i-1) * math.pi/4 + baseRotation * 0.5 -- Rotate with petals but slower
            local x1 = self.x + math.cos(angle) * self.radius * 0.7
            local y1 = self.y + math.sin(angle) * self.radius * 0.7
            local x2 = self.x + math.cos(angle) * self.radius * 1.3
            local y2 = self.y + math.sin(angle) * self.radius * 1.3
            love.graphics.line(x1, y1, x2, y2)
        end
        
        -- Draw pollen amount
        love.graphics.setColor(0, 0, 0, 0.8)
        local font = love.graphics.getFont()
        local text = string.format("%.1f", self.resourceAmount)
            local textWidth = font:getWidth(text)
            love.graphics.print(text, self.x - textWidth/2, self.y - self.radius - 20)
        end
    end
    
    -- Draw bee count with pulsing effect
    local pulseScale = 1 + math.sin(self.pulseTime) * 0.1
    love.graphics.setColor(0, 0, 0)
    local font = love.graphics.getFont()
    local text = tostring(self.beeCount)
    local textWidth = font:getWidth(text)
    love.graphics.print(text, self.x - textWidth/2, self.y - font:getHeight()/2)
end

function Node:isPointInside(x, y)
    local dx = x - self.x
    local dy = y - self.y
    return math.sqrt(dx * dx + dy * dy) <= self.radius
end

return Node 