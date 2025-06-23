local item, super = Class(HealItem, "bittertear")

function item:init()
    super.init(self)

    -- Display name
    self.name = "BitterTear"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\nAll HP"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Bitter water that fell in droplets from the sky.\nRecovers all HP."

    -- Default shop price (sell price is halved)
    self.price = 0
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"
    -- Where this item can be used (world, battle, all, or none/nil)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Character reactions (key = party member id)
    self.reactions = {
		susie = "... Isn't that rain?",
		noelle = "It's like when we ate snow."
	}
end

function item:getHealAmount(id)
	local party_member = Game:getPartyMember(id)

	if not party_member then
		return self.heal_amount -- Fallback
	end

	return party_member:getStat("health") + math.abs(party_member:getHealth())
end

return item