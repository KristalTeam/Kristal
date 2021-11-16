local spell = Spell{
    -- Spell ID (optional, defaults to path)
    id = "ice_shock",
    -- Display name
    name = "IceShock",

    -- Battle description
    effect = "Damage\nw/ ICE",
    -- Menu description
    description = "Deals magical ICE damage to\none enemy.",

    -- TP cost
    cost = 16,

    -- Target mode (party, enemy, or none/nil)
    target = "enemy",
}

function spell:onCast(user, target)
    local function createParticle(x, y)
        local sprite = Sprite("effects/icespell/snowflake", x, y)
        sprite:setOrigin(0.5, 0.5)
        sprite:setScale(1.5)
        sprite.layer = LAYERS["above_battlers"]
        Game.battle:addChild(sprite)
        return sprite
    end

    local x, y = target:getRelativePos(target.width/2, target.height/2, Game.battle)

    local particles = {}
    Game.battle.timer:script(function(wait)
        wait(1/30)
        Assets.playSound("snd_icespell")
        particles[1] = createParticle(x-25, y-20)
        wait(3/30)
        particles[2] = createParticle(x+25, y-20)
        wait(3/30)
        particles[3] = createParticle(x, y+20)
        wait(3/30)
        Game.battle:addChild(IceSpellBurst(x, y))
        for _,particle in ipairs(particles) do
            for i = 0, 5 do
                local effect = IceSpellEffect(particle.x, particle.y)
                effect:setScale(0.75)
                effect.physics.direction = math.rad(60 * i)
                effect.physics.speed = 8
                effect.physics.friction = 0.2
                effect.layer = LAYERS["above_battlers"] - 1
                Game.battle:addChild(effect)
            end
        end
        wait(1/30)
        for _,particle in ipairs(particles) do
            particle:remove()
        end
        wait(4/30)

        local min_magic = Utils.clamp(user.chara:getStat("magic") - 10, 1, 999)
        local damage = math.ceil((min_magic * 30) + 90 + Utils.random(10))
        target:hurt(damage, user, function() target:freeze() end)

        Game.battle:finishActionBy(user)
    end)

    return false
end

return spell