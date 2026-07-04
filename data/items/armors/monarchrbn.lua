local item, super = Class(Item, "monarchrbn")

function item:init()
    super.init(self)

    -- Display name
    self.name = "MonarchRBN"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A ribbon like the wings of a butterfly.\nIncreases healing ability when equipped."

    -- Default shop price (sell price is halved)
    self.price = 4000
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
        defense = 6,
        magic = 2
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "HasAntenna"
    self.bonus_icon = "ui/menu/icon/smile"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "Got a taranchula one?",
        ralsei = "My horns are like antenna!",
        noelle = "They're not ANTENNA!! They're ant-LERS!",
    }
    self.susie_rejection = "I'll squash it."
end

function item:canEquip(character, slot_type, slot_index)
    if character.id == "susie" and not character:getFlag("can_wear_ribbons", false) then
        return false
    end

    return super.canEquip(self, character, slot_type, slot_index)
end

function item:getReaction(user_id, reactor_id)
    if user_id == "susie" and reactor_id == "susie" then
        local susie = Game:getPartyMember("susie")

        if not susie:getFlag("can_wear_ribbons", false) then
            return self.susie_rejection
        end
    end

    return super.getReaction(self, user_id, reactor_id)
end

function item:calculateBattleHeal(heal, base_heal, caster, target)
    -- Increase heal by 1/8 of the base heal for each equipped on the healer
    local heal_add = math.ceil(base_heal / 8)

    if caster ~= nil then
        local _, amount = caster:checkArmor(self.id)
        heal_add = heal_add * amount
    end

    return heal + heal_add
end

function item:calculateBattleHealPriority()
    return -0.8
end

return item
