local Vironeedle, super = Class(Wave)

function Vironeedle:onStart()
    --self.timer:every((ratio == 1 and 6 or (10 * ratio)) / 30, function()
    self.timer:every(1 / 30, function()
        local arena = Game.battle.arena

        local x, y = arena.right + 40 + Utils.random(140), Utils.random(arena.top, arena.bottom)
        self:spawnBullet("virovirokun/needle", x, y, false)

        x, y = arena.left - 40 - Utils.random(140), Utils.random(arena.top, arena.bottom)
        self:spawnBullet("virovirokun/needle", x, y, false, true)

        x, y = Utils.random(arena.left, arena.right), arena.top - 40 - Utils.random(140)
        local bullet = self:spawnBullet("virovirokun/needle", x, y, false)
        bullet.rotation = math.pi/2

        x, y = Utils.random(arena.left, arena.right), arena.bottom + 40 + Utils.random(140)
        bullet = self:spawnBullet("virovirokun/needle", x, y, false)
        bullet.rotation = -math.pi/2
    end)
end

function Vironeedle:update()
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

return Vironeedle
