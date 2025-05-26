local Music = {
    currentTrack = nil,
    volume = 0.3
}

function Music.load()
    -- Load the background music
    local success, error = pcall(function()
        Music.currentTrack = love.audio.newSource("assets/music/Daytime2Loop.wav", "stream")
        if Music.currentTrack then
            Music.currentTrack:setLooping(true)
            Music.currentTrack:setVolume(Music.volume)
            print("Music loaded successfully")
        else
            print("Failed to load music: currentTrack is nil")
        end
    end)
    
    if not success then
        print("Error loading music:", error)
    end
end

function Music.play()
    if Music.currentTrack then
        local success, error = pcall(function()
            Music.currentTrack:play()
            print("Music started playing")
        end)
        if not success then
            print("Error playing music:", error)
        end
    else
        print("Cannot play music: currentTrack is nil")
    end
end

function Music.stop()
    if Music.currentTrack then
        Music.currentTrack:stop()
    end
end

function Music.setVolume(volume)
    Music.volume = volume
    if Music.currentTrack then
        Music.currentTrack:setVolume(volume)
    end
end

return Music 