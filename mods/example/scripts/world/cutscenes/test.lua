local kris = Cutscene.getCharacter("kris")
local susie = Cutscene.getCharacter("susie")
local ralsei = Cutscene.getCharacter("ralsei")

if ralsei then
    Cutscene.text("* The power of [color:pink]test\ndialogue[color:reset] shines within\nyou.", "starwalker")
    Cutscene.wait(0.5)
    Cutscene.text("* Oh    [color:red]Fuck[color:reset]   it's a  bomb")

    Cutscene.detachCamera()
    Cutscene.detachFollowers()

    Cutscene.setSprite(ralsei, "world/dark/up", 1/15)
    Cutscene.setSpeaker("ralsei")
    Cutscene.text("* Kris, Susie, look out!!!", "face_23")

    Cutscene.setSprite(susie, "world/dark/shock_r")
    Cutscene.slideTo(susie, susie.x - 40, susie.y, 8)
    Cutscene.slideTo(ralsei, kris.x, kris.y, 12)
    Cutscene.wait(0.2)
    Cutscene.slideTo(kris, kris.x - 40, kris.y, 8)
    Cutscene.wait(0.3)

    ralsei:explode()

    Cutscene.wait(2)
    Cutscene.text("* Yo what the fuck", "face_15", "susie")

    Cutscene.wait(2)
    Cutscene.setSprite(susie, "world/dark")
    Cutscene.attachFollowers(true)
    Cutscene.attachCamera()
else
    Cutscene.text("", "face_15", "susie")
end