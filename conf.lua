function love.conf(t)
    -- If you intend to create a standalone game from this engine, make sure to also:
    -- * Change "identity", "window.title" here
    -- * Replace icon.png, bigicon.png with your own
    -- * (If you wish to create a Windows executable) replace icon.ico
    --   and recompile icon.rc with rc or windres
    --
    -- This is to:
    -- * Make sure user settings for the actual engine is not loaded;
    -- * Make sure the name and icon of the game is correctly presented during startup.
    --   (We can only automatically adjust window branding when loading finishes.)

    local major, minor, revision, codename = love.getVersion()

    t.identity = "kristal"
    -- TODO: hmm
    t.version = "11.0"

    t.window.title = "Kristal"
    t.window.icon = "icon.png"
    t.window.width = 640
    t.window.height = 480

    if major >= 12 then
        t.highdpi = true
        t.usedpiscale = false
    else
        t.window.highdpi = true
        t.window.usedpiscale = false
    end
	
	t.externalstorage = true
end