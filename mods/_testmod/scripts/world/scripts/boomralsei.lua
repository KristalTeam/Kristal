return function()
    local ralsei = Game.world:getCharacter("ralsei")
    if ralsei then
        ralsei:explode()
    end
end
