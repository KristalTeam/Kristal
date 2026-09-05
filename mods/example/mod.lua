function Mod:init()
    -- Create a logger for this project. Change the name!
    Mod.logger = Logger("Example Project", ConsoleFormats.GREEN)

    Game:registerEvent("mouseholeentry", function(data)
        return MouseholeEntry(data.x, data.y, { data.width, data.height })
    end)

    Game:registerEvent("climbshooter", function(data)
        -- timer_offset is a custom property! Let's read it here and pass it into our object.
        -- Same with shoot_speed.
        return ClimbShooter(data.x, data.y, { data.width, data.height }, data.properties.timer_offset, data.properties.shoot_speed)
    end)

    Mod.logger:info("Loaded " .. self.info.name .. "!")
end
