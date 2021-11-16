local Inventory, super = Class()

function Inventory:init()
    self:clear()
end

function Inventory:clear()
    self.items     = {max = 24, sorted = true}
    self.key_items = {max = 24, sorted = true}
    self.weapons   = {max = 48, sorted = false}
    self.armors    = {max = 48, sorted = false}
end

function Inventory:addItem(item, index)
    if type(item) == "string" then
        item = Registry.getItem(item)
    end
    if item then
        return self:addItemTo(item.type, item, index)
    else
        return false
    end
end

function Inventory:addItemTo(storage, item, index)
    if type(item) == "string" then
        item = Registry.getItem(item)
    end
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    if item and storage then
        if storage.sorted then
            if #storage >= storage.max then
                return false
            end
            if index then
                if index <= 0 or index > storage.max then
                    return false
                end
                table.insert(storage, index, item)
                return true
            else
                table.insert(storage, item)
                return true
            end
        else
            if index then
                if index <= 0 or index > storage.max or storage[index] then
                    return false
                else
                    storage[index] = item
                    return true
                end
            else
                for i = 1, storage.max do
                    if not storage[i] then
                        storage[i] = item
                        return true
                    end
                end
                return false
            end
        end
    end
    return false
end

function Inventory:removeItem(storage, index)
    if isClass(storage) then
        storage = self:getStorage(storage.type)
    end
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    if storage then
        if not index or index <= 0 or index > storage.max then
            return nil
        elseif storage.sorted then
            return table.remove(storage, index)
        else
            local item = storage[index]
            storage[index] = nil
            return item
        end
    end
    return nil
end

function Inventory:replaceItem(storage, item, index)
    if isClass(storage) then
        index = item
        item = storage
        storage = self:getStorage(item.type)
    end
    if type(item) == "string" then
        item = Registry.getItem(item)
    end
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    if storage then
        if not index or index <= 0 or index > storage.max then
            return false, nil
        else
            local old = storage[index]
            storage[index] = item
            return true, old
        end
    end
    return false, nil
end

function Inventory:getItem(storage, index)
    if type(storage) == "string" then
        storage = self:getStorage(storage)
    end
    if storage then
        return storage[index]
    else
        return nil
    end
end

function Inventory:getStorage(type)
    if type == "item" then
        return self.items
    elseif type == "key" then
        return self.key_items
    elseif type == "weapon" then
        return self.weapons
    elseif type == "armor" then
        return self.armors
    end
end


function Inventory:load(data)
    self:clear()

    self.items.max     = data.max_items     or self.items.max
    self.key_items.max = data.max_key_items or self.key_items.max
    self.weapons.max   = data.max_weapons   or self.weapons.max
    self.armors.max    = data.max_armors    or self.armors.max

    local function loadStorage(storage, from)
        for i = 1, storage.max do
            storage[i] = Registry.getItem(from[i])
        end
    end

    if data.items     then loadStorage(self.items,     data.items    ) end
    if data.key_items then loadStorage(self.key_items, data.key_items) end
    if data.weapons   then loadStorage(self.weapons,   data.weapons  ) end
    if data.armors    then loadStorage(self.armors,    data.armors   ) end
end

function Inventory:save()
    local data = {}

    data.max_items     = self.items.max
    data.max_key_items = self.key_items.max
    data.max_weapons   = self.weapons.max
    data.max_armors    = self.armors.max

    local function saveStorage(storage)
        local saved = {}
        for i = 1, storage.max do
            if storage[i] then
                saved[i] = storage[i].id
            end
        end
        return saved
    end

    data.items     = saveStorage(self.items)
    data.key_items = saveStorage(self.key_items)
    data.weapons   = saveStorage(self.weapons)
    data.armors    = saveStorage(self.armors)

    return data
end

return Inventory