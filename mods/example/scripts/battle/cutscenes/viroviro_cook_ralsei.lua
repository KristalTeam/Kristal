for _,battler in ipairs(Game.battle.party) do
    battler:heal(30)
end
BattleScene.text("* Ralsei cooked up a cure.")
BattleScene.text("* If you're sick, shouldn't\nyou have some soup?\nSay \"aah\"~!", "face_17", "ralsei")
BattleScene.text("* Sickness was cured! Everyone's\nHP up!")