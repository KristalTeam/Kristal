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
    Cutscene.text("* Kris, Susie, look out!!!", "ralsei/spr_face_r_nohat_23", {x=-15, y=-10})

    Cutscene.setSprite(susie, "world/dark/shock_r")
    Cutscene.slideTo(susie, susie.x - 40, susie.y, 8)
    Cutscene.slideTo(ralsei, kris.x, kris.y, 12)
    Cutscene.wait(0.2)
    Cutscene.slideTo(kris, kris.x - 40, kris.y, 8)
    Cutscene.wait(0.3)

    ralsei:explode()

    Cutscene.wait(2)
    Cutscene.panTo("entry_down")
    Cutscene.text("* ", "susie/spr_face_susie_alt_15", {x=-5, y=0})

    Cutscene.wait(2)
    Cutscene.setSprite(susie, "world/dark")
    Cutscene.attachFollowers(true)
    Cutscene.attachCamera()
else
    Cutscene.text("* ", "susie/spr_face_susie_alt_15", {x=-5, y=0})
end