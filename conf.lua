function love.conf(t)
    -- If you intend to create a standalone game from this engine, make sure
    -- to change "identity" and "window.title" to fit it.
    -- This is to:
    -- 1 - make sure user settings for the actual engine is not loaded;
    -- 2 - make sure the name of the game is correctly presented.

    t.identity = "kristal"
    -- TODO: hmm
    t.version = "11.0"

    t.window.title = "Kristal"
    t.window.icon = "icon.png"
    t.window.width = 640
    t.window.height = 480
end