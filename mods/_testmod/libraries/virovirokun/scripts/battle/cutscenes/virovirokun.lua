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
        enemy:hurt(enemy.health * 0.75, battler)
        cutscene:text("* She forgot to poke holes in it![wait:5]\nThe hot dog exploded!")
        -- Note: the following isn't part of the original act, it's here for testing battle cutscenes!
        cutscene:enemyText(enemy, "Dumbass")
        cutscene:gotoCutscene("virovirokun", "sussy", enemy)
        cutscene:text("* I,[wait:5] uh,[wait:5] meant to do that.[face:1]", "nervous", "susie", {faces={
            {"ralsei", "pleased", "rightmid", "bottommid", "It's OK, Susie..."}
        }})
    end,

    sussy = function(cutscene, enemy)
        local text = {"* SUSSY", "* SUS", "* IMPOSTOR", "* AMONG US"}
        for i = 1, 15 do
            cutscene:text("[speed:2]"..Utils.pick(text), "teeth_b", "susie", {auto = true})
        end
        local wait = cutscene:enemyText(enemy, "Please shut up", {wait = false})
        local count = 0
        while not wait(cutscene) do
            count = count + 1
            cutscene:text("[speed:2]"..Utils.pick(text), "teeth_b", "susie", {auto = true})
            if count == 60 then
                for _,other in ipairs(Game.battle.enemies) do
                    if other ~= enemy then
                        wait = cutscene:enemyText(other, "Seriously shut up", {wait = false})
                    end
                end
            end
        end
    end,
}