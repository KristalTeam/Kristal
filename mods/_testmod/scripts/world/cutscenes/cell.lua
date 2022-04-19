return {
    home = function(cutscene)
        cutscene:text("* (Ring...)")
        if Game.world:getCellFlag("cell.home", 0) > 0 then
            cutscene:text("* (No one picked up.)")
        else
            cutscene:setSpeaker("susie")
            cutscene:text("* Dreemurr residence,[wait:5]\nwho is this?", "smile")
            cutscene:text("* .[wait:5].[wait:5].[wait:5]Kris?!", "shock_down")
            cutscene:setSpeaker()
            cutscene:text("* (Susie quickly hangs up.)")
        end
    end,
}