function Mod:init()
    -- Create a logger for this project. Change the name!
    Mod.logger = Logger("My Project", ConsoleFormats.GREEN)

    -- Register a custom Tiled event.
    Game:registerEvent("squeak", function(data)
        return Squeak(data.x, data.y, {data.width, data.height, data.polygon})
    end)

    Mod.logger:info("Loaded " .. self.info.name .. "!")
end
