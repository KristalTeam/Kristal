local Invader, super = Class(Wave)

function Invader:onStart()
    local attackers = #self:getAttackers()
    local enemies = #Game.battle:getActiveEnemies()

    local y_offset = -5
    if attackers ~= enemies then
        y_offset = y_offset - 20
    end

    local side = love.math.random(3)
    local side_direction = love.math.random(2) == 1 and 1 or -1

    for i = 1, (enemies == 1 and 2 or 3) do
        local x = Game.battle.arena:getCenter()
        if attackers == 1 then
            x = x + ((Game.battle.arena.width / 2) - 10) * -side_direction
        end
        local fleet = self:spawnBullet("virovirokun/invader_fleet", x, Game.battle.arena:getTop() + y_offset, attackers, enemies, side_direction, attackers == enemies)
        if i == side then
            fleet.shot_timer = (attackers == enemies and 15 or 5)
        end
        side_direction = -side_direction
        y_offset = y_offset - (enemies == 1 and 40 or 20)
    end
end

return Invader
