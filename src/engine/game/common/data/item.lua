---@class Item : Class
---@overload fun(...) : Item
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
    -- Whether this item is for the light world
    self.light = false

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Example description"
    -- Light world check text
    self.check = "Example info"

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

    -- The color of the bonus icon, always orange in DELTARUNE
    self.bonus_color = PALETTE["world_ability_icon"]

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions (key = party member id)
    self.reactions = {}

    --[[ INTERNAL VARIABLES ]]--

    -- Item flags (for saving values to the save file)
    self.flags = {}

    -- Values saved for light/dark world item conversion
    self.dark_item = nil
    self.dark_location = nil

    self.light_item = nil
    self.light_location = nil
end

--[[ Callbacks ]]--

function Item:onEquip(character, replacement) return true end
function Item:onUnequip(character, replacement) return true end

function Item:onWorldUse(target) end
function Item:onBattleUse(user, target) end

function Item:onBattleSelect(user, target) end
function Item:onBattleDeselect(user, target) end

function Item:onMenuOpen(menu) end
function Item:onMenuClose(menu) end

function Item:onMenuUpdate(menu) end
function Item:onMenuDraw(menu) end

-- Only for equipped
function Item:onWorldUpdate(chara) end
function Item:onBattleUpdate(battler) end

function Item:onSave(data) end
function Item:onLoad(data) end

-- Light world / Dark world stuff
function Item:onCheck()
    Game.world:showText("* \""..self:getName().."\" - "..self:getCheck())
end
function Item:onToss()
    if Game:isLight() then
        local choice = love.math.random(30)
        if choice == 1 then
            Game.world:showText("* You bid a quiet farewell to the " .. self:getName() .. ".")
        elseif choice == 2 then
            Game.world:showText("* You put the " .. self:getName() .. " on the ground and gave it a little pat.")
        elseif choice == 3 then
            Game.world:showText("* You threw the " .. self:getName() .. " on the ground like the piece of trash it is.")
        elseif choice == 4 then
            Game.world:showText("* You abandoned the " .. self:getName() .. ".")
        else
            Game.world:showText("* The " .. self:getName() .. " was thrown away.")
        end
    end
    return true
end

function Item:convertToLight(inventory)
    if self.light_item then
        if self.light_location then
            inventory:addItemTo(self.light_location.storage, self.light_location.index, self.light_item)
            return true
        else
            return self.light_item
        end
    end
    return false
end
function Item:convertToDark(inventory)
    if self.dark_item then
        if self.dark_location then
            inventory:addItemTo(self.dark_location.storage, self.dark_location.index, self.dark_item)
            return true
        else
            return self.dark_item
        end
    end
    return false
end

function Item:convertToLightEquip(chara) return self:convertToLight() end
function Item:convertToDarkEquip(chara) return self:convertToDark() end

--[[ Getters ]]--

function Item:getName() return self.name end
function Item:getUseName() return self.use_name or self:getName():upper() end
function Item:getWorldMenuName() return self:getName() end

function Item:getDescription() return self.description end
function Item:getBattleDescription() return self.effect end
function Item:getCheck() return self.check end

function Item:getShopDescription()
    return self:getTypeName() .. "\n" .. self.shop
end

function Item:getPrice() return self.price end

function Item:getBuyPrice() return self.buy_price or self:getPrice() end
function Item:getSellPrice() return self.sell_price or math.ceil(self:getPrice()/2) end

function Item:isSellable() return self.can_sell end

function Item:getStatBonuses() return self.bonuses end
function Item:getBonusName() return self.bonus_name end
function Item:getBonusIcon() return self.bonus_icon end

function Item:getReactions() return self.reactions end

function Item:hasResultItem() return self.result_item ~= nil end
function Item:createResultItem()
    return Registry.createItem(self.result_item)
end

function Item:getBattleText(user, target)
    return "* "..user.chara:getName().." used the "..self:getUseName().."!"
end

--[[ Misc Functions ]]--

function Item:applyMoneyBonus(gold)
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
        return "ITEM"
    elseif self.type == "key" then
        return "KEYITEM"
    elseif self.type == "weapon" then
        return "WEAPON"
    elseif self.type == "armor" then
        return "ARMOR"
    end
    return "UNKNOWN"
end

function Item:getFlag(name, default)
    local result = self.flags[name]
    if result == nil then
        return default
    else
        return result
    end
end

function Item:setFlag(name, value)
    self.flags[name] = value
end

function Item:addFlag(name, amount)
    self.flags[name] = (self.flags[name] or 0) + (amount or 1)
    return self.flags[name]
end

-- Saving / Loading

function Item:save()
    local saved_dark_item = self.dark_item
    local saved_light_item = self.light_item
    if isClass(self.dark_item) then saved_dark_item = self.dark_item:save() end
    if isClass(self.light_item) then saved_light_item = self.light_item:save() end
    local data = {
        id = self.id,
        flags = self.flags,

        dark_item = saved_dark_item,
        dark_location = self.dark_location,

        light_item = saved_light_item,
        light_location = self.light_location,
    }
    self:onSave(data)
    return data
end

function Item:load(data)
    self.flags = data.flags or self.flags

    if data.dark_item then
        if type(data.dark_item) == "table" then
            self.dark_item = Registry.createItem(data.dark_item.id)
            self.dark_item:load(data.dark_item)
        else
            self.dark_item = data.dark_item
        end

        self.dark_location = data.dark_location
    end

    if data.light_item then
        if type(data.light_item) == "table" then
            self.light_item = Registry.createItem(data.light_item.id)
            self.light_item:load(data.light_item)
        else
            self.light_item = data.light_item
        end

        self.light_location = data.light_location
    end

    self:onLoad(data)
end

return Item