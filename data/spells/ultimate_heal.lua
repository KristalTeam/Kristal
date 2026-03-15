local spell, super = Class(Spell, "ultimate_heal")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "UltimatHeal"
    -- Name displayed when cast (optional)
    self.cast_name = nil

    -- Battle description
    self.effect = "Best\nhealing"
    -- Menu description
    self.description = "Heals 1 party member to the\nbest of %s's ability."

    -- TP cost
    self.cost = 100

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"

    -- Tags that apply to this spell
    self.tags = {"heal"}
end

function spell:getName()
    if Game.chapter == 3 then
        return "UltraHeal"
    elseif Game.chapter >= 4 then
        return "BetterHeal"
    end
    return super.getName(self)
end

function spell:getCastName()
    if self:getName() == "UltimatHeal" then
        return "ULTIMATEHEAL"
    elseif self:getName() == "BetterHeal" then
        return "BetterHeal"
    end
    return super.getCastName(self)
end

function spell:getDescription()
    if Game.chapter == 3 then
        return "An awesome healing spell.\n... right?"
    elseif Game.chapter >= 4 then
        return "A healing spell that has grown\nwith practice and confidence."
    end
    return string.format(super.getDescription(self), self.chara:getName())
end

function spell:getBattleDescription()
    if Game.chapter >= 4 then
        return "Heal\nally"
    end
    return super.getBattleDescription(self)
end

function spell:getTPCost(chara)
    if Game.chapter == 3 then
        return 90 - math.min(chara:getFlag("ultimateheals_used", 0), 5)
    elseif Game.chapter >= 4 then
        return 80 - math.ceil(math.min(chara:getFlag("ultimateheals_used", 0), 15) / 3)
    end
    return super.getTPCost(self, chara)
end

function spell:onCast(user, target)
    user.chara:addFlag("ultimateheals_used", 1)

    local base_heal = user.chara:getStat("magic") + 1
    if Game.chapter == 3 then
        base_heal = math.ceil((user.chara:getStat("magic") * 1.5) + 5 + math.min(user.chara:getFlag("ultimateheals_used", 0), 5))
    elseif Game.chapter >= 4 then
        base_heal = math.ceil((user.chara:getStat("magic") * 7) + 15 + (2 * math.min(user.chara:getFlag("ultimateheals_used", 0), 15)))
    end
    local heal_amount = Game.battle:applyHealBonuses(base_heal, user.chara)

    target:heal(heal_amount)
end

return spell
