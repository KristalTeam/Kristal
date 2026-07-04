local item, super = Class(Item, "sethspecs")

function item:init()
    super.init(self)

    -- Display name
    self.name = "SethSpecs"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/specs"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A tactician's glasses. Become invulnerable for\nlonger after being damaged."

    -- Default shop price (sell price is halved)
    self.price = 2
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "none"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        defense = 4,
        magic = 6
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "InvTime+"
    self.bonus_icon = "ui/menu/icon/magic"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        noelle = false
    }

    -- Character reactions
    self.reactions = {
        susie = "Easier than stealing Ralsei's.",
        ralsei = "I'm ready to do your homework!",
        noelle = "That's too much like...",
    }
end

function item:calculateInvulnFrames(frames, base_frames, num_equipped)
    -- DIFFERENCE: In DELTARUNE, this does not stack, as you cannot have multiple equipped.
    return frames + (base_frames * (0.2 * num_equipped))
end

function item:calculateInvulnFramesPriority()
    return -0.9
end

return item
