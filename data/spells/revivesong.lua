local spell, super = Class(Spell, "revivesong")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "ReviveSong"
    -- Name displayed when cast (optional)
    self.cast_name = nil

    -- Battle description
    self.effect = "Revive\nally"

    -- Menu description
    self.description = "Revives a DOWNed ally and heals them.\nOtherwise, heals a lot of HP."

    -- TP cost
    self.cost = 84

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"

    -- Tags that apply to this spell
    self.tags = { "heal" }

    self.select_anim = "sing_ready"

    self.cast_anim = "sing_ready"
end

function spell:onCast(user, target)
    user:setAnimation("sing")

    local _, yellowhat_count = user.chara:checkArmor("yellowhat")

    local health = target.chara:getHealth()

    local base_heal = 0

    if health <= 0 then
        base_heal = (-health) + user.chara:getStat("magic") * (7.5 + (1.5 * yellowhat_count))
    else
        base_heal = user.chara:getStat("magic") * (10 + (2 * yellowhat_count))
    end

    local heal_amount = math.ceil(Game.battle:applyHealBonuses(base_heal, user.chara, target.chara))

    Game.battle:addChild(ReviveSongEffect(target.x, target.y, target, {
        on_finish_func = function()
            target:heal(heal_amount)
        end
    }))

    Game.battle.timer:after(75 / 30, function()
        Game.battle:finishAction()
    end)

    -- Don't manually finish the action, we wanna do it ourselves
    return false
end

return spell
