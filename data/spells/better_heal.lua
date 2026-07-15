local spell, super = Class(Spell, "better_heal")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "BetterHeal"
    -- Name displayed when cast (optional)

    if Game.chapter == 4 then
        self.cast_name = "BetterHeal"
    else
        self.cast_name = "BETTERHEAL"
    end

    -- Battle description
    self.effect = "Heal\nally"
    -- Menu description
    self.description = "A healing spell that has grown\nwith practice and confidence."

    -- TP cost
    self.cost = 80

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
    local base_heal = (user.chara:getStat("magic") * 7) + 15
    -- Apply YellowHat bonus
    -- DIFFERENCE: In DELTARUNE, this does not stack, as you cannot have multiple equipped.
    base_heal = base_heal + ((base_heal * 0.2) * yellowhat_count)
    -- Scale heal based on times used
    base_heal = base_heal + (2 * healing_used)

    local heal_amount = math.ceil(Game.battle:applyHealBonuses(base_heal, user.chara, target.chara))

    target:heal(heal_amount)
end

return spell
