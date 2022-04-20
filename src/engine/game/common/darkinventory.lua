local DarkInventory, super = Class(Inventory)

function DarkInventory:init()
    super:init(self)

    self.storage_for_type = {
        ["item"]   = "items",
        ["key"]    = "key_items",
        ["weapon"] = "weapons",
        ["armor"]  = "armors",
    }

    self.storage_enabled = (Game.chapter > 1)

    -- Order the storages are converted to the light world
    self.convert_order = {"key_items", "weapons", "armors", "items", "storage"}
end

function DarkInventory:clear()
    super:clear(self)

    self.storages = {
        ["items"]     = {id = "items",     max = 12, sorted = true,  name = "ITEMs",     fallback = "storage"},
        ["key_items"] = {id = "key_items", max = 12, sorted = true,  name = "KEY ITEMs", fallback = nil      },
        ["weapons"]   = {id = "weapons",   max = 48, sorted = false, name = "WEAPONs",   fallback = nil      },
        ["armors"]    = {id = "armors",    max = 48, sorted = false, name = "ARMORs",    fallback = nil      },
        ["storage"]   = {id = "storage",   max = 24, sorted = false, name = "STORAGE",   fallback = nil      },
    }
end

function DarkInventory:convertToLight()
    local new_inventory = LightInventory()

    local was_storage_enabled = new_inventory.storage_enabled
    new_inventory.storage_enabled = true

    Kristal.callEvent("onConvertToLight", new_inventory)

    for _,storage_id in ipairs(self.convert_order) do
        local storage = Utils.copy(self:getStorage(storage_id))
        for i = 1, storage.max do
            local item = storage[i]
            if item then
                local result = item:convertToLight(new_inventory)

                if result then
                    self:removeItem(item)

                    if type(result) == "string" then
                        result = Registry.createItem(result)
                    end
                    if isClass(result) then
                        result.dark_item = item
                        result.dark_location = {storage = storage.id, index = i}
                        new_inventory:addItem(result)
                    end
                end
            end
        end
    end

    local ball = Registry.createItem("light/ball_of_junk", self)
    new_inventory:addItemTo("items", 1, ball)

    new_inventory.storage_enabled = was_storage_enabled

    return new_inventory
end

return DarkInventory