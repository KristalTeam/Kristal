local IceShock = Class(Spell)

function IceShock:init()
    -- Spell ID (optional, defaults to path)
    self.id = "ice_shock"
    -- Display name
    self.name = "IceShock"

    -- Battle description
    self.effect = "Damage\nw/ ICE"
    -- Menu description
    self.description = "Deals magical ICE damage to\none enemy."

    -- TP cost (default tp max is 250)
    self.cost = 40

    -- How long it takes the spell to cast
    self.delay = 0.25

    -- Target mode (party, enemy, or none/nil)
    self.target = "enemy"
end

return IceShock