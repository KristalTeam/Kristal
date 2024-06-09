---@class LightInventory : Inventory
---@overload fun(...) : LightInventory
local LightInventory, super = Class(Inventory)

function LightInventory:init()
    super.init(self)

    -- Oops ! All "items"
    self.storage_for_type = {
        ["item"]   = "items",
        ["key"]    = "items",
        ["weapon"] = "items",
        ["armor"]  = "items",
    }

    -- Never true for the light world, as Undertale doesnt use storage fallback
    -- but temporarily set to true during item conversion (to overflow to storage)
    self.storage_enabled = false

    -- Order the storages are converted to the dark world
    self.convert_order = {"items", "box_a", "box_b"}
end

function LightInventory:clear()
    super.clear(self)

    self.storages = {
        ["items"] = {id = "items", max = 8,  sorted = true, name = "INVENTORY", fallback = "box_a"},
        ["box_a"] = {id = "box_a", max = 10, sorted = true, name = "BOX",       fallback = "box_b"},
        ["box_b"] = {id = "box_b", max = 10, sorted = true, name = "BOX",       fallback = nil    },
    }

    Kristal.callEvent(KRISTAL_EVENT.createLightInventory, self)
end

function LightInventory:convertToDark()
    local new_inventory = DarkInventory()

    local was_storage_enabled = new_inventory.storage_enabled
    new_inventory.storage_enabled = true

    Kristal.callEvent(KRISTAL_EVENT.onConvertToDark, new_inventory)

    for _,storage_id in ipairs(self.convert_order) do
        local storage = Utils.copy(self:getStorage(storage_id))
        for i = 1, storage.max do
            local item = storage[i]
            if item then
                local result = item:convertToDark(new_inventory)

                if result then
                    self:removeItem(item)

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

    for _,base_storage in pairs(self.storages) do
        local storage = Utils.copy(base_storage)
        for i = 1, storage.max do
            local item = storage[i]
            if item then
                item.light_item = item
                item.light_location = {storage = storage.id, index = i}

                new_inventory:addItemTo("light", item)

                self:removeItem(item)
            end
        end
    end

    new_inventory.storage_enabled = was_storage_enabled

    return new_inventory
end

function LightInventory:getDarkInventory()
    local junk_ball = self:getItemByID("light/ball_of_junk")

    if not junk_ball then
        junk_ball = self:addItem("light/ball_of_junk")
    end

    return junk_ball.inventory
end

function LightInventory:getDefaultStorage(item_type)
    if isClass(item_type) then -- Passing in an item
        item_type = item_type.type
    end
    return self:getStorage(self.storage_for_type[item_type])
end

-- Item give overrides for Dark World items

---@return Item|nil
function LightInventory:addItem(item, ignore_dark)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    if ignore_dark or item.light then
        return super.addItem(self, item)
    else
        local dark_inv = self:getDarkInventory()
        return dark_inv:addItem(item)
    end
end

function LightInventory:tryGiveItem(item, ignore_dark)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    if ignore_dark or item.light then
        return super.tryGiveItem(self, item, ignore_dark)
    else
        local dark_inv = self:getDarkInventory()
        local result = dark_inv:addItem(item)
        if result then
            return true, "* ([color:yellow]"..item:getName().."[color:reset] was added to your [color:yellow]BALL OF JUNK[color:reset].)"
        else
            return false, "* (Your [color:yellow]BALL OF JUNK[color:reset] is too big to take [color:yellow]"..item:getName().."[color:reset].)"
        end
    end
end

return LightInventory
