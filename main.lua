-- Game state
local gameState = {
    currentState = "splash", -- splash, menu, playing
    gameTime = 300, -- 5 minutes in seconds
    remainingTime = 300,
    selectedNode = nil,
    nodes = {},
    playerHive = nil,
    enemyHives = {},
    gameOver = false,
    winner = nil,
    bees = {}, -- Add bees table to gameState
    paths = {}, -- Add paths table to store active paths
    unlockedAreas = {1}, -- Start with first area unlocked
    camera = {
        x = 0,
        y = 0,
        scale = 1,
        targetX = 0,
        targetY = 0,
        smoothing = 0.1
    },
    fonts = {
        large = nil,
        medium = nil,
        small = nil
    },
    mapSections = {
        {
            name = "Starting Area",
            startX = 200,
            startY = 130,
            gridSize = 4,
            spacing = 140,
            nodes = {}
        },
        {
            name = "Southern Territory",
            startX = 200,
            startY = 670, -- Below starting area
            gridSize = 4,
            spacing = 140,
            nodes = {}
        },
        {
            name = "Eastern Territory",
            startX = 740, -- Changed to 760 to prevent node overlap (200 + 4*140 = 760)
            startY = 130,
            gridSize = 4,
            spacing = 140,
            nodes = {}
        },
        {
            name = "Northern Territory",
            startX = 200,
            startY = -410, -- Above starting area
            gridSize = 4,
            spacing = 140,
            nodes = {}
        }
    },
    linkBonuses = {}, -- Store active link bonuses
    gameStarted = false, -- Flag to track if game has started (first connection made)
    fogParticles = {}, -- Store fog particle systems
    captureEffects = {},
    beeTrailEffects = {},
    screenShake = {
        intensity = 0,
        duration = 0,
        time = 0
    },
    pathEffects = {}, -- Store active path effects
    captureParticles = {}, -- Store capture particles
}

-- Load required modules
local Node = require("node")
local Bee = require("bee")
local Menu = require("menu")
local Transition = require("transition")
local GameOver = require("gameover")
local Splash = require("splash")
local Music = require("music")
local SFX = require("sfx")

-- Initialize game objects
local nodes = {}
local bees = {}

function initializeFogParticles()
    -- Create new fog particles array
    local newFogParticles = {}
    
    -- Process each section
    for sectionIndex = 1, #gameState.mapSections do
        local section = gameState.mapSections[sectionIndex]
        local sectionNodes = {}
        for _, node in ipairs(nodes) do
            if node.section == sectionIndex then
                table.insert(sectionNodes, node)
            end
        end
        
        -- Find the boundaries
        local minX, maxX = math.huge, -math.huge
        local minY, maxY = math.huge, -math.huge
        for _, node in ipairs(sectionNodes) do
            minX = math.min(minX, node.x)
            maxX = math.max(maxX, node.x)
            minY = math.min(minY, node.y)
            maxY = math.max(maxY, node.y)
        end
        
        -- Track which edges should have fog
        local keepTopEdge = true
        local keepBottomEdge = true
        local keepLeftEdge = true
        local keepRightEdge = true
        
        -- Check if this section shares an edge with any unlocked area
        for _, unlockedArea in ipairs(gameState.unlockedAreas) do
            if unlockedArea ~= sectionIndex then -- Don't compare with self
                local unlockedSection = gameState.mapSections[unlockedArea]
                local unlockedNodes = {}
                for _, node in ipairs(nodes) do
                    if node.section == unlockedArea then
                        table.insert(unlockedNodes, node)
                    end
                end
                
                -- Find unlocked section boundaries
                local unlockedMinX, unlockedMaxX = math.huge, -math.huge
                local unlockedMinY, unlockedMaxY = math.huge, -math.huge
                for _, node in ipairs(unlockedNodes) do
                    unlockedMinX = math.min(unlockedMinX, node.x)
                    unlockedMaxX = math.max(unlockedMaxX, node.x)
                    unlockedMinY = math.min(unlockedMinY, node.y)
                    unlockedMaxY = math.max(unlockedMaxY, node.y)
                end
                
                -- Check if sections share an edge
                -- They share an edge if:
                -- 1. Their X ranges overlap AND one's top/bottom edge aligns with the other's
                -- 2. Their Y ranges overlap AND one's left/right edge aligns with the other's
                local xOverlap = (minX <= unlockedMaxX and maxX >= unlockedMinX)
                local yOverlap = (minY <= unlockedMaxY and maxY >= unlockedMinY)
                
                -- Check for edge alignment (with a larger tolerance for grid alignment)
                local tolerance = 140 -- Grid spacing
                local topAligned = math.abs(minY - unlockedMaxY) <= tolerance
                local bottomAligned = math.abs(maxY - unlockedMinY) <= tolerance
                local leftAligned = math.abs(minX - unlockedMaxX) <= tolerance
                local rightAligned = math.abs(maxX - unlockedMinX) <= tolerance
                
                -- Update which edges should keep fog
                if xOverlap then
                    if topAligned then 
                        keepTopEdge = false
                    end
                    if bottomAligned then 
                        keepBottomEdge = false
                    end
                end
                if yOverlap then
                    if leftAligned then 
                        keepLeftEdge = false
                    end
                    if rightAligned then 
                        keepRightEdge = false
                    end
                end
            end
        end
        
        -- Create fog particles for this section
        local points = {}
        local spacing = 8
        local borderOffset = 60
        
        -- Calculate edge positions relative to center
        local centerX = (minX + maxX) / 2
        local centerY = (minY + maxY) / 2
        local width = maxX - minX
        local height = maxY - minY
        local leftEdge = centerX - (width/2) - borderOffset
        local rightEdge = centerX + (width/2) + borderOffset
        local topEdge = centerY - (height/2) - borderOffset
        local bottomEdge = centerY + (height/2) + borderOffset
        
        -- Add particles only for edges that should keep fog
        if keepTopEdge then
            for x = leftEdge, rightEdge, spacing do
                table.insert(points, {
                    x = x,
                    y = topEdge,
                    alpha = 0,
                    size = 12,
                    rotation = love.math.random() * math.pi * 2,
                    rotationSpeed = (love.math.random() - 0.5) * 2,
                    scale = 1,
                    scaleSpeed = (love.math.random() - 0.5) * 0.5,
                    phase = love.math.random() * math.pi * 2
                })
            end
        end
        
        if keepRightEdge then
            for y = topEdge, bottomEdge, spacing do
                table.insert(points, {
                    x = rightEdge,
                    y = y,
                    alpha = 0,
                    size = 12,
                    rotation = love.math.random() * math.pi * 2,
                    rotationSpeed = (love.math.random() - 0.5) * 2,
                    scale = 1,
                    scaleSpeed = (love.math.random() - 0.5) * 0.5,
                    phase = love.math.random() * math.pi * 2
                })
            end
        end
        
        if keepBottomEdge then
            for x = rightEdge, leftEdge, -spacing do
                table.insert(points, {
                    x = x,
                    y = bottomEdge,
                    alpha = 0,
                    size = 12,
                    rotation = love.math.random() * math.pi * 2,
                    rotationSpeed = (love.math.random() - 0.5) * 2,
                    scale = 1,
                    scaleSpeed = (love.math.random() - 0.5) * 0.5,
                    phase = love.math.random() * math.pi * 2
                })
            end
        end
        
        if keepLeftEdge then
            for y = bottomEdge, topEdge, -spacing do
                table.insert(points, {
                    x = leftEdge,
                    y = y,
                    alpha = 0,
                    size = 12,
                    rotation = love.math.random() * math.pi * 2,
                    rotationSpeed = (love.math.random() - 0.5) * 2,
                    scale = 1,
                    scaleSpeed = (love.math.random() - 0.5) * 0.5,
                    phase = love.math.random() * math.pi * 2
                })
            end
        end
        
        -- Only add fog system if it has particles
        if #points > 0 then
            table.insert(newFogParticles, {
                points = points,
                section = sectionIndex,
                time = 0,
                isUnlocked = table.contains(gameState.unlockedAreas, sectionIndex)
            })
        end
    end
    
    -- Replace old fog particles with new ones
    gameState.fogParticles = newFogParticles
end

function love.load()
    -- Initialize audio system
    love.audio.setVolume(1.0)
    
    -- Load assets
    love.graphics.setBackgroundColor(0.9, 0.9, 0.8) -- Light yellow background
    
    -- Load fonts
    gameState.fonts.large = love.graphics.newFont("assets/KenneyPixel.ttf", 48)
    gameState.fonts.medium = love.graphics.newFont("assets/KenneyPixel.ttf", 32)
    gameState.fonts.small = love.graphics.newFont("assets/KenneyPixel.ttf", 24)
    
    -- Set default font
    love.graphics.setFont(gameState.fonts.medium)
    
    -- Initialize music first
    Music.load()
    
    -- Initialize sound effects
    SFX.load()
    
    -- Initialize splash screen
    Splash.load()
    
    -- Initialize menu
    Menu.load()
    
    -- Initialize game over screen
    GameOver.load()
    
    -- Initialize game
    initializeGame()
    
    -- Initialize fog particles
    initializeFogParticles()
    
    -- Center camera on starting area
    gameState.camera.targetX = gameState.mapSections[1].startX + (gameState.mapSections[1].gridSize * gameState.mapSections[1].spacing) / 2
    gameState.camera.targetY = gameState.mapSections[1].startY + (gameState.mapSections[1].gridSize * gameState.mapSections[1].spacing) / 2
    gameState.camera.x = gameState.camera.targetX
    gameState.camera.y = gameState.camera.targetY
end

function initializeGame()
    -- Clear existing game objects
    nodes = {}
    gameState.nodes = {}
    gameState.bees = {} -- Clear bees table
    gameState.selectedNode = nil
    gameState.gameOver = false
    gameState.winner = nil
    gameState.remainingTime = gameState.gameTime
    gameState.paths = {} -- Clear paths
    gameState.unlockedAreas = {1} -- Reset to only first area
    gameState.gameStarted = false -- Reset game started flag
    gameState.captureEffects = {} -- Clear effects
    gameState.beeTrailEffects = {}
    gameState.pathEffects = {}
    gameState.captureParticles = {}
    gameState.linkBonuses = {} -- Clear link bonuses
    
    -- Reset camera position
    gameState.camera.x = 0
    gameState.camera.y = 0
    gameState.camera.targetX = 0
    gameState.camera.targetY = 0
    
    -- Game constants
    gameState.SPAWN_DELAY = 0.5 -- Reduced from 2.0 to 0.5 seconds for faster initial spawning
    
    -- Initialize all map sections
    for sectionIndex, section in ipairs(gameState.mapSections) do
        section.nodes = {} -- Clear section nodes
        
        -- Create nodes for this section
        for i = 1, section.gridSize do
            for j = 1, section.gridSize do
                local x = section.startX + (j-1) * section.spacing
                local y = section.startY + (i-1) * section.spacing
                local node = Node.new(x, y, "neutral", 0, gameState)
                node.section = sectionIndex -- Store which section this node belongs to
                table.insert(section.nodes, node)
                table.insert(nodes, node)
                table.insert(gameState.nodes, node)
            end
        end
    end
    
    -- After all nodes are created, assign resource nodes
    assignResourceNodes()
    
    -- Set player hive in first section (top left)
    gameState.playerHive = gameState.mapSections[1].nodes[1]
    gameState.playerHive.owner = "player"
    gameState.playerHive.beeCount = 20
    gameState.playerHive.isHive = true
    gameState.playerHive.spawnRate = 1.0
    gameState.playerHive.maxBees = 15 + math.random(10)
    
    -- Set enemy hives
    gameState.enemyHives = {}
    
    -- Enemy 1 (Red) - Bottom right of first section (unlocks Southern Territory)
    local enemy1Hive = gameState.mapSections[1].nodes[gameState.mapSections[1].gridSize * 3 + 4] -- Bottom right
    enemy1Hive.owner = "enemy1"
    enemy1Hive.beeCount = 20
    enemy1Hive.isHive = true
    enemy1Hive.spawnRate = 1.0
    enemy1Hive.maxBees = 15 + math.random(10)
    enemy1Hive.section = 1 -- Set section number
    table.insert(gameState.enemyHives, enemy1Hive)
    
    -- Enemy 2 (Blue) - Bottom left of second section (moved from top right)
    local enemy2Hive = gameState.mapSections[2].nodes[gameState.mapSections[2].gridSize * 3 + 1] -- Bottom left
    enemy2Hive.owner = "enemy2"
    enemy2Hive.beeCount = 20
    enemy2Hive.isHive = true
    enemy2Hive.spawnRate = 1.0
    enemy2Hive.maxBees = 15 + math.random(10)
    enemy2Hive.section = 2 -- Set section number
    table.insert(gameState.enemyHives, enemy2Hive)
    
    -- Enemy 3 (Green) - Top right of third section
    local enemy3Hive = gameState.mapSections[3].nodes[gameState.mapSections[3].gridSize]
    enemy3Hive.owner = "enemy3"
    enemy3Hive.beeCount = 20
    enemy3Hive.isHive = true
    enemy3Hive.spawnRate = 1.0
    enemy3Hive.maxBees = 15 + math.random(10)
    enemy3Hive.section = 3 -- Set section number
    table.insert(gameState.enemyHives, enemy3Hive)
    
    -- Enemy 4 (Purple) - Top left of fourth section
    local enemy4Hive = gameState.mapSections[4].nodes[1] -- Top left
    enemy4Hive.owner = "enemy4"
    enemy4Hive.beeCount = 20
    enemy4Hive.isHive = true
    enemy4Hive.spawnRate = 1.0
    enemy4Hive.maxBees = 15 + math.random(10)
    enemy4Hive.section = 4 -- Set section number
    table.insert(gameState.enemyHives, enemy4Hive)
    
    -- Initialize enemy AI timers
    gameState.enemyTimers = {}
    for _, hive in ipairs(gameState.enemyHives) do
        gameState.enemyTimers[hive] = {
            lastSpawnTime = 0,
            spawnDelay = gameState.SPAWN_DELAY
        }
    end
    
    -- Initialize fog particles
    initializeFogParticles()
    
    -- Center camera on starting area
    gameState.camera.targetX = gameState.mapSections[1].startX + (gameState.mapSections[1].gridSize * gameState.mapSections[1].spacing) / 2
    gameState.camera.targetY = gameState.mapSections[1].startY + (gameState.mapSections[1].gridSize * gameState.mapSections[1].spacing) / 2
    gameState.camera.x = gameState.camera.targetX
    gameState.camera.y = gameState.camera.targetY
end

function love.update(dt)
    if gameState.currentState == "splash" then
        if Splash.update(dt) then
            gameState.currentState = "menu"
        end
    elseif gameState.currentState == "menu" then
        -- Menu state updates
        if Menu.update(dt) then
            gameState.currentState = "playing"
        end
    elseif gameState.currentState == "playing" then
        if GameOver.isShowing() then
            if GameOver.update(dt) then
                -- Reset game state and initialize new game
                gameState.currentState = "playing"
                initializeGame()
            end
        elseif not gameState.gameOver then
            -- Update game elements
            updateGameElements(dt)
        end
    end
    
    -- Update sound effects
end

function love.draw()
    if gameState.currentState == "splash" then
        Splash.draw()
    elseif gameState.currentState == "menu" then
        Menu.draw()
    elseif gameState.currentState == "playing" then
        -- Apply screen shake before camera transformation
        if gameState.screenShake.time < gameState.screenShake.duration then
            local shakeX = (math.random() * 2 - 1) * gameState.screenShake.intensity
            local shakeY = (math.random() * 2 - 1) * gameState.screenShake.intensity
            love.graphics.translate(shakeX, shakeY)
        end
        
        -- Apply camera transformation
        love.graphics.push()
        love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
        love.graphics.scale(gameState.camera.scale)
        love.graphics.translate(-gameState.camera.x, -gameState.camera.y)
        
        -- Draw game elements
        drawGameElements()
        
        -- Restore camera transformation
        love.graphics.pop()
        
        -- Draw UI (not affected by camera)
        drawUI()
        
        -- Draw game over screen if active
        if GameOver.isShowing() then
            GameOver.draw()
        end
    end
end

function drawUI()
    -- Draw timer
    local timerText = string.format("%.1f", gameState.remainingTime)
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(gameState.fonts.large)
    
    local textWidth = gameState.fonts.large:getWidth(timerText)
    local textHeight = gameState.fonts.large:getHeight()
    local centerX = love.graphics.getWidth() / 2
    local centerY = 40
    
    -- Draw outline
    love.graphics.setColor(0, 0, 0, 1)
    for dx = -3, 3, 3 do
        for dy = -3, 3, 3 do
            love.graphics.print(timerText, centerX - textWidth/2 + dx, centerY - textHeight/2 + dy)
        end
    end
    
    -- Draw main text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(timerText, centerX - textWidth/2, centerY - textHeight/2)
    
    -- Restore original font
    love.graphics.setFont(oldFont)
    
    -- Draw selected node info
    if gameState.selectedNode then
        local info = string.format("Bees: %d", gameState.selectedNode.beeCount)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(gameState.fonts.small)
        love.graphics.print(info, 10, 10)
    end
end

function drawGameElements()
    -- Draw black background for the entire game area
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", -2000, -2000, 4000, 4000)
    
    -- Draw yellow background for unlocked sections
    for i, section in ipairs(gameState.mapSections) do
        if table.contains(gameState.unlockedAreas, i) then
            local startX = section.startX
            local startY = section.startY
            local endX = startX + (section.gridSize - 1) * section.spacing
            local endY = startY + (section.gridSize - 1) * section.spacing
            
            -- Draw light yellow background for unlocked section
            love.graphics.setColor(0.9, 0.9, 0.8, 1)
            love.graphics.rectangle("fill", 
                startX - 60, 
                startY - 60,
                endX - startX + 120,
                endY - startY + 120
            )
        end
    end
    
    -- Draw particles for all sections
    for _, fog in ipairs(gameState.fogParticles) do
        if table.contains(gameState.unlockedAreas, fog.section) then
            for _, point in ipairs(fog.points) do
                love.graphics.setColor(0, 0, 0, point.alpha)
                love.graphics.push()
                love.graphics.translate(point.x, point.y)
                love.graphics.rotate(point.rotation)
                love.graphics.scale(point.scale, point.scale)
                love.graphics.rectangle("fill", -point.size, -point.size, point.size * 2, point.size * 2)
                love.graphics.pop()
            end
        end
    end
    
    -- Draw paths with flow indicators
    for _, path in ipairs(gameState.paths) do
        if path.source.owner == "player" and isNodeInUnlockedArea(path.source) then
            love.graphics.setColor(0.2, 0.6, 1, 0.3)
            love.graphics.line(path.source.x, path.source.y, path.target.x, path.target.y)
            
            local midX = (path.source.x + path.target.x) / 2
            local midY = (path.source.y + path.target.y) / 2
            local angle = math.atan2(path.target.y - path.source.y, path.target.x - path.source.x) + math.pi/2
            
            love.graphics.setColor(0.2, 0.6, 1, 0.8)
            love.graphics.push()
            love.graphics.translate(midX, midY)
            love.graphics.rotate(angle)
            love.graphics.polygon("fill", 
                0, -5,  -- Tip
                -5, 5,  -- Left base
                5, 5    -- Right base
            )
            love.graphics.pop()
        end
    end
    
    -- Draw nodes
    for _, node in ipairs(nodes) do
        if isNodeInUnlockedArea(node) then
            node:draw()
        end
    end
    
    -- Draw bees
    for _, bee in ipairs(gameState.bees) do
        bee:draw()
    end
    
    -- Draw effects
    drawEffects()
end

function drawEffects()
    -- Draw capture effects
    for _, effect in ipairs(gameState.captureEffects) do
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.alpha)
        love.graphics.circle("line", effect.x, effect.y, effect.radius)
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], effect.alpha * 0.3)
        love.graphics.circle("fill", effect.x, effect.y, effect.radius)
    end
    
    -- Draw bee trail effects
    for _, effect in ipairs(gameState.beeTrailEffects) do
        local x = effect.x + (effect.targetX - effect.x) * effect.progress
        local y = effect.y + (effect.targetY - effect.y) * effect.progress
        local alpha = 1 - effect.progress
        
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha * 0.6)
        love.graphics.circle("fill", x, y, 5)
    end
    
    -- Draw path effects
    for _, effect in ipairs(gameState.pathEffects) do
        for i = 1, effect.segments do
            local segmentProgress = effect.segmentProgress[i]
            if segmentProgress > 0 then
                local startX = effect.x + (effect.targetX - effect.x) * (i-1) / effect.segments
                local startY = effect.y + (effect.targetY - effect.y) * (i-1) / effect.segments
                local endX = effect.x + (effect.targetX - effect.x) * i / effect.segments
                local endY = effect.y + (effect.targetY - effect.y) * i / effect.segments
                
                local alpha = 0.8 * (1 - segmentProgress)
                love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha)
                love.graphics.setLineWidth(3)
                love.graphics.line(startX, startY, endX, endY)
            end
        end
    end
    
    -- Draw capture particles
    for _, particle in ipairs(gameState.captureParticles) do
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], particle.alpha)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
end

function updateGameElements(dt)
        -- Update camera position with smoothing
        gameState.camera.x = gameState.camera.x + (gameState.camera.targetX - gameState.camera.x) * gameState.camera.smoothing
        gameState.camera.y = gameState.camera.y + (gameState.camera.targetY - gameState.camera.y) * gameState.camera.smoothing
        
        -- Update fog particles
        for _, fog in ipairs(gameState.fogParticles) do
            fog.time = fog.time + dt
        for _, point in ipairs(fog.points) do
                local phase = point.phase + fog.time * 2
                point.alpha = 0.3 + math.sin(phase) * 0.2
                point.rotation = point.rotation + point.rotationSpeed * dt
            point.scale = 1 + math.sin(phase * 0.5) * 0.8
            end
        end
        
        -- Handle camera panning with arrow keys
        local panSpeed = 500 * dt
        if love.keyboard.isDown('left') then
            gameState.camera.targetX = gameState.camera.targetX - panSpeed
        end
        if love.keyboard.isDown('right') then
            gameState.camera.targetX = gameState.camera.targetX + panSpeed
        end
        if love.keyboard.isDown('up') then
            gameState.camera.targetY = gameState.camera.targetY - panSpeed
        end
        if love.keyboard.isDown('down') then
            gameState.camera.targetY = gameState.camera.targetY + panSpeed
        end
        
        -- Update game timer
        gameState.remainingTime = gameState.remainingTime - dt
        if gameState.remainingTime <= 0 then
            endGame("time")
        end
        
        -- Update nodes in unlocked areas
        for _, node in ipairs(nodes) do
            if isNodeInUnlockedArea(node) then
                node:update(dt)
            end
        end
        
        -- Update link bonuses
        for i = #gameState.linkBonuses, 1, -1 do
            local bonus = gameState.linkBonuses[i]
            local elapsed = love.timer.getTime() - bonus.startTime
            if elapsed >= bonus.duration then
                table.remove(gameState.linkBonuses, i)
            end
        end
        
    -- Update paths and spawn bees
        if gameState.gameStarted then
        updatePaths(dt)
    end
    
    -- Update enemy AI
    updateEnemyAI(dt)
    
    -- Update bees
    updateBees(dt)
    
    -- Update resource nodes
    updateResourceNodes(dt)
    
    -- Check win condition
    checkWinCondition()
    
    -- Update effects
    updateEffects(dt)
end

function updatePaths(dt)
            for _, path in ipairs(gameState.paths) do
                if path.source.beeCount > 1 and isNodeInUnlockedArea(path.source) then
                    path.lastSpawnTime = path.lastSpawnTime + dt
                    
                    -- Check for link bonus
                    local spawnMultiplier = 1.0
                    for _, bonus in ipairs(gameState.linkBonuses) do
                        if bonus.node == path.source then
                            spawnMultiplier = bonus.multiplier
                            break
                        end
                    end
                    
            -- Apply node's spawn rate
                    local effectiveDelay = path.spawnDelay * (1 / (spawnMultiplier * path.source.spawnRate))
                    
                    if path.lastSpawnTime >= effectiveDelay then
                        path.lastSpawnTime = 0
                        path.source.beeCount = path.source.beeCount - 1
                        local newBee = Bee.new(
                            path.source.x,
                            path.source.y,
                            path.target.x,
                            path.target.y,
                            path.source.owner,
                            gameState
                        )
                        if newBee then
                            table.insert(gameState.bees, newBee)
                        end
                    end
                end
            end
        end
        
function updateEnemyAI(dt)
        for i = #gameState.enemyHives, 1, -1 do
            local hive = gameState.enemyHives[i]
            
            if hive.owner:sub(1, 5) ~= "enemy" then
                table.remove(gameState.enemyHives, i)
            elseif isNodeInUnlockedArea(hive) and hive.beeCount > 1 and hive.owner == "enemy" .. tostring(hive.section) then
                gameState.enemyTimers[hive].lastSpawnTime = gameState.enemyTimers[hive].lastSpawnTime + dt
                
                if gameState.enemyTimers[hive].lastSpawnTime >= gameState.enemyTimers[hive].spawnDelay then
                    gameState.enemyTimers[hive].lastSpawnTime = 0
                    
                -- Find nearest valid target
                local nearestNode = findNearestEnemyTarget(hive)
                
                    if nearestNode then
                    createEnemyPath(hive, nearestNode)
                            end
                        end
                                    end
                                end
                            end
                            
function updateBees(dt)
        for i = #gameState.bees, 1, -1 do
            if gameState.bees[i]:update(dt) then
                local targetNode = gameState.bees[i].targetNode
                if targetNode then                    
                -- Play bee sound when bee arrives
                SFX.play("bee")
                handleBeeArrival(targetNode, gameState.bees[i])
                end
                table.remove(gameState.bees, i)
        end
            end
        end
        
function updateResourceNodes(dt)
        for _, node in ipairs(nodes) do
            if node.isResourceNode and node.owner ~= "neutral" then
            node.resourceAmount = node.resourceAmount + (dt * 0.5)
                
                if node.resourceAmount >= 5 then
                    node.resourceAmount = node.resourceAmount - 5
                    if node.beeCount < node.maxBees then
                        node.beeCount = node.beeCount + 1
                end
                    end
                end
            end
        end
        
function updateEffects(dt)
    -- Update screen shake
    if gameState.screenShake.time < gameState.screenShake.duration then
        gameState.screenShake.time = gameState.screenShake.time + dt
        gameState.screenShake.intensity = gameState.screenShake.intensity * (1 - dt)
    end
        
        -- Update capture effects
        for i = #gameState.captureEffects, 1, -1 do
            local effect = gameState.captureEffects[i]
            effect.time = effect.time + dt
            effect.radius = 30 + (effect.maxRadius - 30) * (effect.time / effect.duration)
            effect.alpha = 1 - (effect.time / effect.duration)
            
            if effect.time >= effect.duration then
                table.remove(gameState.captureEffects, i)
            end
        end
        
        -- Update bee trail effects
        for i = #gameState.beeTrailEffects, 1, -1 do
            local effect = gameState.beeTrailEffects[i]
            effect.time = effect.time + dt
            effect.progress = effect.time / effect.duration
            
            if effect.time >= effect.duration then
                table.remove(gameState.beeTrailEffects, i)
            end
        end
        
        -- Update path effects
        for i = #gameState.pathEffects, 1, -1 do
            local effect = gameState.pathEffects[i]
            effect.time = effect.time + dt
            effect.progress = effect.time / effect.duration
            
            for j = 1, effect.segments do
                effect.segmentProgress[j] = math.min(1, effect.progress * 2 - (j-1) * 0.1)
            end
            
            if effect.time >= effect.duration then
                table.remove(gameState.pathEffects, i)
            end
        end
        
        -- Update capture particles
        for i = #gameState.captureParticles, 1, -1 do
            local particle = gameState.captureParticles[i]
            particle.time = particle.time + dt
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
            particle.alpha = 1 - (particle.time / particle.duration)
            
            if particle.time >= particle.duration then
                table.remove(gameState.captureParticles, i)
        end
    end
end

function love.mousepressed(x, y, button)
    if gameState.currentState == "menu" then
        if Menu.handleClick(x, y, button) then
            gameState.currentState = "playing"
            initializeGame()
        end
    elseif gameState.currentState == "playing" then
        if GameOver.isShowing() then
            if GameOver.handleClick(x, y, button) then
                -- Game over screen will handle the restart
            end
        else
            handleGameClick(x, y, button)
        end
    end
end

function isNeighbor(node1, node2)
    -- Calculate the distance between nodes
    local dx = math.abs(node1.x - node2.x)
    local dy = math.abs(node1.y - node2.y)
    local spacing = 140 -- Same as the grid spacing
    
    -- Allow connections if nodes are adjacent horizontally, vertically, or diagonally
    -- Using a slightly larger threshold (1.5 * spacing) to account for floating point imprecision
    return dx <= spacing * 1.5 and dy <= spacing * 1.5
end

function handleNodeClick(x, y)
    local clickedNode = nil
    
    -- Find clicked node
    for _, node in ipairs(nodes) do
        if node:isPointInside(x, y) then
            clickedNode = node
            break
        end
    end
    
    if clickedNode then
        if not gameState.selectedNode then
            -- Select source node
            if clickedNode.owner == "player" and clickedNode.beeCount > 0 then
                gameState.selectedNode = clickedNode
                -- Play selection sound
                SFX.play("selectNode")
            end
        else
            -- Create or update path
            if gameState.selectedNode ~= clickedNode then
                -- Check if nodes are neighbors
                if isNeighbor(gameState.selectedNode, clickedNode) then
                    -- Create path effect
                    local r, g, b = gameState.selectedNode:getColor()
                    createPathEffect(gameState.selectedNode.x, gameState.selectedNode.y, clickedNode.x, clickedNode.y, {r, g, b})
                    
                    -- Remove any existing enemy paths between these nodes
                    for i = #gameState.paths, 1, -1 do
                        local path = gameState.paths[i]
                        if (path.source == gameState.selectedNode and path.target == clickedNode) or
                           (path.source == clickedNode and path.target == gameState.selectedNode) then
                            table.remove(gameState.paths, i)
                        end
                    end
                    
                    -- Create new player path
                    table.insert(gameState.paths, {
                        source = gameState.selectedNode,
                        target = clickedNode,
                        lastSpawnTime = 0,
                        spawnDelay = gameState.SPAWN_DELAY
                    })
                    
                    -- Set game as started when first connection is made
                    if not gameState.gameStarted then
                        gameState.gameStarted = true
                    end
                end
            end
            gameState.selectedNode = nil
        end
    else
        gameState.selectedNode = nil
    end
end

function checkWinCondition()
    -- Check if all enemy hives are eliminated
    if #gameState.enemyHives == 0 then
        endGame("player")
        return
    end
    
    -- Check if player's hive is captured
    if gameState.playerHive.owner ~= "player" then
        -- Find which enemy captured the player's hive
        local capturer = gameState.playerHive.owner
        endGame(capturer)
        return
    end
    
    -- Check if any enemy has been eliminated (no nodes left)
    for i = #gameState.enemyHives, 1, -1 do
        local hive = gameState.enemyHives[i]
        local enemyType = hive.owner
        local hasNodes = false
        
        -- Check if this enemy has any nodes left
        for _, node in ipairs(nodes) do
            if node.owner == enemyType then
                hasNodes = true
                break
            end
        end
        
        -- If enemy has no nodes left, remove their hive
        if not hasNodes then
            table.remove(gameState.enemyHives, i)
        end
    end
end

function endGame(reason)
    gameState.gameOver = true
    -- Reset screen shake
    gameState.screenShake.intensity = 0
    gameState.screenShake.duration = 0
    gameState.screenShake.time = 0
    
    if reason == "time" then
        -- Count nodes to determine winner
        local playerNodes = 0
        local enemyNodes = {}
        enemyNodes["enemy1"] = 0
        enemyNodes["enemy2"] = 0
        enemyNodes["enemy3"] = 0
        
        for _, node in ipairs(nodes) do
            if node.owner == "player" then
                playerNodes = playerNodes + 1
            elseif node.owner ~= "neutral" then
                enemyNodes[node.owner] = (enemyNodes[node.owner] or 0) + 1
            end
        end
        
        -- Find the faction with the most nodes
        local maxNodes = playerNodes
        local winner = "player"
        for enemyType, count in pairs(enemyNodes) do
            if count > maxNodes then
                maxNodes = count
                winner = enemyType
            end
        end
        GameOver.show(winner)
    else
        GameOver.show(reason)
    end
end

function isNodeInUnlockedArea(node)
    return table.contains(gameState.unlockedAreas, node.section)
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function handleNodeCapture(node, newOwner)
    -- Store the current bee count
    local currentBeeCount = node.beeCount
    
    -- Remove all outgoing connections from this node
    removeNodePaths(node)

    -- Check for link bonus
    local hasLinkBonus = false
    for _, ownedNode in ipairs(nodes) do
        if ownedNode.owner == newOwner and isNeighbor(node, ownedNode) then
            hasLinkBonus = true
            -- Add link bonus
            table.insert(gameState.linkBonuses, {
                node = node,
                startTime = love.timer.getTime(),
                duration = 15, -- 15 seconds
                multiplier = 1.1 -- 10% bonus
            })
            break
        end
    end
    
    -- Update node owner and ensure bee count is at least 1
    node.owner = newOwner
    node.beeCount = math.max(1, currentBeeCount)
    
    -- Play appropriate capture sound
    if newOwner == "player" then
        SFX.play("captureNode")
    else
        SFX.play("enemyCaptureNode")
    end
    
    -- Create capture effect
    local r, g, b = node:getColor()
    createCaptureEffect(node.x, node.y, {r, g, b})
    createCaptureParticles(node.x, node.y, {r, g, b})
    createScreenShake(5, 0.2) -- Add screen shake on capture
end

function handleHiveCapture(hive, newOwner)    
    -- Store the current bee count
    local currentBeeCount = hive.beeCount
    
    -- Remove all paths to/from this hive
    removeNodePaths(hive)
    
    -- Remove from enemy timers and hives
    if gameState.enemyTimers[hive] then
        gameState.enemyTimers[hive] = nil
    end
    
    -- Remove from enemy hives
    for i = #gameState.enemyHives, 1, -1 do
        if gameState.enemyHives[i] == hive then
            table.remove(gameState.enemyHives, i)
            break
        end
    end
    
    -- Update hive ownership
    hive.owner = newOwner
    
    -- If the new owner is an enemy, add it to enemyHives and set up timer
    if newOwner ~= "player" then
        table.insert(gameState.enemyHives, hive)
        gameState.enemyTimers[hive] = {
            lastSpawnTime = 0,
            spawnDelay = gameState.SPAWN_DELAY
        }
    end
    
    -- Restore the bee count
    hive.beeCount = currentBeeCount
    
    -- Play appropriate capture sound
    if newOwner == "player" then
        SFX.play("captureHive")
    else
        SFX.play("enemyCaptureHive")
    end
    
    -- If this was an enemy hive and is now player owned, unlock the next area
    if newOwner == "player" and hive.owner == "player" then
        local nextArea = hive.section + 1
        if nextArea <= #gameState.mapSections and not table.contains(gameState.unlockedAreas, nextArea) then
            table.insert(gameState.unlockedAreas, nextArea)
            initializeFogParticles()
        end
    end
    
    -- Create stronger effects for hive capture
    local r, g, b = hive:getColor()
    createCaptureEffect(hive.x, hive.y, {r, g, b})
    createCaptureParticles(hive.x, hive.y, {r, g, b})
    createScreenShake(10, 0.3) -- Stronger screen shake for hive capture
end

function removeNodePaths(node)
    local pathsToRemove = {}
    for i, path in ipairs(gameState.paths) do
        if path.source == node then
            table.insert(pathsToRemove, i)
        end
    end

        -- Remove paths in reverse order
    for i = #pathsToRemove, 1, -1 do
        table.remove(gameState.paths, pathsToRemove[i])
    end
end

function createCaptureEffect(x, y, color)
    table.insert(gameState.captureEffects, {
        x = x,
        y = y,
        radius = 30,
        maxRadius = 60,
        alpha = 1,
        color = color,
        time = 0,
        duration = 0.5
    })
end

function createBeeTrailEffect(x, y, targetX, targetY, color)
    table.insert(gameState.beeTrailEffects, {
        x = x,
        y = y,
        targetX = targetX,
        targetY = targetY,
        progress = 0,
        color = color,
        time = 0,
        duration = 0.3
    })
end

function createScreenShake(intensity, duration)
    gameState.screenShake.intensity = intensity
    gameState.screenShake.duration = duration
    gameState.screenShake.time = 0
end

function createPathEffect(sourceX, sourceY, targetX, targetY, color)
    table.insert(gameState.pathEffects, {
        x = sourceX,
        y = sourceY,
        targetX = targetX,
        targetY = targetY,
        progress = 0,
        color = color,
        time = 0,
        duration = 0.5,
        segments = 8,
        segmentProgress = {}
    })
    
    -- Initialize segment progress
    local effect = gameState.pathEffects[#gameState.pathEffects]
    for i = 1, effect.segments do
        effect.segmentProgress[i] = 0
    end
end

function createCaptureParticles(x, y, color)
    for i = 1, 20 do
        local angle = math.random() * math.pi * 2
        local speed = math.random(50, 150)
        local size = math.random(3, 6)
        table.insert(gameState.captureParticles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = size,
            color = color,
            alpha = 1,
            time = 0,
            duration = 0.5
        })
    end
end

-- Add this function after initializeGame
function assignResourceNodes()
    -- First pass: identify hives
    local hives = {}
    for _, node in ipairs(nodes) do
        if node.isHive then
            table.insert(hives, node)
        end
    end
    
    -- Second pass: assign resource nodes
    for _, node in ipairs(nodes) do
        if not node.isHive then
            -- Check if this node is too close to any hive
            local tooCloseToHive = false
            for _, hive in ipairs(hives) do
                local dx = math.abs(node.x - hive.x)
                local dy = math.abs(node.y - hive.y)
                if dx <= 140 and dy <= 140 then -- One grid space away
                    tooCloseToHive = true
                    break
                end
            end
            
            -- Only spawn resource nodes if not too close to a hive
            if not tooCloseToHive and math.random() < 0.2 then
                node.isResourceNode = true
                node.resourceType = "pollen"
                node.resourceAmount = math.random(5, 15)
                node.spawnRate = 0.8
                node.maxBees = 15
            else
                node.spawnRate = 0.8 + (math.random() * 0.4)
                node.maxBees = 15 + math.random(10)
            end
        end
    end
end

function findNearestEnemyTarget(hive)
    -- Initialize variables for finding nearest node
    local nearestNode = nil
    local minDist = math.huge
    
    -- Get all nodes owned by this enemy
    local ownedNodes = {}
    for _, node in ipairs(nodes) do
        if node.owner == hive.owner and isNodeInUnlockedArea(node) and node.beeCount > 1 then
            table.insert(ownedNodes, node)
        end
    end
    
    -- For each owned node, find potential targets
    for _, sourceNode in ipairs(ownedNodes) do
        -- Get all neighbor nodes
        local neighborNodes = {}
        for _, targetNode in ipairs(nodes) do
            -- Check if this node is a neighbor of the source node
            if isNeighbor(sourceNode, targetNode) then
                table.insert(neighborNodes, targetNode)
            end
        end
        
        -- Then filter for valid targets in unlocked areas
        local validTargets = {}
        for _, targetNode in ipairs(neighborNodes) do
            -- Check if node is in unlocked area
            local inUnlockedArea = isNodeInUnlockedArea(targetNode)
            
            -- Check if node is not the source
            local notSource = targetNode ~= sourceNode
            
            -- Check if node has valid owner (neutral or enemy)
            local validOwner = targetNode.owner == "neutral" or targetNode.owner ~= hive.owner
            
            -- Check if node is not a captured hive
            local notCapturedHive = not (targetNode.isHive and targetNode.owner ~= hive.owner)
            
            if inUnlockedArea and notSource and validOwner and notCapturedHive then
                table.insert(validTargets, targetNode)
            end
        end
        
        -- Add some randomization to target selection
        if #validTargets > 0 then
            -- 70% chance to pick closest target, 30% chance to pick random target
            local targetNode
            if math.random() < 0.7 then
                -- Find closest target
                local minDist = math.huge
                for _, target in ipairs(validTargets) do
                    local dx = target.x - sourceNode.x
                    local dy = target.y - sourceNode.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < minDist then
                        minDist = dist
                        targetNode = target
                    end
                end
            else
                -- Pick random target
                targetNode = validTargets[math.random(1, #validTargets)]
            end
            
            if targetNode then
                local dx = targetNode.x - sourceNode.x
                local dy = targetNode.y - sourceNode.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist < minDist then
                    minDist = dist
                    nearestNode = targetNode
                end
            end
        end
    end
    
    return nearestNode
end

function createEnemyPath(hive, targetNode)
    -- Find the source node that's closest to the target
    local bestSource = nil
    local bestDist = math.huge
    local ownedNodes = {}
    
    -- Get all nodes owned by this enemy
    for _, node in ipairs(nodes) do
        if node.owner == hive.owner and isNodeInUnlockedArea(node) and node.beeCount > 1 then
            table.insert(ownedNodes, node)
        end
    end
    
    -- Find the best source node
    for _, sourceNode in ipairs(ownedNodes) do
        if isNeighbor(sourceNode, targetNode) then
            local dx = sourceNode.x - targetNode.x
            local dy = sourceNode.y - targetNode.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < bestDist then
                bestDist = dist
                bestSource = sourceNode
            end
        end
    end
    
    if bestSource then
        -- Check if this source node already has a path
        local sourceHasPath = false
        for _, path in ipairs(gameState.paths) do
            if path.source == bestSource then
                sourceHasPath = true
                break
            end
        end
        
        if not sourceHasPath then
            table.insert(gameState.paths, {
                source = bestSource,
                target = targetNode,
                lastSpawnTime = 0,
                spawnDelay = gameState.SPAWN_DELAY
            })
        else
            -- Try to find another source node
            for _, altSource in ipairs(ownedNodes) do
                if altSource ~= bestSource and isNeighbor(altSource, targetNode) then
                    local hasPath = false
                    for _, path in ipairs(gameState.paths) do
                        if path.source == altSource then
                            hasPath = true
                            break
                        end
                    end
                    if not hasPath then
                        table.insert(gameState.paths, {
                            source = altSource,
                            target = targetNode,
                            lastSpawnTime = 0,
                            spawnDelay = gameState.SPAWN_DELAY
                        })
                        break
                    end
                end
            end
        end
    end
end

function handleBeeArrival(targetNode, bee)
    -- First check for hive capture if it's a hive
    if targetNode.isHive and targetNode.owner ~= bee.owner then
        -- Store the new owner before handling the capture
        local newOwner = bee.owner
        
        -- Handle the hive capture
        handleHiveCapture(targetNode, newOwner)
    end
    
    -- Then handle the node capture
    if targetNode.owner ~= bee.owner then
        -- If node is neutral or has fewer bees, capture it
        if targetNode.owner == "neutral" or targetNode.beeCount < 1 then
            handleNodeCapture(targetNode, bee.owner)
            targetNode.beeCount = 1
        else
            -- Otherwise, reduce the node's bee count
            targetNode.beeCount = targetNode.beeCount - 1
            if targetNode.beeCount <= 0 then
                handleNodeCapture(targetNode, bee.owner)
                targetNode.beeCount = 1
            end
        end
    else
        -- If same owner, just add the bee
        targetNode.beeCount = targetNode.beeCount + 1
    end
end

function handleGameClick(x, y, button)
    if button == 1 then -- Left click
        -- Convert mouse position to world coordinates
        local worldX = (x - love.graphics.getWidth()/2) / gameState.camera.scale + gameState.camera.x
        local worldY = (y - love.graphics.getHeight()/2) / gameState.camera.scale + gameState.camera.y
        
        -- Play click sound
        SFX.play("click")
        
        handleNodeClick(worldX, worldY)
    end
end