local RudeBuster = Class(Spell)

function RudeBuster:init()
    -- Spell ID (optional, defaults to path)
    self.id = "rude_buster"
    -- Display name
    self.name = "Rude Buster"

    -- Battle description
    self.effect = "Rude\nDamage"
    -- Menu description
    self.description = "Deals moderate Rude-elemental damage to\none foe. Depends on Attack & Magic."

    -- TP cost (default tp max is 250)
    self.cost = 125

    -- How long it takes the spell to cast
    self.delay = 0.25

    -- Target mode (party, enemy, or none/nil)
    self.target = "enemy"
end

return RudeBuster