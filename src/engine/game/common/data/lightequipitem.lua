---@class LightEquipItem : Item
---@overload fun(...) : LightEquipItem
local LightEquipItem, super = Class(Item)

function LightEquipItem:showEquipText()
    Game.world:showText("* You equipped the "..self:getName()..".")
end

function LightEquipItem:onWorldUse(target)
    Assets.playSound("item")
    local chara = Game.party[1]
    local replacing = nil
    if self.type == "weapon" then
        if chara:getWeapon() then
            replacing = chara:getWeapon()
            replacing:onUnequip(chara, self)
            Game.inventory:replaceItem(self, replacing)
        end
        chara:setWeapon(self)
    elseif self.type == "armor" then
        if chara:getArmor(1) then
            replacing = chara:getArmor(1)
            replacing:onUnequip(chara, self)
            Game.inventory:replaceItem(self, replacing)
        end
        chara:setArmor(1, self)
    else
        error("LightEquipItem "..self.id.." invalid type: "..self.type)
    end

    self:onEquip(chara, replacing)

    self:showEquipText()
    return false
end

function LightEquipItem:setArmor(i, item)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    local current_items = self:createArmorItems()

    local last_item = current_items[i]

    current_items[i] = item
    self:setArmorItems(current_items)

    return last_item
end

function LightEquipItem:createArmorItems()
    local armors = self:getFlag("dark_armors")
    if armors then
        local armor_items = {}

        if armors["1"] then
            armor_items[1] = Registry.createItem(armors["1"].id)
            armor_items[1]:load(armors["1"])
        end

        if armors["2"] then
            armor_items[2] = Registry.createItem(armors["2"].id)
            armor_items[2]:load(armors["2"])
        end

        return armor_items
    else
        local armor_result = super.convertToDark(self)
        if type(armor_result) == "string" then
            armor_result = Registry.createItem(armor_result)
        end
        if armor_result and isClass(armor_result) then
            return {armor_result}
        else
            return {}
        end
    end
end

function LightEquipItem:setArmorItems(armor_items)
    local armors = {}

    if armor_items[1] then
        armors["1"] = armor_items[1]:save()
    end

    if armor_items[2] then
        armors["2"] = armor_items[2]:save()
    end

    self:setFlag("dark_armors", armors)
end

function LightEquipItem:convertToDarkEquip(chara)
    if self.type == "armor" then
        local armors = self:createArmorItems()
        if armors[1] then
            chara:setArmor(1, armors[1])
        end
        if armors[2] then
            chara:setArmor(2, armors[2])
        end
        return true
    end
    return self:convertToDark()
end

function LightEquipItem:convertToDark(inventory)
    if self.type == "armor" then
        local armors = self:createArmorItems()
        if armors[1] then
            inventory:addItem(armors[1])
        end
        if armors[2] then
            inventory:addItem(armors[2])
        end
        return true
    else
        return super.convertToDark(self, inventory)
    end
end

return LightEquipItem