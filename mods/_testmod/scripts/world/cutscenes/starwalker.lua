return function(cutscene)
    cutscene:text("* These [color:yellow]bananas[color:reset] are [color:yellow]Pissing[color:reset] me\noff...")
    cutscene:text("* I'm the original   [color:yellow]Starwalker[color:reset][react:1][wait:5][react:2][wait:5][react:3][wait:5][react:sussy]", {reactions={
        {"susie", "surprise", "left", "bottom", "BottomLeft"},
        {"ralsei", "blush", "right", "top", "RightTop"},
        {"noelle", "smile", "mid", "mid", "MidMid"},
        sussy = {"susie", "surprise", "right", "bottommid", "Right BottomMid"},
    }})
    cutscene:wait(0.25)
    Assets.playSound("snd_save")
    cutscene:wait(0.5)
    Game:saveQuick(Game.world.player:getExactPosition())
    cutscene:text("* (The original   [color:yellow]Starwalker[color:reset]      \n   somehow saved your game...)")
end