--- The inventory is where all of the player's ITEMs are held. In gameplay, the currently active inventory is stored in [`Game.inventory`](lua://Game.inventory). \
--- In practice, the inventory will be either a [`LightInventory`](lua://LightInventory.init) or [`DarkInventory`](lua://DarkInventory.init), both inheriting from this class.
--- 
---@class Inventory : Class
---
---@field storage_for_type  table<string, string>
---@field storage_enabled   boolean                 Whether the `storage` storage (overflow accessed in the SAVE menu) is enabled
---@field storages          table<string, table>    A table containing all the storage tables available for this inventory
---@field stored_items      table
---
---@overload fun(...) : Inventory
local Inventory, super = Class()

function Inventory:init()
    self.storage_for_type = {}
    self.storage_enabled = true

    self:clear()
end

--- Completely empties the inventory and removes all its storages
function Inventory:clear()
    self.storages = {}
    self.stored_items = {}
end

--- Adds an item to this inventory, sending it to it's [default storage](lua://Inventory.getDefaultStorage)
---@param item              Item|string
---@param ignore_convert?   boolean
---@return Item|nil
function Inventory:addItem(item, ignore_convert)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    return self:addItemTo(self:getDefaultStorage(item, ignore_convert), item)
end

--- Adds an item to this inventory
---@overload fun(self: Inventory, item: any, allow_fallback: any)
---@param storage           string|table
---@param index?            integer
---@param item              Item|string
---@param allow_fallback?   boolean
---@return Item|nil
function Inventory:addItemTo(storage, index, item, allow_fallback)
    ---@diagnostic disable param-type-mismatch
    if type(index) ~= "number" then
        allow_fallback = item
        item = index
        index = nil
    end
    allow_fallback = (allow_fallback == nil and self.storage_enabled) or allow_fallback
    local item_id, storage_id = item, storage
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    if item and storage then
        if not index then
            -- No index specified, find the next free slot
            local free_storage, free_index = self:getNextIndex(storage, 1, allow_fallback)
            return self:setItem(free_storage, free_index, item)
        else
            if index <= 0 or index > storage.max then
                -- Index out of bounds
                return
            end
            if storage.sorted then
                if self:isFull(storage, allow_fallback) then
                    -- Attempt to insert into full storage
                    return
                end
                index = math.min(#storage + 1, index)
                table.insert(storage, index, item)
                if storage[storage.max + 1] then
                    -- Inserting pushed item out-of-bounds, move it to fallback storage
                    local overflow, overflow_index = self:getNextIndex(storage, storage.max + 1, allow_fallback)
                    if not overflow or not self:setItem(overflow, overflow_index, storage[storage.max + 1]) then
                        Kristal.Console:warn("Deleted item by overflow - THIS SHOULDNT HAPPEN")
                    else
                        self:updateStoredItems(self:getStorage(overflow))
                    end
                    storage[storage.max + 1] = nil
                end
                self:updateStoredItems(storage)
                return item
            else
                if storage[index] then
                    -- Attempt to add to non-empty slot
                    return
                end
                return self:setItem(storage, index, item)
            end
        end
    end
    ---@diagnostic enable param-type-mismatch
end

--- Gets the next open index for an item in the given storage
---@param storage           string|table
---@param index?            integer         The minimum index to check
---@param allow_fallback?   boolean         Whether the fallback storage will be checked if the current target storage is full
---@return string|nil   id      The id of the storage with an open slot
---@return integer|nil  index   The index of the open slot
function Inventory:getNextIndex(storage, index, allow_fallback)
    allow_fallback = (allow_fallback == nil and self.storage_enabled) or allow_fallback
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    index = index or 1
    while index <= storage.max do
        if not storage[index] then
            return storage.id, index
        end
        index = index + 1
    end
    if storage.fallback and allow_fallback then
        return self:getNextIndex(storage.fallback, index - storage.max)
    end
end

--- Removes an item from this inventory
---@param item string|Item
---@return Item|nil
function Inventory:removeItem(item)
    local stored = self.stored_items[item]
    if type(item) == "string" then
        for k,v in pairs(self.stored_items) do
            if k.id == item then
                stored = v
                break
            end
        end
    end
    return self:removeItemFrom(stored.storage, stored.index)
end

--- Removes the item at `index` of a specific storage in this inventory
---@param storage string|table
---@param index? integer
---@return Item|nil
function Inventory:removeItemFrom(storage, index)
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    if storage then
        if not index or index <= 0 or index > storage.max then
            return
        elseif storage.sorted then
            local item = table.remove(storage, index)
            self:updateStoredItems(storage)
            return item
        else
            local item = storage[index]
            storage[index] = nil
            self:updateStoredItems(storage)
            return item
        end
    end
end

--- Sets the item stored at `index` of a particular storage
---@param storage?  string|table
---@param index?    integer
---@param item?     string|Item
---@return Item|nil
function Inventory:setItem(storage, index, item)
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    if storage then
        if not index or index <= 0 or index > storage.max then
            return
        elseif storage.sorted then
            index = math.min(#storage + 1, index)
            if storage[index] then
                table.remove(storage, index)
            end
            if item then
                table.insert(storage, index, item)
            end
            self:updateStoredItems(storage)
            return item
        else
            storage[index] = item
            self:updateStoredItems(storage)
            return item
        end
    end
end

--- Updates the [`stored_items`](lua://Inventory.stored_items) table
---@param storage? table
function Inventory:updateStoredItems(storage)
    if not storage then
        for k,v in pairs(self.storages) do
            self:updateStoredItems(v)
        end
    else
        for k,v in pairs(self.stored_items) do
            if v.storage == storage.id then
                self.stored_items[k] = nil
            end
        end
        for i = 1, storage.max do
            if storage[i] then
                self.stored_items[storage[i]] = {storage = storage.id, index = i}
            end
        end
    end
end

--- Gets the storage and index an item is stored at in this inventory, if it exists
---@param item string|Item
---@return table|nil storage
---@return integer|nil index
function Inventory:getItemIndex(item)
    if type(item) == "string" then
        for k,v in pairs(self.stored_items) do
            if k.id == item then
                return v.storage, v.index
            end
        end
    else
        local stored = self.stored_items[item]
        if stored then
            return stored.storage, stored.index
        end
    end
end

--- Replaces one item in the inventory with another
---@param item string|Item
---@param new string|Item
---@return Item|nil
function Inventory:replaceItem(item, new)
    local storage, index = self:getItemIndex(item)
    if storage and new then
        return self:setItem(storage, index, new)
    end
end

--- Swaps the position of two items in the inventory
---@param storage1 string|table
---@param index1 integer
---@param storage2 string|table
---@param index2 integer
function Inventory:swapItems(storage1, index1, storage2, index2)
    if type(storage1) == "string" then
        storage1 = self:getStorage(storage1)
    end
    if type(storage2) == "string" then
        storage2 = self:getStorage(storage2)
    end
    if storage1 and storage2 then
        if not index1 or index1 <= 0 or index1 > storage1.max then
            return
        end
        if not index2 or index2 <= 0 or index2 > storage2.max then
            return
        end
        if storage1.sorted then
            index1 = math.min(#storage1 + 1, index1)
        end
        if storage2.sorted then
            index2 = math.min(#storage2 + 1, index2)
        end
        local item1 = storage1[index1]
        local item2 = storage2[index2]
        if storage1.sorted then
            table.remove(storage1, index1)
            if item2 then
                table.insert(storage1, index1, item2)
            end
        else
            storage1[index1] = item2
        end
        if storage2.sorted then
            table.remove(storage2, index2)
            if item1 then
                table.insert(storage2, index2, item1)
            end
        else
            storage2[index2] = item1
        end
        self:updateStoredItems(storage1)
        if storage2 ~= storage1 then
            self:updateStoredItems(storage2)
        end
    end
end

--- Gets an item from the inventory, if it exists
---@param storage string|table
---@param index integer
---@return Item|nil
function Inventory:getItem(storage, index)
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    if storage then
        return storage[index]
    end
end

--- Gets whether an item is in this inventory, in any storage
---@param item string|Item
---@return boolean has_item
---@return Item|nil item
function Inventory:hasItem(item)
    if type(item) == "string" then
        for k,v in pairs(self.stored_items) do
            if k.id == item then
                return true, k
            end
        end
        return false
    else
        return self.stored_items[item] ~= nil, item
    end
end

--- Gets an item in the inventory by its id, if it exists
---@param item string
---@return Item|nil
function Inventory:getItemByID(item)
    for k,v in pairs(self.stored_items) do
        if k.id == item then
            return k
        end
    end
end

--- Gets whether a particular storage in this inventory is full
---@param storage           string|table
---@param allow_fallback?   boolean         Whether the fallback storage should also be checked for space before declaring this storage full
---@return boolean full
function Inventory:isFull(storage, allow_fallback)
    allow_fallback = (allow_fallback == nil and self.storage_enabled) or allow_fallback
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    if storage then
        local full = false
        if storage.sorted then
            full = #storage >= storage.max
        else
            for i = 1, storage.max do
                if not storage[i] then
                    return false
                end
            end
            full = true
        end
        if full and storage.fallback and allow_fallback then
            return self:isFull(storage.fallback, true)
        end
        return full
    else
        return true
    end
end

--- Gets the number of items contained in the specified storage
---@param storage string|table
---@param allow_fallback? boolean Whether the fallback storage should also be included in the item count
---@return integer
function Inventory:getItemCount(storage, allow_fallback)
    allow_fallback = (allow_fallback == nil and self.storage_enabled) or allow_fallback
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    if storage then
        local count = 0
        if storage.sorted then
            count = #storage
        else
            for i = 1, storage.max do
                if storage[i] then
                    count = count + 1
                end
            end
        end
        if storage.fallback and allow_fallback then
            return count + self:getItemCount(storage.fallback, true)
        end
        return count
    else
        return 0
    end
end

--- Gets the amount of free space in the specified storage
---@param storage string|table
---@param allow_fallback? boolean
---@return integer
function Inventory:getFreeSpace(storage, allow_fallback)
    allow_fallback = (allow_fallback == nil and self.storage_enabled) or allow_fallback
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    if storage then
        local count = 0
        if storage.sorted then
            count = storage.max - #storage
        else
            for i = 1, storage.max do
                if not storage[i] then
                    count = count + 1
                end
            end
        end
        if storage.fallback and allow_fallback then
            return count + self:getFreeSpace(storage.fallback, true)
        else
            return count
        end
    end
    return 0
end

--- Tries to give an item to the player, and returns an appropriate text to display depending on success
---@param item              string|Item
---@param ignore_convert    boolean
---@return boolean success      Whether the item was successfully picked up
---@return string result_text   The text that should be displayed
function Inventory:tryGiveItem(item, ignore_convert)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    local result = self:addItem(item, ignore_convert)
    if result then
        local destination = self:getStorage(self.stored_items[result].storage)
        return true, "* ([color:yellow]"..item:getName().."[color:reset] was added to your [color:yellow]"..destination.name.."[color:reset].)"
    else
        local destination = self:getDefaultStorage(item)
        return false, "* (You have too many [color:yellow]"..destination.name.."[color:reset] to take [color:yellow]"..item:getName().."[color:reset].)"
    end
end

--- Gets the default storaged used to store items of type `item_type`
---@param item_type Item|string     An item type or an Item instance to get the type from
---@param ignore_convert? boolean
---@return table storage
function Inventory:getDefaultStorage(item_type, ignore_convert)
    if isClass(item_type) then -- Passing in an item
        item_type = item_type.type
    end
    return self:getStorage(self.storage_for_type[item_type])
end

--- Gets one of this inventory's storages
---@param type string The name of the storage
---@return table storage
function Inventory:getStorage(type)
    return self.storages[type]
end

---@param data table
function Inventory:load(data)
    self:clear()

    self.storage_enabled = data.storage_enabled or self.storage_enabled

    data.storages = data.storages or {}
    for id,storage in pairs(self.storages) do
        if data.storages[id] then
            self:loadStorage(storage, data.storages[id])
        end
    end
    self:updateStoredItems()
end

---@return table
function Inventory:save()
    local data = {
        storage_enabled = self.storage_enabled,
        storages = {}
    }

    for id,storage in pairs(self.storages) do
        data.storages[id] = self:saveStorage(storage)
    end

    return data
end

---@param storage table
---@param data table
function Inventory:loadStorage(storage, data)
    storage.max = data.max
    for i = 1, storage.max do
        local item = data.items[tostring(i)]
        if item then
            if Registry.getItem(item.id) then
                storage[i] = Registry.createItem(item.id)
                storage[i]:load(item)
            else
                Kristal.Console:error("Could not load item \""..item.id.."\"")
            end
        end
    end
end

---@param storage table
---@return table
function Inventory:saveStorage(storage)
    local saved = {
        max = storage.max,
        items = {}
    }
    for i = 1, storage.max do
        if storage[i] then
            saved.items[tostring(i)] = storage[i]:save()
        end
    end
    return saved
end

return Inventory