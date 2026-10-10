local spell, super = Class(Spell, "ok_heal")

function spell:init()
    super.init(self)

    -- Display name
    if Game.chapter <= 4 then
        self.name = "OKHeal"
    else
        self.name = "Heal"
    end
    -- Name displayed when cast (optional)
    self.cast_name = nil

    -- Battle description
    if Game.chapter <= 4 then
        self.effect = "OK\nhealing"
    else
        self.effect = "Heal\nally"
    end
    -- Menu description
    if Game.chapter <= 4 then
        self.description = "It's not the best healing spell, but\nit may have its uses."
    else
        self.description = "A healing spell that has grown\nwith practice and confidence."
    end

    -- TP cost
    self.cost = 85

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"

    -- Tags that apply to this spell
    self.tags = { "heal" }
end

function spell:getTPCost(chara)
    local cost = super.getTPCost(self, chara)

    local healing_used = chara:getFlag("healing_used", 0)
    cost = cost - math.floor(healing_used / 3)

    return cost
end

function spell:onCast(user, target)
    local healing_used = user.chara:getFlag("healing_used", 0)

    if healing_used < 15 then
        healing_used = healing_used + 1
        user.chara:setFlag("healing_used", healing_used)
    end

    local _, yellowhat_count = user.chara:checkArmor("yellowhat")

    -- Base heal amount
    local base_heal = (user.chara:getStat("magic") * 5) + 15
    -- Apply YellowHat bonus
    -- DIFFERENCE: In DELTARUNE, this does not stack, as you cannot have multiple equipped.
    base_heal = base_heal + ((base_heal * 0.2) * yellowhat_count)
    -- Scale heal based on times used
    base_heal = base_heal + (2 * healing_used)

    local heal_amount = math.ceil(Game.battle:applyHealBonuses(base_heal, user.chara, target.chara))

    -- Hidden Chapter 5 mechanic
    -- The spell restores extra hp if the target's health is below 0
    if Game.chapter >= 5 and target.chara:getHealth() < 0 then
        local bonus_heal = heal_amount
        local bonus_heal2 = heal_amount
        if bonus_heal + bonus_heal2 < 1 then
            heal_amount = bonus_heal + bonus_heal2
        else
            bonus_heal2 = 0
            for i = 1, heal_amount do
                if bonus_heal + bonus_heal2 + target.chara:getHealth() > 0 then
                    break
                end
                if bonus_heal2 >= heal_amount then
                    break
                end
                bonus_heal2 = bonus_heal2 + 1
            end
            heal_amount = bonus_heal + bonus_heal2
        end
    end

    target:heal(heal_amount)
end

return spell
