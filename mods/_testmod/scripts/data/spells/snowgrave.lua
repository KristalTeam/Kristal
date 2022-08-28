local spell, super = Class("snowgrave", true)

function spell:onSelect(user, target)
    Game:addFlag("snowgrave_attempts", 1)
    local attempts = Game:getFlag("snowgrave_attempts", 0)
    if attempts == 1 then
        Game.battle:startCutscene(function(cutscene)
            cutscene:setSpeaker(user.actor)
            cutscene:text("* S...[wait:2] Snowgrave?", "sad_side")
            cutscene:text("* I...[wait:2] I don't know that spell.", "down")
            cutscene:after(function()
                Game.battle:setState("ACTIONSELECT")
            end, true)
        end)
        return false
    elseif attempts == 2 then
        Game.battle:startCutscene(function(cutscene)
            cutscene:setSpeaker(user.actor)
            cutscene:text("* I'm telling you,[wait:2] I...[wait:2] I...", "down")
            cutscene:text("* I don't know what you're talking about.", "upset_down")
            local wait = cutscene:choicer({"Proceed", "Whoops wait\nyou're right\nmy bad"}, {wait = false})
            local choice
            local timer = 0
            while timer < 1 do
                local chosen, value = wait()
                if chosen then
                    choice = value
                    break
                end
                timer = timer + DT
                cutscene:wait()
            end
            cutscene:closeText()
            cutscene:text("Kris would you shut up", "smile")
            cutscene:after(function()
                Game.battle:setState("ACTIONSELECT")
            end, true)
        end)
        return false
    end
end

return spell