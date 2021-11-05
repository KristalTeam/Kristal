local Vironeedle, super = Class(Wave)

function Vironeedle:onStart()
    local attackers = self:getAttackers()

    local ratio = self:getEnemyRatio()

    self.timer:every((ratio == 1 and 6 or (10 * ratio)) / 30, function()
        local arena = Game.battle.arena

        local x, y = arena.right + 40 + Utils.random(140), Utils.random(arena.top, arena.bottom)
        self:spawnBullet("vironeedle", x, y, #attackers > 1)

        if #attackers > 1 then
            x, y = arena.left - 40 - Utils.random(140), Utils.random(arena.top, arena.bottom)
            self:spawnBullet("vironeedle", x, y, true, true)
        end
    end)
end

function Vironeedle:update(dt)
    super:update(self, dt)

    Object.startCache()
    local infected = {}
    for _,needle in ipairs(self.bullets) do
        if needle.collidable and needle:isBullet("vironeedle") then
            for _,bullet in ipairs(Game.stage:getObjects(Bullet)) do
                if not bullet:isBullet("virovirus") and (not bullet:isBullet("vironeedle") or bullet:getDirection() ~= needle:getDirection()) then
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
