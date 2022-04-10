local TestShop, super = Class(Shop,  "testshop")

function TestShop:init()
    super:init(self)

    --[[
    -- Shown when you first enter a shop
    self.encounter_text = "* (...)"
    -- Shown when you return to the main menu of the shop
    self.shop_text = "* (...)"
    -- Shown when you leave a shop
    self.leaving_text = "* (...)"
    -- Shown when you're in the BUY menu
    self.buy_menu_text = "..."
    -- Shown when you buy something
    self.buy_text = "..."
    -- Shown when you're in the SELL menu
    self.sell_menu_text = "..."
    -- Shown when you're in the SELL ITEMS menu
    self.sell_items_text = "..."
    -- Shown when you're in the SELL WEAPONS menu
    self.sell_weapons_text = "..."
    -- Shown when you're in the SELL ARMOR menu
    self.sell_armor_text = "..."
    -- Shown when you're in the SELL POCKET ITEMS menu
    self.sell_pocket_text = "..."
    -- Shown when you try to sell an empty spot
    self.sell_nothing_text = "..."
    -- Shown when you refuse to sell something
    self.sell_refuse_text = "..."
    -- Shown when you sell something
    self.sell_text = "..."
    ]]--

end

function TestShop:onTalk()
    self:startDialogue("* There's nobody here.")
end

return TestShop