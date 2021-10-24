local HealPrayer = Class(Spell)

function HealPrayer:init()
    -- Spell ID (optional, defaults to path)
    self.id = "heal_prayer"
    -- Display name
    self.name = "Heal Prayer"

    -- Battle description
    self.effect = "Heal\nAlly"
    -- Menu description
    self.description = "Heavenly light restores a little HP to\none party member. Depends on Magic."

    -- TP cost (default tp max is 250)
    self.cost = 80

    -- How long it takes the spell to cast
    self.delay = 0.25

    -- Target mode (party, enemy, or none/nil)
    self.target = "party"
end

function HealPrayer:onCast(user, target)
    target:heal(love.math.random(100))
    Game.battle:finishSpell()
end

return HealPrayer