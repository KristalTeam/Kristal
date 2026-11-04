---@return table<WorldCutsceneFunc>
return {
    ---@type WorldCutsceneFunc
    lauren_chooser = function(cutscene)
        local lauren = cutscene:getCharacter("lauren")
        if not lauren then
            return
        end
        local cutscene_to_start = "lauren_end"
        local interact_count = Game:getFlag("lauren_interacted", 0)
        if interact_count < 1 then
            cutscene_to_start = "lauren_first"
        elseif interact_count < 2 then
            cutscene_to_start = "lauren_second"
        elseif interact_count < 3 then
            cutscene_to_start = "lauren_third"
        end
        Game:addFlag("lauren_interacted",1)
        lauren:setSprite("talk")
        cutscene:gotoCutscene("climbing." .. cutscene_to_start, lauren)
    end,
    ---@type WorldCutsceneFunc
    lauren_first = function(cutscene, lauren)
        if lauren then
            cutscene:setSpeaker(lauren)
            cutscene:text("* yeah im lauren")
            cutscene:text("* lauren ip. some")
            lauren:setSprite("bounce")
            cutscene:text("* you can call me lauren")
            cutscene:wait(1)
            lauren:setSprite("talk")
            cutscene:text("* [wait:4]ip.[wait:5] some")
            lauren:setSprite("idle")
        end
    end,
    ---@type WorldCutsceneFunc
    lauren_second = function(cutscene, lauren)
        if lauren then
            cutscene:setSpeaker(lauren)
            lauren:setSprite("look_up")
            cutscene:text("* thats a [wave:1]pre[wait:2]tty[wave:0] tall wall")
            cutscene:text("* climbing sounds like \n* it would be[wait:4] kinda hard")
            cutscene:wait(2)
            lauren:setSprite("talk")
            cutscene:text("* [wave:1]glad im not doing that~")
            lauren:setSprite("idle")
        end
    end,
    ---@type WorldCutsceneFunc
    lauren_third = function(cutscene, lauren)
        if lauren then
            cutscene:setSpeaker(lauren)
            cutscene:text("* my job is to show off 'example dialogue'")
            cutscene:text("* im not actually that good at it[wait:5]\n* i dunno what '[color:yellow]punctuation[color:reset]' is")
            cutscene:text("* [font:main,16]good thing my boss doesnt know that")
            lauren:setSprite("idle")
        end
    end,
    ---@type WorldCutsceneFunc
    lauren_end = function(cutscene, lauren)
        if lauren then
            cutscene:setSpeaker(lauren)
            cutscene:text("* im outta new lines sorry")
            lauren:setSprite("idle")
        end
    end
}