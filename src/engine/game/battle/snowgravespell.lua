--- A special object used for the Snowgrave spell. \
--- Despite its name, this object is not the `Spell` used to trigger snowgrave - the snowgrave spell is instead a default spell in all mods under the id `snowgrave`. \
--- The spell file that calls is is found from Kristal's root at `data/spells/snowgrave.lua` - see here for how this object is used. 
---@class SnowGraveSpell : Object
---@overload fun(user:PartyBattler) : SnowGraveSpell
local SnowGraveSpell, super = Class(Object)

---@param user PartyBattler
function SnowGraveSpell:init(user)
    super.init(self, 0, 0)

    self.caster = user

    self.bgalpha = 0
    self.timer = 0
    self.snowspeed = 0
    self.stimer = 0
    self.damage = 0
    self.fncon = 0
    self.con = 0
    self.init = true
    self.siner = 0
    self.hurt = false

    self.since_last_snowflake = 0
    self.reset_once = true

    self.bg = Assets.getTexture("effects/icespell/gradient")

    self.bg_snowfall = Assets.getTexture("effects/icespell/snowfall")
    self.bg_snowfall:setWrap('repeat','repeat')
    self.bg_snowfall_quad = love.graphics.newQuad( 0, 0, 640, 480, self.bg_snowfall:getWidth(), self.bg_snowfall:getHeight())

    Assets.playSound("snowgrave", 0.5)

    self.hurt_enemies = false
end

function SnowGraveSpell:update()
    super.update(self)
    self.timer = self.timer + DTMULT
    self.since_last_snowflake = self.since_last_snowflake + DTMULT

    if self.hurt_enemies then
        self.hurt_enemies = false
        for i, enemy in ipairs(Game.battle.enemies) do
            if enemy then
                enemy.hit_count = 0
                enemy:hurt(self.damage + Utils.round(math.random(100)), self.caster, enemy.onDefeatFatal)
                if enemy.health > 0 then
                    enemy:flash()
                end
            end
        end
    end
end

function SnowGraveSpell:drawTiled(x, y, alpha)
    Draw.setColor(1, 1, 1, alpha)

    local width = (self.bg_snowfall:getWidth() * 2)
    local height = (self.bg_snowfall:getHeight() * 2)

    local cur_x = -(width  * math.ceil(x / width))
    local cur_y = -(height * math.ceil(y / height))

    while cur_y + y < 480 do
        while cur_x + x < 640 do
            Draw.draw(self.bg_snowfall, cur_x + x, cur_y + y, 0, 2, 2)
            cur_x = cur_x + width
        end
        cur_x = -(width * math.ceil(x / width))
        cur_y = cur_y + height
    end
end

function SnowGraveSpell:createSnowflake(x, y)
    local snowflake = SnowGraveSnowflake(x, y)
    snowflake.physics.gravity = -2
    snowflake.physics.speed_y = math.sin(self.timer / 2) * 0.5
    snowflake.siner = self.timer / 2
    self:addChild(snowflake)
    return snowflake
end

function SnowGraveSpell:draw()
    super.draw(self)

    Draw.setColor(1, 1, 1, self.bgalpha)
    Draw.draw(self.bg)

    self:drawTiled((self.snowspeed / 1.5), (self.timer * 6), self.bgalpha)
    self:drawTiled((self.snowspeed), (self.timer * 8), self.bgalpha * 2)

    if ((self.timer <= 10) and (self.timer >= 0)) then
        if (self.bgalpha < 0.5) then
            self.bgalpha = self.bgalpha + 0.05 * DTMULT
        end
    end

    if (self.timer >= 0) then
        self.snowspeed = self.snowspeed + (20 + (self.timer / 5)) * DTMULT
    end

    if ((self.timer >= 20) and (self.timer <= 75)) then
        self.stimer = self.stimer + 1 * DTMULT

        if self.reset_once then
            self.reset_once = false
            self.since_last_snowflake = 1
        end

        if self.since_last_snowflake > 1 then
            self:createSnowflake(455, 560)
            self:createSnowflake(500, 600)
            self:createSnowflake(545, 520)
            self.since_last_snowflake = self.since_last_snowflake - 1
        end

        if (self.stimer >= 8) then
            self.stimer = 0
        end
    end


    if ((not self.hurt) and ((self.timer >= 95) and (self.damage > 0))) then
        self.hurt = true
        self.hurt_enemies = true
    end

    if (self.timer >= 90) then
        if (self.bgalpha > 0) then
            self.bgalpha = self.bgalpha - 0.02 * DTMULT
        end
    end
    if (self.timer >= 120) then
        Game.battle:finishAction()
        self:remove()
    end
end

return SnowGraveSpell