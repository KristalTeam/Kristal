local UltimateHeal = Class(Spell)

function UltimateHeal:init()
    -- Spell ID (optional, defaults to path)
    self.id = "ultimate_heal"
    -- Display name
    self.name = "UltimatHeal"

    -- Battle description
    self.effect = "Best\nhealing"
    -- Menu description
    self.description = "Heals 1 party member to the\nbest of Susie's ability."

    -- TP cost (default tp max is 250)
    self.cost = 250

    -- How long it takes the spell to cast
    self.delay = 0.25

    -- Target mode (party, enemy, or none/nil)
    self.target = "party"
end

return UltimateHeal