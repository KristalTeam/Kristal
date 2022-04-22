function Mod:init()
    print("Loaded example mod!")
end

function Mod:onKeyPressed(key)
    if Kristal.Config["debug"] then
        if not Game.lock_input then
            if key == "p" then
                Game.world.player:shake(4, 0)
            end
        end
    end
end