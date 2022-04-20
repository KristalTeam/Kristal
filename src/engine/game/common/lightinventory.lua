local LightInventory, super = Class(Inventory)

function LightInventory:init()
    super:init(self)

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
    super:clear(self)

    self.storages = {
        ["items"] = {id = "items", max = 8,  sorted = true, name = "INVENTORY", fallback = "box_a"},
        ["box_a"] = {id = "box_a", max = 10, sorted = true, name = "BOX",       fallback = "box_b"},
        ["box_b"] = {id = "box_b", max = 10, sorted = true, name = "BOX",       fallback = nil    },
    }
end

function LightInventory:convertToDark()
    local new_inventory = DarkInventory()

    local was_storage_enabled = new_inventory.storage_enabled
    new_inventory.storage_enabled = true

    Kristal.callEvent("onConvertToDark", new_inventory)

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

return LightInventory
