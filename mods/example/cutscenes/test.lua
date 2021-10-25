Cutscene.text("* The power of [color:pink]test dialogue[color:reset]\nshines within you.")
Cutscene.wait(0.5)
Cutscene.text("* Oh    [color:red]Fuck[color:reset]   it's a  bomb", nil, {auto = true})

if Game.world.player then
    Game.world.player:explode()
end