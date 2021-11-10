local Item = Class()

function Item:init(o)
    o = o or {}

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
    -- Item this item will get turned into when consumed
    self.next_item = nil

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
    for k,v in pairs(o) do
        self[k] = v
    end
end

function Item:onEquip(character) end

function Item:onWorldUse(target) end
function Item:onBattleUse(target) end

function Item:consume()
    
end

return Item