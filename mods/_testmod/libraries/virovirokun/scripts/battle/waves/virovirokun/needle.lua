local Needle, super = Class(Wave)

function Needle:onStart()
    local attackers = self:getAttackers()

    local ratio = self:getEnemyRatio()

    self.timer:every((ratio == 1 and 6 or (10 * ratio)) / 30, function()
        local arena = Game.battle.arena

        local x, y = arena.right + 40 + Utils.random(140), Utils.random(arena.top, arena.bottom)
        self:spawnBullet("virovirokun/needle", x, y, #attackers > 1)

        if #attackers > 1 then
            x, y = arena.left - 40 - Utils.random(140), Utils.random(arena.top, arena.bottom)
            self:spawnBullet("virovirokun/needle", x, y, true, true)
        end
    end)
end

function Needle:update()
    super.update(self)

    Object.startCache()
    local infected = {}
    for _,needle in ipairs(self.bullets) do
        if needle.collidable and needle:isBullet("virovirokun/needle") then
            for _,bullet in ipairs(Game.stage:getObjects(Bullet)) do
                if not bullet:isBullet("virovirokun/virus") and (not bullet:isBullet("virovirokun/needle") or bullet:getDirection() ~= needle:getDirection()) then
                    if not infected[bullet] and bullet:collidesWith(needle.infect_collider) then
                        infected[bullet] = true
                        needle:infect(bullet)
                        break
                    end
                end
            end
        end
    end
    Object.endCache()
end

function Needle:getEnemyRatio()
    local enemies = #Game.battle:getActiveEnemies()
    if enemies <= 1 then
        return 1
    elseif enemies == 2 then
        return 1.6
    elseif enemies >= 3 then
        return 2.3
    end
end

return Needle
