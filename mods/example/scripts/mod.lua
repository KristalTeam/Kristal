function Init()
    print("Loaded example mod!")
end

function KeyPressed(key)
    if key == "e" and Game.world.player then
        Game.world.player:explode(0, -40)
        Game.world.player = nil
        return true
    end
end