local Encounter = Class()

function Encounter:addEnemy(enemy, x, y, ...)
    local enemy_obj
    if type(enemy) == "string" then
        enemy_obj = Registry.createEnemy(enemy, ...)
    else
        enemy_obj = enemy
    end
    if x and y then
        enemy_obj:setPosition(x, y)
    else
        for _,enemy in ipairs(Game.battle.enemies) do
            enemy.x = enemy.x - 10
            enemy.y = enemy.y - 45
        end
        enemy_obj:setPosition(550 + (10 * #Game.battle.enemies), 200 + (45 * #Game.battle.enemies))
    end
    table.insert(Game.battle.enemies, enemy_obj)
    Game.battle:addChild(enemy_obj)
end

return Encounter