local SFX = {
    sounds = {}, -- Dictionary of event -> array of sound sources
    volume = 0.5,
    activeSounds = {}, -- Pool of currently playing sounds
    maxConcurrent = 16 -- Maximum number of concurrent sounds
}

function SFX.load()
    -- Load sound effects into event-based dictionary
    SFX.sounds = {
        captureNode = {
            love.audio.newSource("assets/sfx/FA_Collect_Coin_1_1.wav", "static"),
            love.audio.newSource("assets/sfx/FA_Collect_Coin_1_2.wav", "static"),
            love.audio.newSource("assets/sfx/FA_Collect_Coin_1_3.wav", "static"),
            love.audio.newSource("assets/sfx/FA_Collect_Coin_1_4.wav", "static")
            
        },
        captureHive = {
            love.audio.newSource("assets/sfx/PP_Collect_Item_1_1.wav", "static"),
            love.audio.newSource("assets/sfx/PP_Collect_Item_1_2.wav", "static")
        },
        selectNode = {
            love.audio.newSource("assets/sfx/CGM3_Bubble_Button_01_1.wav", "static"),
            love.audio.newSource("assets/sfx/CGM3_Bubble_Button_01_2.wav", "static"),
            love.audio.newSource("assets/sfx/CGM3_Bubble_Button_01_3.wav", "static"),
            love.audio.newSource("assets/sfx/CGM3_Bubble_Button_01_4.wav", "static"),
            love.audio.newSource("assets/sfx/CGM3_Bubble_Button_01_5.wav", "static"),
            love.audio.newSource("assets/sfx/CGM3_Bubble_Button_01_6.wav", "static")
        },
        enemyCaptureNode = {
            love.audio.newSource("assets/sfx/impactMining_000.ogg", "static"),
            love.audio.newSource("assets/sfx/impactMining_001.ogg", "static"),
            love.audio.newSource("assets/sfx/impactMining_002.ogg", "static"),
            love.audio.newSource("assets/sfx/impactMining_003.ogg", "static"),
            love.audio.newSource("assets/sfx/impactMining_004.ogg", "static")
        },
        enemyCaptureHive = {
            love.audio.newSource("assets/sfx/impactMining_000.ogg", "static"),
            love.audio.newSource("assets/sfx/impactMining_001.ogg", "static"),
            love.audio.newSource("assets/sfx/impactMining_002.ogg", "static"),
            love.audio.newSource("assets/sfx/impactMining_003.ogg", "static"),
            love.audio.newSource("assets/sfx/impactMining_004.ogg", "static")
        },
        uiHover = {
            love.audio.newSource("assets/sfx/switch_001.ogg", "static"),
            love.audio.newSource("assets/sfx/switch_003.ogg", "static"),
            love.audio.newSource("assets/sfx/switch_004.ogg", "static"),
            love.audio.newSource("assets/sfx/switch_005.ogg", "static"),
            love.audio.newSource("assets/sfx/switch_006.ogg", "static"),
            love.audio.newSource("assets/sfx/switch_007.ogg", "static")
        },
        uiClick = {
            love.audio.newSource("assets/sfx/click_001.ogg", "static"),
            love.audio.newSource("assets/sfx/click_002.ogg", "static"),
            love.audio.newSource("assets/sfx/click_003.ogg", "static"),
            love.audio.newSource("assets/sfx/click_004.ogg", "static"),
            love.audio.newSource("assets/sfx/click_005.ogg", "static")
        }
    }
    
    -- Set initial volume for all sounds
    for _, variations in pairs(SFX.sounds) do
        for _, sound in ipairs(variations) do
            sound:setVolume(SFX.volume)
        end
    end
end

function SFX.play(eventName)
    -- Get the array of sound variations for this event
    local variations = SFX.sounds[eventName]
    if variations then
        -- Randomly select a variation
        local sound = variations[love.math.random(1, #variations)]
        
        if sound then
            -- Clean up finished sounds
            for i = #SFX.activeSounds, 1, -1 do
                local activeSound = SFX.activeSounds[i]
                if not activeSound:isPlaying() then
                    activeSound:release()
                    table.remove(SFX.activeSounds, i)
                end
            end
            
            -- If we've reached the maximum concurrent sounds, remove the oldest one
            if #SFX.activeSounds >= SFX.maxConcurrent then
                local oldestSound = table.remove(SFX.activeSounds, 1)
                oldestSound:stop()
                oldestSound:release()
            end
            
            -- Clone the sound to allow multiple instances
            local soundInstance = sound:clone()
            
            -- Random pitch variation between 0.9 and 1.1
            local pitch = 0.9 + (math.random() * 0.2)
            soundInstance:setPitch(pitch)
            
            -- Add to active sounds pool
            table.insert(SFX.activeSounds, soundInstance)
            
            -- Play the sound
            soundInstance:play()
        end
    end
end

function SFX.setVolume(volume)
    SFX.volume = volume
    for _, variations in pairs(SFX.sounds) do
        for _, sound in ipairs(variations) do
            sound:setVolume(volume)
        end
    end
    -- Update volume for all active sounds
    for _, sound in ipairs(SFX.activeSounds) do
        sound:setVolume(volume)
    end
end

function SFX.update(dt)
    -- Clean up finished sounds
    for i = #SFX.activeSounds, 1, -1 do
        local sound = SFX.activeSounds[i]
        if not sound:isPlaying() then
            sound:release()
            table.remove(SFX.activeSounds, i)
        end
    end
end

return SFX 