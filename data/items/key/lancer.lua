local item, super = Class(Item, "lancer")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Lancer"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "key"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = nil
    -- Menu description
    self.description = "Hohoho! I'm a tough boy!\nTreat me like one of your ITEMS!"

    -- Default shop price (sell price is halved)
    self.price = nil
    -- Whether the item can be sold
    self.can_sell = false

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "none"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "world"
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

function item:onWorldUse()
    Assets.stopAndPlaySound("splat")
end

function item:getCustomAnimation()
    return nil
end

function item:isVisible()
    return true
end

function item:onMenuUpdate(menu)
    if menu then
        local x, y = menu.box:screenToLocalPos(0, 0)
        if menu.box.state == "SELECT" and menu.box.lancer_actor == nil and self:isVisible() then
            menu.box.lancer_actor = menu.box:addChild(LancerKeyItem(x, y))
            if self:getCustomAnimation() then
                menu.box.lancer_actor.movecon = -1
                menu.box.lancer_actor.custom_animation = self:getCustomAnimation()
            end
        end
        if menu.box.state ~= "SELECT" and menu.box.lancer_actor ~= nil then
            menu.box.lancer_actor:remove()
            menu.box.lancer_actor = nil
        end
        menu.box:setLayer(WORLD_LAYERS["ui"])
    end
end

function item:convertToLight(inventory)
    if inventory:hasItem("light/cards") then
        local light_item = inventory:getItemByID("light/cards")
        table.insert(light_item.cards, self.id)
        return true
    else
        local light_item = Registry.createItem("light/cards")
        table.insert(light_item.cards, self.id)
        return light_item
    end
end

return item
