local Item = Class()

function Item:init(o)
    -- Item ID (optional, defaults to path)
    self.id = nil
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

    -- Consumable target mode (party, enemy, or none/nil)
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

    -- Load the table
    o = o or {}
    for k,v in pairs(o) do
        self[k] = v
    end
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

function Item:getBattleText(user, target)
    return "* "..user.chara.name.." used the "..self.name:upper().."!"
end

function Item:applyGoldBonus(gold)
    return gold
end

function Item:getReactions(id)
    if id and self.reactions[id] then
        if type(self.reactions[id]) == "table" then
            return self.reactions[id]
        else
            return {[id] = self.reactions[id]}
        end
    end
    return {}
end

return Item