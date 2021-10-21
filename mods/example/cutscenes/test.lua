local text = DialogueText("* The power of [color:pink]test dialogue[color:reset] shines\nwithin you.")
Game.stage:addChild(text)
Cutscene:wait(3)
text:setText("* Oh    [color:red]Fuck[color:reset]   it's a  bomb")
Cutscene:wait(2)
text:Remove()

if Game.world.player then
    Game.world.player:explode()
end