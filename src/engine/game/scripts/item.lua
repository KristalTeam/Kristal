local Item = Class()

function Item:init()
    -- Display name
    self.name = "Test Item"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Example item."

    -- Shop sell price
    self.price = 0

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    self.target = nil
    -- Where this item can be used (world, battle, all, or none/nil)
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

    -- Character reactions (key = party member id)
    self.reactions = {}
end

function Item:onEquip(character) end

function Item:onWorldUse(target) end
function Item:onBattleUse(user, target) end

function Item:onBattleSelect(user, target) end
function Item:onBattleDeselect(user, target) end

function Item:onMenuOpen(menu) end
function Item:onMenuClose(menu) end

function Item:onMenuUpdate(menu, dt) end
function Item:onMenuDraw(menu) end

function Item:getName() return self.name end

function Item:getDescription() return self.description end
function Item:getBattleDescription() return self.effect end
function Item:getShopDescription() return self.shop end

function Item:getPrice() return self.price end

function Item:getStatBonuses() return self.bonuses end
function Item:getBonusName() return self.bonus_name end
function Item:getBonusIcon() return self.bonus_icon end

function Item:getReactions() return self.reactions end

function Item:getBattleText(user, target)
    return "* "..user.chara.name.." used the "..self:getName():upper().."!"
end

function Item:applyGoldBonus(gold)
    return gold
end

function Item:getStatBonus(stat)
    return self:getStatBonuses()[stat] or 0
end

function Item:canEquip(character, slot_type, slot_index)
    if self.type == "armor" then
        return self.can_equip[character.id] ~= false
    else
        return self.can_equip[character.id]
    end
end

function Item:getReaction(user_id, reactor_id)
    local reactions = self:getReactions()
    if reactions[user_id] then
        if type(reactions[user_id]) == "string" then
            if reactor_id == user_id then
                return reactions[user_id]
            else
                return nil
            end
        else
            return reactions[user_id][reactor_id]
        end
    end
end

function Item:getTypeName()
    if self.type == "item" then
        return "Item"
    elseif self.type == "key" then
        return "Key Item"
    elseif self.type == "weapon" then
        return "Weapon"
    elseif self.type == "armor" then
        return "Armor"
    end
    return "Unknown"
end

return Item