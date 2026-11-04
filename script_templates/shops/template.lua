---@class TemplateShop : Shop
local shop, super = Class(Shop, "test_shop")

function shop:init()
    super.init(self)

    self.currency_text = "$%d"

    self.encounter_text = "* Encounter text"
    self.shop_text = "* Shop text"
    self.leaving_text = "* Leaving text"
    self.buy_menu_text = "Purchase\ntext"
    self.buy_confirmation_text = "Buy it for\n%s ?"
    self.buy_refuse_text = "Buy\nrefused\ntext"
    self.buy_text = "Buy text"
    self.buy_storage_text = "Storage\nbuy text"
    self.buy_too_expensive_text = "Not\nenough\nmoney."
    self.buy_no_space_text = "You're\ncarrying\ntoo much."
    self.sell_no_price_text = "No\nprice\ntext"
    self.sell_menu_text = "Sell\nmenu\ntext"
    self.sell_nothing_text = "Sell\nnothing\nattempt"
    self.sell_confirmation_text = "Sell it for\n%s ?"
    self.sell_refuse_text = "Sell\nrefuse\ntext"
    self.sell_text = "Sell\ntext"
    self.sell_no_storage_text = "Empty\ninventory\ntext"
    self.sell_everything_text = "Sold\neverything\ntext"
    self.talk_text = "Talk\ntext"

    self.sell_options_text = {
        items = "Item text",
        weapons = "Weapon\ntext",
        armors = "Armor text",
        storage = "Storage\ntext"
    }
    self.hide_storage_text = false

    self.menu_options = {
        {"Buy", "BUYMENU"},
        {"Sell", "SELLMENU"},
        {"Talk", "TALKMENU"},
        {"Exit", "LEAVE"}
    }

    self.shop_music = ""
    self.background = nil
    self.background_speed = 5 / 30
    self.voice = nil
    self.hide_price = false
    self.hide_world = true
    self.hide_main_menu_currency = false

    self.leave_options = {}

    -- self:registerItem("item_id")
    -- self:registerTalk("Topic")
end

-- Function overrides go here

return shop
