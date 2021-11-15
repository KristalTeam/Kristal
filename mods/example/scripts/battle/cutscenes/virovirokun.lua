return {
    cook_ralsei = function(cutscene)
        for _,battler in ipairs(Game.battle.party) do
            battler:heal(30)
        end
        cutscene:text("* Ralsei cooked up a cure.")
        cutscene:text("* If you're sick, shouldn't\nyou have some soup?\nSay \"aah\"~!", "face_17", "ralsei")
        cutscene:text("* Sickness was cured! Everyone's\nHP up!")
    end,

    cook_susie = function(cutscene, battler, enemy)
        cutscene:text("* Susie cooked up a cure!")
        cutscene:text("* What, you want me to cook\nsomething?", "face_2", "susie")
        cutscene:text("* Susie put a hot dog in the\nmicrowave!")
        enemy:explode(0, 0, true)
        enemy:hurt(enemy.health * 0.75, battler)
        cutscene:text("* She forgot to poke holes in it!\nThe hot dog exploded!")
        -- Note: the following isn't part of the original act, it's here for testing battle cutscenes!
        cutscene:enemyText(enemy, "Dumbass")
        cutscene:gotoCutscene("virovirokun", "sussy")
        cutscene:text("* I, uh, meant to do that.", "face_3", "susie")
    end,

    sussy = function(cutscene)
        local text = {"* SUSSY", "* SUS", "* IMPOSTOR", "* AMONG US"}
        for i = 1, 15 do
            cutscene:text("[speed:2]"..Utils.pick(text), "face_17", "susie", {auto = true})
        end
    end,
}