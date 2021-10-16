local text1 = DialogueText("* The power of [color:pink]test dialogue[color:reset] shines\nwithin you.")
Game.stage:addChild(text1)
Cutscene:wait(3)
for _,char in ipairs(text1.chars) do
    char:remove()
end
local text2 = DialogueText("* Oh    [color:red]Fuck[color:reset]   it's a  bomb")
Game.stage:addChild(text2)
Cutscene:wait(2)
for _,char in ipairs(text2.chars) do
    char:remove()
end
if Game.world.player then
    Game.world.player:explode()
end