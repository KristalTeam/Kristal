local item, super = Class(Item, "manual")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Manual"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Read\nout of\nbattle"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Ralsei's handmade book full of\nvarious tips and tricks."

    -- Default shop price (sell price is halved)
    self.price = 0
    -- Whether the item can be sold
    self.can_sell = false

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "party"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {}
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {}
end

function item:onWorldUse(target)
    Game.world:showText("* (You tried to read the manual,\nbut it was so dense it made\nyour head spin...)")
    return false
end

function item:onBattleSelect(user, target)
    -- Do not consume (ralsei will feel bad)
    return false
end

function item:getBattleText(user, target)
    if Game.battle.encounter.onManualUse then
        return Game.battle.encounter:onManualUse(self, user)
    end
    return {"* "..user.chara:getName().." read the "..self:getUseName().."!", "* But nothing happened..."}
end

return item