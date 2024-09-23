--- The Item class represents all types of item in Kristal. \
--- Items are data files contained in `scripts/data/items` that should extend this class or one of its extensions (see below), and their filepath starting at this location becomes their id, unless an id for them is specified as the second argument to `Class()`. \
--- There are extensions of item that provide additional functionality when extended from: [`HealItem`](lua://HealItem.init) and [`TensionItem`](lua://TensionItem.init) \
--- Items that are Light World equipment should extend [`LightEquipItem`](lua://LightEquipItem.init) instead of this class (it provides all of the same fields and functions as `Item`). \
--- Items can be given to the player directly in the code through [`Inventory:addItem()`](lua://Inventory.addItem).
---
---@class Item : Class
---
---@field name string
---@field use_name string?
---
---@field type string
---@field icon string?
---@field light boolean
---
---@field effect string
---@field shop string
---@field description string
---@field check string
---
---@field price integer
---@field can_sell boolean
---
---@field buy_price integer?
---@field sell_price integer?
---
---@field target string
---@field usable_in string
---@field result_item string?
---@field instant boolean
---
---@field bonuses {attack: number, defense: number, health: number, magic: number, graze_time: number, graze_size: number, graze_tp: number}
---
---@field bonus_name string?
---@field bonus_icon string?
---
---@field bonus_color table
---
---@field can_equip table<string, boolean>
---
---@field reactions table<string, string|table<string, string>>
---
---@field flags table<string, any>
---
---@field dark_item Item
---@field dark_location {storage: string, index: integer}
---@field light_item Item
---@field light_location {storage: string, index: integer}
---
---@overload fun(...) : Item
local Item = Class()

function Item:init()
    -- Display name
    self.name = "Test Item"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (`"item"`, `"key"`, `"weapon"`, `"armor"`)
    self.type = "item"
    -- Item icon filepath (for equipment)
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

    -- Consumable target mode ("ally", "party", "enemy", "enemies", or "none")
    self.target = "none"
    -- Where this item can be used ("world", "battle", "all", or "none")
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

--- *(Override)* Called when the player tries to equip this item on a character \
--- *If the function returns `false`, the item will not be equipped*
---@param character     PartyMember The party member equipping the item
---@param replacement?  Item        The item currently in the slot, if one is present
---@return boolean equipped
function Item:onEquip(character, replacement) return true end
function Item:onUnequip(character, replacement) return true end

--- *(Override)* Called when the item is used in the overworld
---@param target PartyMember|PartyMember[]
function Item:onWorldUse(target) end
--- *(Override)* Called when the item is used in battle
---@param user PartyBattler
---@param target Battler[]|PartyBattler|PartyBattler[]|EnemyBattler|EnemyBattler[]
function Item:onBattleUse(user, target) end

--- *(Override)* Called when the item is selected for use in battle
---@param user PartyBattler
---@param target Battler[]|PartyBattler|PartyBattler[]|EnemyBattler|EnemyBattler[]
function Item:onBattleSelect(user, target) end
--- *(Override)* Called when the item use is undone in the menu
---@param user PartyBattler
---@param target Battler[]|PartyBattler|PartyBattler[]|EnemyBattler|EnemyBattler[]
function Item:onBattleDeselect(user, target) end

--- *(Override)* Called when the menu containing this item is opened (only in Dark World)
---@param menu DarkMenu
function Item:onMenuOpen(menu) end
--- *(Override)* Called when the menu containing this item is closed (only in Dark World)
---@param menu DarkMenu
function Item:onMenuClose(menu) end

--- *(Override)* Called whenever the menu updates when it is open to the storage containing this item (only in Dark World)
---@param menu DarkMenu
function Item:onMenuUpdate(menu) end
--- *(Override)* Called whenever the menu draws when it is open to the storage containing this item (only in Dark World)
---@param menu DarkMenu
function Item:onMenuDraw(menu) end

-- Only for equipped

--- *(Override)* Called every frame in the overworld when this item is equipped
---@param chara Character The equipping character
function Item:onWorldUpdate(chara) end
--- *(Override)* Called every frame in batle when this item is equipped
---@param battler PartyBattler The equipping character
function Item:onBattleUpdate(battler) end

--- *(Override)* Called when the item is saved
---@param data table
function Item:onSave(data) end
--- *(Override)* Called when the item is loaded
---@param data table
function Item:onLoad(data) end

-- Light world / Dark world stuff

--- *(Override)* Called when the item is checked \
--- *By default, responisble for displaying the check message
function Item:onCheck()
    if type(self:getCheck()) == "table" then
        local text
        for i, check in ipairs(self:getCheck()) do
            if i > 1 then
                if text == nil then
                    text = {}
                end
                table.insert(text, check)
            end
        end
        Game.world:showText({{"* \""..self:getName().."\" - "..(self:getCheck()[1] or "")}, text})
    else
        Game.world:showText("* \""..self:getName().."\" - "..self:getCheck())
    end
end
--- *(Override)* Called when the item is tossed \
--- *By default, responsible for displaying a random toss message when in the Light World*
---@return boolean success  Whether the item was successfully tossed - return `false` to cancel tossing
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

--- *(Override)* Converts this item into its light counterpart, if it has one
---@param inventory? LightInventory
---@return boolean|Item result  `true` if the item sucessfully converts and stores, and `false` if there is no item to convert. If the [`light_location`](lua://Item.light_location) is unset, returns the converted item
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
--- *(Override)* Converts this item into its dark counterpart, if it has one
---@param inventory? DarkInventory
---@return boolean|Item result  `true` if the item sucessfully converts and stores, and `false` if there is no item to convert. If the [`dark_location`](lua://Item.light_location) is unset, returns the converted item
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

--- *(Override)* Converts an equipped item to its light counterpart
---@param chara PartyMember
---@return boolean|Item
function Item:convertToLightEquip(chara) return self:convertToLight() end
--- *(Override)* Converts an equipped item to its dark counterpart
---@param chara PartyMember
---@return boolean|Item
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
--- *(Override)* Creates an instance of this Item's specified [`result_item`](lua://Item.result_item)
---@return Item result_item
function Item:createResultItem()
    return Registry.createItem(self.result_item)
end

--- *(Override)* Gets the text displayed when the item is used in battle
---@param user PartyBattler
---@param target Battler[]|PartyBattler|PartyBattler[]|EnemyBattler|EnemyBattler[]
---@return string
function Item:getBattleText(user, target)
    return "* "..user.chara:getName().." used the "..self:getUseName().."!"
end

--[[ Misc Functions ]]--

--- *(Override)* If the item grants bonus `gold`, it applies its bonus here
---@param gold number   The current amount of victory gold
---@return number new_gold  The amount of gold with the bonus applied
function Item:applyMoneyBonus(gold)
    return gold
end

--- Gets the stat bonus an item has for a specific stat
---@param stat string
---@return number bonus
function Item:getStatBonus(stat)
    return self:getStatBonuses()[stat] or 0
end

--- Gets whether a particular character can equip an item
---@param character PartyMember The character to check equippability for
---@param slot_type string      The type of equipment slot, either `"weapon"` or `"armor"`
---@param slot_index number     The index of the slot the item is being equipped to
---@return boolean  can_equip
function Item:canEquip(character, slot_type, slot_index)
    if self.type == "armor" then
        return self.can_equip[character.id] ~= false
    else
        return self.can_equip[character.id]
    end
end

--- Gets the reaction for using or equipping an item for a specific user and reactor
---@param user_id       string  The id of the character using/equipping the item
---@param reactor_id    string  The id of the character to get a reaction for
---@return string?  reaction
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

---@return string
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

--- Gets the value of an item-specific flag
---@param name      string  The name of the flag to get the value from
---@param default?  integer An optional default value to return if the flag is `nil`
function Item:getFlag(name, default)
    local result = self.flags[name]
    if result == nil then
        return default
    else
        return result
    end
end

--- Sets the value of an item-specific flag
---@param name  string  The name of the flag to set
---@param value integer The value to set the flag to
function Item:setFlag(name, value)
    self.flags[name] = value
end

--- Adds to the value of a numerical item-specific flag
---@param name      string  The name of the flag to change
---@param amount?   number  The value to increment the flag by (defaults to `1`)
---@return number new_value
function Item:addFlag(name, amount)
    self.flags[name] = (self.flags[name] or 0) + (amount or 1)
    return self.flags[name]
end

-- Saving / Loading

--- Compacts the item's data into a table for saving
---@return table
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

--- Unpacks a table of Item save data into fields on the class
---@param data table
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