local spell, super = Class(Spell, "ultimate_heal")

function spell:init(chara, style)
    super.init(self, chara)
    
    -- Display name
    self.name = "UltimatHeal"
    -- Name displayed when cast (optional)
    self.cast_name = "ULTIMATEHEAL"

    -- Battle description
    self.effect = "Best\nhealing"
    -- Menu description
    self.description = string.format("Heals 1 party member to the\nbest of %s's ability.", chara:getName())

    -- TP cost
    self.cost = 100
    
    -- The amount of TP cost that gets reduced with each cast
    self.usage_cost_reduction = 0
    
    -- The maximum amount of times the spell will get better stats with each cast
    self.usage_bonus_limit = 0
    
    -- Spell style
    self.style = style
    if self.style == "ultra_heal" then
        self.name = "UltraHeal"
        self.cast_name = nil
        self.description = "An awesome healing spell.\n... right?"
        self.cost = 90
        self.usage_cost_reduction = 1
        self.usage_bonus_limit = 5
    elseif self.style == "ok_heal" then
        self.name = "OKHeal"
        self.cast_name = nil
        self.effect = "OK\nhealing"
        self.description = "It's not the best healing spell, but\nit may have its uses."
        self.cost = 85
        self.usage_cost_reduction = 1 / 3
        self.usage_bonus_limit = 15
    elseif self.style == "better_heal" then
        self.name = "BetterHeal"
        self.cast_name = "BetterHeal"
        self.effect = "Heal\nally"
        self.description = "A healing spell that has grown\nwith practice and confidence."
        self.cost = 80
        self.usage_cost_reduction = 1 / 3
        self.usage_bonus_limit = 15
    end

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"

    -- Tags that apply to this spell
    self.tags = {"heal"}
end

function spell:getTPCost(chara)
    return super.getTPCost(self, chara) - math.ceil(math.min(chara:getFlag("ultimateheals_used", 0), self.usage_bonus_limit) * self.usage_cost_reduction)
end

function spell:onCast(user, target)
    user.chara:addFlag("ultimateheals_used", 1)

    local base_heal = user.chara:getStat("magic") + 1
    if self.style == "ultra_heal" then
        base_heal = math.ceil((user.chara:getStat("magic") * 1.5) + 5 + (1 * math.min(user.chara:getFlag("ultimateheals_used", 0), self.usage_bonus_limit)))
    elseif self.style == "ok_heal" then
        base_heal = math.ceil((user.chara:getStat("magic") * 5) + 15 + (2 * math.min(user.chara:getFlag("ultimateheals_used", 0), self.usage_bonus_limit)))
    elseif self.style == "better_heal" then
        base_heal = math.ceil((user.chara:getStat("magic") * 7) + 15 + (2 * math.min(user.chara:getFlag("ultimateheals_used", 0), self.usage_bonus_limit)))
    end
    local heal_amount = Game.battle:applyHealBonuses(base_heal, user.chara)

    target:heal(heal_amount)
end

return spell
