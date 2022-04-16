local Inventory, super = Class()

function Inventory:init()
    self.storage_for_type = {
        ["item"]   = "items",
        ["key"]    = "key_items",
        ["weapon"] = "weapons",
        ["armor"]  = "armors",
    }

    self.pocket_enabled = (Game.chapter > 1)

    self:clear()
end

function Inventory:clear()
    self.storages = {
        ["items"]     = {id = "items",     max = 12, sorted = true,  name = "ITEMs",     fallback = "pocket"},
        ["key_items"] = {id = "key_items", max = 12, sorted = true,  name = "KEY ITEMs", fallback = nil     },
        ["weapons"]   = {id = "weapons",   max = 48, sorted = false, name = "WEAPONs",   fallback = nil     },
        ["armors"]    = {id = "armors",    max = 48, sorted = false, name = "ARMORs",    fallback = nil     },
        ["pocket"]    = {id = "pocket",    max = 24, sorted = false, name = "STORAGE",   fallback = nil     },
    }
    self.stored_items = {}
end

function Inventory:addItem(item)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    return self:addItemTo(self:getDefaultStorage(item.type), item)
end

function Inventory:addItemTo(storage, index, item, allow_fallback)
    allow_fallback = (allow_fallback ~= false) and self.pocket_enabled
    if type(index) ~= "number" then
        allow_fallback = item
        item = index
        index = nil
    end
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
                table.insert(storage, index, item)
                self.stored_items[item] = {storage = storage.id, index = index}
                if storage[storage.max + 1] then
                    -- Inserting pushed item out-of-bounds, move it to fallback storage
                    local overflow, overflow_index = self:getNextIndex(storage, storage.max + 1, allow_fallback)
                    if not overflow or not self:setItem(overflow, overflow_index, storage[storage.max + 1]) then
                        self.stored_items[storage[storage.max + 1]] = nil
                        print("[WARNING] Deleted item by overflow - THIS SHOULDNT HAPPEN")
                    end
                    storage[storage.max + 1] = nil
                end
                -- Update indexes in the stored_items table for all items we pushed up
                for i = index + 1, storage.max do
                    if storage[i] then
                        self.stored_items[storage[i]].index = i
                    end
                end
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
    allow_fallback = (allow_fallback ~= false) and self.pocket_enabled
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
            self.stored_items[item] = nil
            -- Update indexes in the stored_items table for all items we pushed down
            for i = index, storage.max do
                if storage[i] then
                    self.stored_items[storage[i]].index = i
                end
            end
            return item
        else
            local item = storage[index]
            storage[index] = nil
            self.stored_items[item] = nil
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
            if storage[index] then
                local old_item = table.remove(storage, index)
                self.stored_items[old_item] = nil
            end
            if item then
                table.insert(storage, index, item)
                self.stored_items[item] = {storage = storage.id, index = index}
            end
            return item
        else
            if storage[index] then
                self.stored_items[storage[index]] = nil
            end
            storage[index] = item
            if item then
                self.stored_items[item] = {storage = storage.id, index = index}
            end
            return item
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

function Inventory:isFull(storage, allow_fallback)
    allow_fallback = (allow_fallback ~= false) and self.pocket_enabled
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    if storage then
        local full = false
        if storage.sorted then
            full = #storage < storage.max
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

function Inventory:tryGiveItem(item)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    local result = self:addItem(item)
    if result then
        local destination = self:getStorage(self.stored_items[item].storage)
        return true, "* ([color:yellow]"..item:getName().."[color:reset] was added to your\n[color:yellow]"..destination.name.."[color:reset].)"
    else
        local destination = self:getDefaultStorage(item.type)
        return false, "* (You have too many [color:yellow]"..destination.name.."[color:reset]\nto take [color:yellow]"..item:getName().."[color:reset].)"
    end
end

function Inventory:getDefaultStorage(type)
    return self:getStorage(self.storage_for_type[type])
end

function Inventory:getStorage(type)
    return self.storages[type]
end

function Inventory:getFreeSpace(storage, allow_fallback)
    allow_fallback = (allow_fallback ~= false) and self.pocket_enabled
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

function Inventory:load(data)
    self:clear()

    self.pocket_enabled = data.pocket_enabled or self.pocket_enabled

    data.storages = data.storages or {}
    for id,storage in pairs(self.storages) do
        if data.storages[id] then
            self:loadStorage(storage, data.storages[id])
        end
    end
end

function Inventory:save()
    local data = {
        pocket = self.pocket_enabled,
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
        local item = data.items[i]
        if item then
            if Registry.getItem(item.id) then
                storage[i] = Registry.createItem(item.id)
                storage[i]:load(item)
            else
                print("LOAD ERROR: Could not load item \""..item.id.."\"")
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
            saved.items[i] = storage[i]:save()
        end
    end
    return saved
end

return Inventory