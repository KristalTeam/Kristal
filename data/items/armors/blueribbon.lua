local item, super = Class(Item, "blueribbon")

function item:init()
    super.init(self)

    -- Display name
    self.name = "BlueRibbon"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A blue cheer bow. When the user uses a\nhealing move, it recovers slightly more HP."

    -- Default shop price (sell price is halved)
    self.price = 1
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
        defense = 1,
        magic = 1,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Heal+"
    self.bonus_icon = "ui/menu/icon/up"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "Hey, ONLY on the arm.",
        ralsei = "Yeah!",
        noelle = "Go...  t... team?",
    }
    self.susie_rejection = "ABSOLUTELY not."
    -- Ralsei cheer reactions (advanced on each equip)
    self.ralsei_cheer_reactions = {
        "Give me a K! Give me an R!",
        "Give me an I! Give me an S!",
        "Give me an ampersand!",
        "Give me an S! Give me a U!",
        "Give me an S! Give me an I!",
        "Give me an E! Give me an A!",
        "Give me an R! Give me an E!",
        "Give me an M! Give me a Y!",
        "Give me an F! Give me an R!",
        "Give me an I! Give me an E!",
        "Give me an N! Give me a D!",
        "Give me an S!",
        "Give me an exclamation point!",
        "Um, that's it!",
        "D... don't give me anything else!",
    }
    self.ralsei_cheer_flag = "blueribbon_ralsei_cheer"
end

function item:canEquip(character, slot_type, slot_index)
    if character.id == "susie" and not character:getFlag("can_wear_ribbons", false) then
        return false
    end

    return super.canEquip(self, character, slot_type, slot_index)
end

function item:onEquip(character, replacement)
    if character.id == "ralsei" then
        -- Cheer reaction advances each equip
        Game:setFlag(self.ralsei_cheer_flag, Game:getFlag(self.ralsei_cheer_flag, 1) + 1)
    end

    return true
end

function item:getReaction(user_id, reactor_id)
    -- Handle progressive cheer reaction for Ralsei
    if user_id == "ralsei" and reactor_id == "ralsei" then
        local cheer_step = Game:getFlag(self.ralsei_cheer_flag, 1)

        if self.ralsei_cheer_reactions[cheer_step] then
            return self.ralsei_cheer_reactions[cheer_step]
        end
    end

    -- Handle ribbon rejection for Susie
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
    return -0.9
end

return item
