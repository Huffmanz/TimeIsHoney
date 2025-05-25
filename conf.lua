function love.conf(t)
    t.title = "Hive Conquest"
    t.version = "11.4"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = false
    t.window.vsync = true
    t.window.minwidth = 800
    t.window.minheight = 600
    
    -- Enable required modules
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
    t.modules.audio = true
    t.modules.event = true
    t.modules.keyboard = true
    t.modules.mouse = true
    t.modules.timer = true
    t.modules.window = true
    t.modules.graphics = true
end 