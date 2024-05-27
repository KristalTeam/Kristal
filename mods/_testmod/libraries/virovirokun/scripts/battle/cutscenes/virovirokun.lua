return {
    cook_ralsei = function(cutscene)
        for _,battler in ipairs(Game.battle.party) do
            battler:heal(30)
        end
        cutscene:text("* Ralsei cooked up a cure.")
        cutscene:text("* If you're sick,[wait:5] shouldn't\nyou have some soup?[wait:5]\nSay \"aah\"~!", "blush_pleased", "ralsei")
        cutscene:text("* Sickness was cured![wait:5] Everyone's\nHP up!")
    end,

    cook_susie = function(cutscene, battler, enemy)
        cutscene:text("* Susie cooked up a cure!")
        cutscene:text("* What,[wait:5] you want me to cook\nsomething?", "smile", "susie")
        cutscene:text("* Susie put a hot dog in the\nmicrowave!")
        enemy:explode(0, 0, true)
        enemy:hurt(enemy.health * 0.75, Game.battle:getPartyBattler("susie"))
        cutscene:text("* She forgot to poke holes in it![wait:5]\nThe hot dog exploded!")
    end
}