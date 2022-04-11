local item, super = Class(Item, "manual")

function item:init()
    super:init(self)

    -- Display name
    self.name = "Manual"

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

    -- Shop buy price
    self.buy_price = 0
    -- Shop sell price (usually half of buy price)
    self.sell_price = nil

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    self.target = nil
    -- Where this item can be used (world, battle, all, or none/nil)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        attack = 0,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {}
end

function item:onWorldUse(target)
    Game.world:startCutscene(function(cutscene)
        cutscene:text("* (You tried to read the manual,\nbut it was so dense it made\nyour head spin...)")
    end)
    return false
end

function item:onBattleSelect(user, target)
    -- Do not consume (ralsei will feel bad)
    return false
end

function item:getBattleText(user, target)
    if Game.battle.encounter.onManualUse then
        return Game.battle.encounter:onManualUse(user)
    end
    return {"* "..user.chara.name.." read the MANUAL!", "* But nothing happened..."}
end

return item