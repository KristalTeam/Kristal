function Mod:init()
    print("Loaded " .. self.info.name .. "!")

    Game:registerEvent("squeak", function(data)
        return Squeak(data.x, data.y, { data.width, data.height })
    end)
end
