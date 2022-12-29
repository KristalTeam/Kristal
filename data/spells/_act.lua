-- This spell is only used for display in the POWER menu.

local spell, super = Class(Spell, "_act")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "ACT"
    -- Name displayed when cast (optional)
    self.cast_name = nil

    -- Battle description
    self.effect = ""
    -- Menu description
    if Game.chapter == 1 then
        self.description = "Do all sorts of things.\nIt isn't magic."
    else
        self.description = "You can do many things.\nDon't confuse it with magic."
    end

    -- TP cost
    self.cost = 0

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "enemy"

    -- Tags that apply to this spell
    self.tags = {}
end

return spell