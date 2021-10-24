local SleepMist = Class(Spell)

function SleepMist:init()
    -- Spell ID (optional, defaults to path)
    self.id = "sleep_mist"
    -- Display name
    self.name = "Sleep Mist"

    -- Battle description
    self.effect = "Spare\nTIRED foes"
    -- Menu description
    self.description = "A cold mist sweeps through,\nsparing all TIRED enemies."

    -- TP cost (default tp max is 250)
    self.cost = 80

    -- Target mode (party, enemy, or none/nil)
    self.target = "enemy"

    -- How long it takes the spell to cast
    self.delay = 0.25

    -- (Optional) Suggests this spell when sparing a tired enemy
    self.pacify = true
end

return SleepMist