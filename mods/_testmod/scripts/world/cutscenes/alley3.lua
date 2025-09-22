return {
    puzzle_fail = function(cutscene, event)
        cutscene:wait(0.5)

        cutscene:text("* [wait:5].[wait:5].[wait:5].[wait:5]")
        cutscene:text("* Nothing happened.")
    end,

    starwalker_disable = function(cutscene, event)
        if Game:getFlag("alley3_enable_forcefield") then
            cutscene:setSpeaker("starwalker")
            cutscene:text("* This [color:yellow]forcefield[color:reset] is [color:yellow]Pissing[color:reset] me off...")
            cutscene:wait(0.25)

            Game:setFlag("alley3_enable_forcefield", false)
            cutscene:shakeCamera(2)
            Assets.playSound("dtrans_flip")

            cutscene:wait(1)
            cutscene:text("* Not   [wait:5]anymore")
        else
            local alpha = event:addFX(AlphaFX())

            Game.stage.timer:tween(1, alpha, {alpha = 0})
            Assets.playSound("mysterygo")

            cutscene:wait(2)

            Game:setFlag("alley3_enable_starwalker", false)
        end
        cutscene:look("down")
    end
}
