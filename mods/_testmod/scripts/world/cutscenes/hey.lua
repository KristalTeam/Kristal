return {
    face = function(cutscene)
        cutscene:setSpeaker("susie")
        cutscene:text("* Hey Kris Hey", "small_smile")
        cutscene:text("* I just learned how to\nchange my face mid\nsentence", "smile")
        cutscene:text("* Watch this", "closed_grin")
        cutscene:text("* hhooooOOOOOOOOAAAAAAAA\nAAAAAAAAAAAAAAAAA[facec:ralsei_hat/angry,-15,-10][voice:ralsei]AAAAA\nAAAAAAAAAAAAAAGGHHH", "teeth_b")
        cutscene:wait(2)
        cutscene:text("* Ok but for real here's\nthe [face:teeth_b]\\[face\\] command", "smile")
    end,

    fade = function(cutscene)
        cutscene:wait(0.2)
        cutscene:fadeOut(0.5, {music = true})
        cutscene:wait(0.5)
        cutscene:text("Who knows what happened here[wait:2].[wait:2].[wait:2].[wait:2]\n.[wait:2].[wait:2].[wait:2].[wait:2].[wait:2].[wait:2].[wait:2].[wait:2].[wait:2] it could be[wait:10]\n  anything")
        cutscene:wait(0.5)
        cutscene:fadeIn(0.5, {music = true, wait = true})

        cutscene:wait(1)

        cutscene:fadeOut(2, {color = {1, 1, 1}, music = 1, global = true, wait = false})
        cutscene:text("Wait no why are you white noooo\nooooooooooooooooooooooooo\noooooooooooooooo", {wait = false, advance = false})
        cutscene:wait(2)
        cutscene:closeText()
        cutscene:fadeIn(0.2, {global = true})
        cutscene:startEncounter("starwalker", false)
    end
}