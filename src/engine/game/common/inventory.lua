---@class Inventory : Class
---@overload fun(...) : Inventory
local Inventory, super = Class()

function Inventory:init()
    self.storage_for_type = {}
    self.storage_enabled = true

    self:clear()
end

function Inventory:clear()
    self.storages = {}
    self.stored_items = {}
end

function Inventory:addItem(item, ignore_convert)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    return self:addItemTo(self:getDefaultStorage(item, ignore_convert), item)
end

function Inventory:addItemTo(storage, index, item, allow_fallback)
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
end

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

function Inventory:replaceItem(item, new)
    local storage, index = self:getItemIndex(item)
    if storage and new then
        return self:setItem(storage, index, new)
    end
end

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

function Inventory:getItem(storage, index)
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    if storage then
        return storage[index]
    end
end

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

function Inventory:getItemByID(item)
    for k,v in pairs(self.stored_items) do
        if k.id == item then
            return k
        end
    end
end

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

function Inventory:getDefaultStorage(item_type, ignore_convert)
    if isClass(item_type) then -- Passing in an item
        item_type = item_type.type
    end
    return self:getStorage(self.storage_for_type[item_type])
end

function Inventory:getStorage(type)
    return self.storages[type]
end

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