local Item = Class()

function Item:init()
    -- Display name
    self.name = "Test Item"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

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

    -- Default shop price (sell price is halved)
    self.price = 0
    -- Whether the item can be sold
    self.can_sell = true

    -- Shop buy price (optional)
    self.buy_price = nil
    -- Shop sell price (optional, default half of buy price)
    self.sell_price = nil

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "none"
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
function Item:getUseName() return self.use_name or self.name:upper() end

function Item:getDescription() return self.description end
function Item:getBattleDescription() return self.effect end

function Item:getShopDescription()
    return (self.type == "key" and "KEYITEM" or self:getTypeName():upper()) .. "\n" .. self.shop
end

function Item:getPrice() return self.price end

function Item:getBuyPrice() return self.buy_price or self:getPrice() end
function Item:getSellPrice() return self.sell_price or math.ceil(self:getPrice()/2) end

function Item:isSellable() return self.can_sell end

function Item:getStatBonuses() return self.bonuses end
function Item:getBonusName() return self.bonus_name end
function Item:getBonusIcon() return self.bonus_icon end

function Item:getReactions() return self.reactions end

function Item:getBattleText(user, target)
    return "* "..user.chara.name.." used the "..self:getUseName().."!"
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