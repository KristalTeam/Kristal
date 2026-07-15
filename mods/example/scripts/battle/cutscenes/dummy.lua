return {
    susie_punch = function(cutscene, battler, enemy)
        -- Open textbox and wait for completion
        cutscene:text("* Susie threw a punch at\nthe dummy.")

        -- Hurt the target enemy for 1 damage
        Assets.playSound("damage")
        enemy:hurt(1, battler)
        -- Wait 1 second
        cutscene:wait(1)

        --If the enemy's health reaches zero, Susie will react to it
        if enemy.health < 1 then
            cutscene:text("* Oh $#&*!", "surprise_frown", "susie")

        else
            --Since the enemy's health isn't zero, do the normal scene
            cutscene:text("* You,[wait:5] uh,[wait:5] look like a weenie.[wait:5]\n* I don't like beating up\npeople like that.", "nervous_side", "susie")

            if cutscene:getCharacter("ralsei") then
                -- Ralsei text, if he's in the party
                cutscene:text("* Aww,[wait:5] Susie!", "blush_pleased", "ralsei")
            end
        end
    end
}