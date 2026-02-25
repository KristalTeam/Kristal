--- A type of inventory used to store items in the Dark World.
---@class DarkInventory : Inventory
---@overload fun(...) : DarkInventory
local DarkInventory, super = Class(Inventory)

function DarkInventory:init()
    super.init(self)

    self.storage_for_type = {
        ["item"]   = "items",
        ["key"]    = "key_items",
        ["weapon"] = "weapons",
        ["armor"]  = "armors",
    }

    self.storage_enabled = Game.default_storage_slots > 0

    -- Order the storages are converted to the light world
    self.convert_order = {"key_items", "weapons", "armors", "items", "storage"}
end

function DarkInventory:clear()
    super.clear(self)

    self.storages = {
        ["items"]     = {id = "items",     max = 12,                         sorted = true,  name = "ITEMs",       fallback = "storage"},
        ["key_items"] = {id = "key_items", max = 12,                         sorted = true,  name = "KEY ITEMs",   fallback = nil      },
        ["weapons"]   = {id = "weapons",   max = Game.default_equip_slots,   sorted = false, name = "WEAPONs",     fallback = nil      },
        ["armors"]    = {id = "armors",    max = Game.default_equip_slots,   sorted = false, name = "ARMORs",      fallback = nil      },
        ["storage"]   = {id = "storage",   max = Game.default_storage_slots, sorted = false, name = "STORAGE",     fallback = nil      },
    }

    Kristal.callEvent(KRISTAL_EVENT.createDarkInventory, self)
end


---@return LightInventory
function DarkInventory:convertToLight()
    local new_inventory = LightInventory()

    local was_storage_enabled = new_inventory.storage_enabled
    new_inventory.storage_enabled = true
    
    for k,storage in pairs(self:getLightInventory().storages) do
        for i = 1, storage.max do
            if storage[i] then
                if not new_inventory:addItemTo(storage.id, i, storage[i]) then
                    new_inventory:addItem(storage[i])
                end
            end
        end
    end

    if not self:getLightInventory():hasItem("light/ball_of_junk") then
        new_inventory:addItem("light/ball_of_junk")
    end

    Kristal.callEvent(KRISTAL_EVENT.onConvertToLight, new_inventory)

    for _,storage_id in ipairs(self.convert_order) do
        local storage = TableUtils.copy(self:getStorage(storage_id))
        for i = 1, storage.max do
            local item = storage[i]
            if item then
                local result = item:convertToLight(new_inventory)

                if result then
                    self:removeItem(item)

                    if not isClass(result) and type(result) == "table" then
                        for _,item in ipairs(result) do
                            if type(item) == "string" then
                                item = Registry.createItem(item)
                            end
                            if isClass(item) then
                                new_inventory:addItem(item)
                            end
                        end
                    else
                        if type(result) == "string" then
                            result = Registry.createItem(result)
                        end
                        if isClass(result) then
                            new_inventory:addItem(result)
                        end
                    end
                end
            end
        end
    end

    new_inventory.storage_enabled = was_storage_enabled
    
    Game.dark_inventory = self

    return new_inventory
end

--- Gets the Light World inventory
---@return LightInventory
function DarkInventory:getLightInventory()
    return Game.light_inventory
end

--- Gets the Dark World inventory
---@return DarkInventory
function DarkInventory:getDarkInventory()
    return self
end

-- Item give overrides for Light World items

---@param item              Item|string
---@param ignore_light?     boolean     Whether to add the item to this inventory even if it is a Light item
---@return Item|nil
function DarkInventory:addItem(item, ignore_light)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    if ignore_light or not item.light then
        return super.addItem(self, item)
    else
        local light_inv = self:getLightInventory()
        return light_inv:addItem(item)
    end
end

---@param item              string|Item
---@param ignore_light?     boolean     Whether to add the item to this inventory even if it is a Light item
---@return boolean success      Whether the item was successfully picked up
---@return string result_text   The text that should be displayed
function DarkInventory:tryGiveItem(item, ignore_light)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    if ignore_light or not item.light then
        return super.tryGiveItem(self, item, ignore_light)
    else
        local light_inv = self:getLightInventory()
        local result = light_inv:addItem(item)
        if result then
            return true, "* ([color:yellow]"..item:getName().."[color:reset] was added to your [color:yellow]LIGHT ITEMs[color:reset].)"
        else
            return false, "* (You have too many [color:yellow]LIGHT ITEMs[color:reset] to take [color:yellow]"..item:getName().."[color:reset].)"
        end
    end
end

return DarkInventory