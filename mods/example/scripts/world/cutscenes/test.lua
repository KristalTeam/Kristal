return function(cutscene)

    local kris = cutscene:getCharacter("kris")
    local susie = cutscene:getCharacter("susie")
    local ralsei = cutscene:getCharacter("ralsei")

    if ralsei then
        cutscene:text("* The power of [color:pink]test\ndialogue[color:reset] shines within\nyou.", "starwalker")
        cutscene:wait(0.5)
        cutscene:text("* Oh    [color:red]Fuck[color:reset]   it's a  bomb")

        cutscene:detachCamera()
        cutscene:detachFollowers()

        cutscene:setSprite(ralsei, "up", 1/15)
        cutscene:setSpeaker("ralsei")
        cutscene:text("* Kris, Susie, look out!!!", "face_23")

        susie.sprite:set("shock_r")
        --Cutscene.setSprite(susie, "world/dark/shock_r")
        cutscene:wait(cutscene:slideTo(ralsei, susie.x, susie.y, 12))
        cutscene:slideTo(susie, susie.x - 40, susie.y, 8)
        cutscene:wait(cutscene:slideTo(ralsei, kris.x, kris.y, 12))
        cutscene:look(kris, "right")
        cutscene:wait(cutscene:slideTo(kris, kris.x - 40, kris.y, 8))
        ralsei:explode()
        cutscene:shakeCamera(8)

        cutscene:wait(2)
        cutscene:text("* Yo what the fuck", "face_15", "susie")

        cutscene:wait(2)
        cutscene:setSprite(susie, "")

        cutscene:alignFollowers("up")
        cutscene:attachFollowers()
        cutscene:attachCamera()
    else
        cutscene:text("", "face_15", "susie")
    end

end