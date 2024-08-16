---@class DarkEquipMenu : Object
---@overload fun(...) : DarkEquipMenu
local DarkEquipMenu, super = Class(Object)

function DarkEquipMenu:init()
    super.init(self, 82, 112, 477, 277)

    self.draw_children_below = 0

    self.font = Assets.getFont("main")

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")
    self.ui_cant_select = Assets.newSound("ui_cant_select")
    self.ui_cancel_small = Assets.newSound("ui_cancel_small")

    self.heart_sprite = Assets.getTexture("player/heart")
    self.arrow_sprite = Assets.getTexture("ui/page_arrow_down")

    self.caption_sprites = {
        ["char"] = Assets.getTexture("ui/menu/caption_char"),
        ["equipped"] = Assets.getTexture("ui/menu/caption_equipped"),
        ["stats"] = Assets.getTexture("ui/menu/caption_stats"),
        ["weapons"] = Assets.getTexture("ui/menu/caption_weapons"),
        ["armors"] = Assets.getTexture("ui/menu/caption_armors"),
    }

    self.stat_icons = {
        ["attack"] = Assets.getTexture("ui/menu/icon/sword"),
        ["defense"] = Assets.getTexture("ui/menu/icon/armor"),
        ["magic"] = Assets.getTexture("ui/menu/icon/magic"),
    }

    self.armor_icons = {
        Assets.getTexture("ui/menu/equip/armor_1"),
        Assets.getTexture("ui/menu/equip/armor_2"),
    }

    self.bg = UIBox(0, 0, self.width, self.height)
    self.bg.layer = -1
    self.bg.debug_select = false
    self:addChild(self.bg)

    self.party = DarkMenuPartySelect(8, 48)
    self.party.focused = true
    self:addChild(self.party)

    -- PARTY, SLOTS, ITEMS
    self.state = "PARTY"

    self.selected_slot = 1

    self.selected_item = {
        ["weapons"] = 1,
        ["armors"] = 1
    }
    self.item_scroll = {
        ["weapons"] = 1,
        ["armors"] = 1
    }
end

function DarkEquipMenu:getCurrentItemType()
    if self.selected_slot == 1 then
        return "weapons"
    else
        return "armors"
    end
end

function DarkEquipMenu:getCurrentStorage()
    return Game.inventory:getStorage(self:getCurrentItemType())
end

function DarkEquipMenu:getSelectedItem()
    local type = self:getCurrentItemType()
    return Game.inventory:getItem(type, self.selected_item[type])
end

function DarkEquipMenu:getMaxItems()
    return self:getCurrentStorage().max
end

function DarkEquipMenu:canEquipSelected()
    local item = self:getSelectedItem()
    local character = self.party:getSelected()

    if self.selected_slot == 1 then
        return character:canEquip(item, "weapon", self.selected_slot)
    else
        return character:canEquip(item, "armor", self.selected_slot - 1)
    end
end

function DarkEquipMenu:getEquipPreview()
    local party = self.party:getSelected()
    local equipped = {}
    local item = self:getSelectedItem()
    if self.selected_slot == 1 then
        equipped[1] = item
    else
        equipped[1] = party.equipped.weapon
    end
    for i = 1, 2 do
        if self.selected_slot == i + 1 then
            equipped[i + 1] = item
        else
            equipped[i + 1] = party.equipped.armor[i]
        end
    end
    return equipped
end

function DarkEquipMenu:getStatsPreview()
    local party = self.party:getSelected()
    local current_stats = party:getStats()
    if self.state == "ITEMS" and self:canEquipSelected() then
        local preview_stats = Utils.copy(party.stats)
        local equipment = self:getEquipPreview()
        for i = 1, 3 do
            if equipment[i] then
                for stat, amount in pairs(equipment[i].bonuses) do
                    if preview_stats[stat] then
                        preview_stats[stat] = preview_stats[stat] + amount
                    end
                end
            end
        end
        return preview_stats, current_stats
    else
        return current_stats, current_stats
    end
end

function DarkEquipMenu:getAbilityPreview()
    local party = self.party:getSelected()
    local current_abilities = {}
    local weapon = party.equipped.weapon
    if weapon and weapon:getBonusName() then
        current_abilities[1] = { name = weapon:getBonusName(), icon = weapon.bonus_icon, color = weapon.bonus_color }
    end
    for i = 1, 2 do
        local armor = party.equipped.armor[i]
        if armor and armor:getBonusName() then
            current_abilities[i + 1] = { name = armor:getBonusName(), icon = armor.bonus_icon, color = armor.bonus_color }
        end
    end
    if self.state == "ITEMS" and self:canEquipSelected() then
        local preview_abilities = {}
        local equipment = self:getEquipPreview()
        for i = 1, 3 do
            if equipment[i] and equipment[i]:getBonusName() then
                preview_abilities[i] = {
                    name = equipment[i]:getBonusName(),
                    icon = equipment[i].bonus_icon,
                    color = equipment[i].bonus_color
                }
            end
        end
        return preview_abilities, current_abilities
    else
        return current_abilities, current_abilities
    end
end

function DarkEquipMenu:react()
    local item, party = self:getSelectedItem(), self.party:getSelected()

    for index, chara in ipairs(Game.party) do
        local reaction = chara:getReaction(item, party)
        if reaction then
            Game.world.healthbar.action_boxes[index]:react(reaction)
        end
    end
end

function DarkEquipMenu:updateDescription()
    if self.state == "PARTY" then
        Game.world.menu:setDescription("", false)
    elseif self.state == "SLOTS" then
        local party = self.party:getSelected()
        local item
        if self.selected_slot == 1 then
            item = party:getWeapon()
        else
            item = party:getArmor(self.selected_slot - 1)
        end
        Game.world.menu:setDescription(item and item:getDescription() or "", true)
    elseif self.state == "ITEMS" then
        local item = self:getSelectedItem()
        Game.world.menu:setDescription(item and item:getDescription() or "", true)
    end
end

function DarkEquipMenu:onRemove(parent)
    super.onRemove(self, parent)
    Game.world.menu:updateSelectedBoxes()
end

function DarkEquipMenu:update()
    if self.state == "PARTY" then
        if Input.pressed("cancel") then
            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()
            Game.world.menu:closeBox()
            return
        elseif Input.pressed("confirm") then
            self.state = "SLOTS"

            self.party.focused = false

            self.ui_select:stop()
            self.ui_select:play()

            self.selected_slot = 1
            self:updateDescription()
        end
    elseif self.state == "SLOTS" then
        if Input.pressed("cancel") then
            self.state = "PARTY"

            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()

            self.party.focused = true
            self:updateDescription()
            return
        elseif Input.pressed("confirm") then
            self.state = "ITEMS"

            self.ui_select:stop()
            self.ui_select:play()

            self:updateDescription()
        end
        local old_selected = self.selected_slot
        if Input.pressed("up") then
            self.selected_slot = self.selected_slot - 1
        end
        if Input.pressed("down") then
            self.selected_slot = self.selected_slot + 1
        end
        self.selected_slot = (self.selected_slot - 1) % 3 + 1
        if old_selected ~= self.selected_slot then
            self.ui_move:stop()
            self.ui_move:play()
            self:updateDescription()
        end
    elseif self.state == "ITEMS" then
        if Input.pressed("cancel") then
            self.state = "SLOTS"

            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()

            self:updateDescription()
            return
        end
        local type = self:getCurrentItemType()
        local max_items = self:getMaxItems()
        local old_selected = self.selected_item[type]
        if Input.pressed("up", true) then
            self.selected_item[type] = self.selected_item[type] - 1
        end
        if Input.pressed("down", true) then
            self.selected_item[type] = self.selected_item[type] + 1
        end
        self.selected_item[type] = Utils.clamp(self.selected_item[type], 1, max_items)
        if self.selected_item[type] ~= old_selected then
            local min_scroll = math.max(1, self.selected_item[type] - 5)
            local max_scroll = math.min(math.max(1, max_items - 5), self.selected_item[type])
            self.item_scroll[type] = Utils.clamp(self.item_scroll[type], min_scroll, max_scroll)

            self.ui_move:stop()
            self.ui_move:play()

            self:updateDescription()
        end
        if Input.pressed("confirm") then
            self:react()
            local item, party = self:getSelectedItem(), self.party:getSelected()
            if not self:canEquipSelected() then
                self.ui_cant_select:stop()
                self.ui_cant_select:play()
            else
                local swap_with = (self.selected_slot == 1) and party:getWeapon() or
                    party:getArmor(self.selected_slot - 1)

                local can_continue = true

                if item and (not item:onEquip(party, swap_with)) then can_continue = false end
                if swap_with and (not swap_with:onUnequip(party, item)) then can_continue = false end
                if (not party:onEquip(item, swap_with)) then can_continue = false end
                if (not party:onUnequip(swap_with, item)) then can_continue = false end

                -- If one of the functions returned false, don't continue

                if (not can_continue) then
                    self.ui_cant_select:stop()
                    self.ui_cant_select:play()
                    return
                end

                Assets.playSound("equip")

                if self.selected_slot == 1 then
                    party:setWeapon(item)
                else
                    party:setArmor(self.selected_slot - 1, item)
                end

                Game.inventory:setItem(self:getCurrentStorage(), self.selected_item[type], swap_with)

                self.state = "SLOTS"
                self:updateDescription()
            end
        end
    end
    super.update(self)
end

function DarkEquipMenu:draw()
    love.graphics.setFont(self.font)

    Draw.setColor(PALETTE["world_border"])
    love.graphics.rectangle("fill", 188, -24, 6, 139)
    love.graphics.rectangle("fill", -24, 109, 58, 6)
    love.graphics.rectangle("fill", 130, 109, 160, 6)
    love.graphics.rectangle("fill", 422, 109, 81, 6)
    love.graphics.rectangle("fill", 241, 109, 6, 192)

    Draw.setColor(1, 1, 1, 1)
    Draw.draw(self.caption_sprites["char"], 36, -26, 0, 2, 2)
    Draw.draw(self.caption_sprites["equipped"], 294, -26, 0, 2, 2)
    Draw.draw(self.caption_sprites["stats"], 34, 104, 0, 2, 2)
    if self.selected_slot == 1 then
        Draw.draw(self.caption_sprites["weapons"], 290, 104, 0, 2, 2)
    else
        Draw.draw(self.caption_sprites["armors"], 290, 104, 0, 2, 2)
    end

    self:drawChar()
    self:drawEquipped()
    self:drawItems()
    self:drawStats()

    super.draw(self)
end

function DarkEquipMenu:drawChar()
    local party = self.party:getSelected()
    Draw.setColor(1, 1, 1, 1)
    love.graphics.print(party:getName(), 53, -5)
end

function DarkEquipMenu:drawEquipped()
    local party = self.party:getSelected()
    Draw.setColor(1, 1, 1, 1)

    if self.state ~= "SLOTS" or self.selected_slot ~= 1 then
        local weapon_icon = Assets.getTexture(party:getWeaponIcon())
        if weapon_icon then
            Draw.draw(weapon_icon, 220, -4, 0, 2, 2)
        end
    end
    if self.state ~= "SLOTS" or self.selected_slot ~= 2 then Draw.draw(self.armor_icons[1], 220, 30, 0, 2, 2) end
    if self.state ~= "SLOTS" or self.selected_slot ~= 3 then Draw.draw(self.armor_icons[2], 220, 60, 0, 2, 2) end

    if self.state == "SLOTS" then
        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart_sprite, 226, 10 + ((self.selected_slot - 1) * 30))
    end

    for i = 1, 3 do
        self:drawEquippedItem(i, 261, 6 + ((i - 1) * 30))
    end
end

function DarkEquipMenu:drawEquippedItem(index, x, y)
    local party = self.party:getSelected()
    local item
    if index == 1 then
        item = party:getWeapon()
    else
        item = party:getArmor(index - 1)
    end
    if item then
        Draw.setColor(1, 1, 1)
        if item.icon and Assets.getTexture(item.icon) then
            Draw.draw(Assets.getTexture(item.icon), x, y, 0, 2, 2)
        end
        love.graphics.print(item:getName(), x + 22, y - 6)
    else
        Draw.setColor(PALETTE["world_dark_gray"])
        love.graphics.print("(Nothing)", x + 22, y - 6)
    end
end

function DarkEquipMenu:drawItems()
    local type = self:getCurrentItemType()
    local party = self.party:getSelected()
    local items = Game.inventory:getStorage(type)

    local x, y = 282, 124

    local scroll = self.item_scroll[type]
    for i = scroll, math.min(items.max, scroll + 5) do
        local item = items[i]
        local offset = i - scroll

        if item then
            local usable = false
            if self.selected_slot == 1 then
                usable = party:canEquip(item, "weapon", self.selected_slot)
            else
                usable = party:canEquip(item, "armor", self.selected_slot - 1)
            end
            if usable then
                Draw.setColor(1, 1, 1)
            else
                Draw.setColor(0.5, 0.5, 0.5)
            end
            if item.icon and Assets.getTexture(item.icon) then
                Draw.draw(Assets.getTexture(item.icon), x, y + (offset * 27), 0, 2, 2)
            end
            love.graphics.print(item:getName(), x + 20, y + (offset * 27) - 6)
        else
            Draw.setColor(0.25, 0.25, 0.25)
            love.graphics.print("---------", x + 20, y + (offset * 27) - 6)
        end
    end

    if self.state == "ITEMS" then
        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart_sprite, x - 20, y + 4 + ((self.selected_item[type] - scroll) * 27))

        if items.max > 6 then
            Draw.setColor(1, 1, 1)
            local sine_off = math.sin((Kristal.getTime() * 30) / 12) * 3
            if scroll + 6 <= items.max then
                Draw.draw(self.arrow_sprite, x + 187, y + 149 + sine_off)
            end
            if scroll > 1 then
                Draw.draw(self.arrow_sprite, x + 187, y + 14 - sine_off, 0, 1, -1)
            end
        end
        if items.max <= 12 then
            Draw.setColor(1, 1, 1)
            for i = 1, items.max do
                local item = items[i]
                local percentage = (i - 1) / (items.max - 1)
                if self.selected_item[type] == i and item then
                    love.graphics.rectangle("fill", x + 188, y + 21 + percentage * 110, 10, 10)
                elseif self.selected_item[type] == i then
                    love.graphics.rectangle("fill", x + 189, y + 22 + percentage * 110, 8, 8)
                elseif item then
                    love.graphics.rectangle("fill", x + 191, y + 24 + percentage * 110, 4, 4)
                else
                    love.graphics.rectangle("fill", x + 192, y + 25 + percentage * 110, 2, 2)
                end
            end
        else
            Draw.setColor(0.25, 0.25, 0.25)
            love.graphics.rectangle("fill", x + 191, y + 24, 6, 119)
            local percent = (scroll - 1) / (items.max - 6)
            Draw.setColor(1, 1, 1)
            love.graphics.rectangle("fill", x + 191, y + 24 + math.floor(percent * (119 - 6)), 6, 6)
        end
    end
end

function DarkEquipMenu:drawStats()
    local party = self.party:getSelected()
    Draw.setColor(1, 1, 1, 1)
    Draw.draw(self.stat_icons["attack"], -8, 124, 0, 2, 2)
    Draw.draw(self.stat_icons["defense"], -8, 151, 0, 2, 2)
    Draw.draw(self.stat_icons["magic"], -8, 178, 0, 2, 2)
    love.graphics.print("Attack:", 18, 118)
    love.graphics.print("Defense:", 18, 145)
    love.graphics.print("Magic:", 18, 172)
    local stats, compare = self:getStatsPreview()
    self:drawStatPreview("attack", 148, 118, stats, compare, self:getCurrentItemType() == "weapons")
    self:drawStatPreview("defense", 148, 145, stats, compare, false)
    self:drawStatPreview("magic", 148, 172, stats, compare, false)
    local abilities, ability_comp = self:getAbilityPreview()
    for i = 1, 3 do
        self:drawAbilityPreview(i, -8, 178 + (27 * i), abilities, ability_comp)
    end
end

function DarkEquipMenu:drawStatPreview(stat, x, y, stats, compare, show_difference)
    local stat_num = stats[stat] or 0
    local comp_num = compare[stat] or 0
    if stat_num > comp_num then
        Draw.setColor(1, 1, 0)
    elseif stat_num < comp_num then
        Draw.setColor(1, 0, 0)
    else
        Draw.setColor(1, 1, 1)
    end
    local display = tostring(stat_num)
    if show_difference and stat_num ~= comp_num then
        if Game:getConfig("oldUIPositions") or stat_num < comp_num then
            display = display .. "(" .. (stat_num - comp_num) .. ")"
        else
            display = display .. "(+" .. (stat_num - comp_num) .. ")"
        end
    end
    love.graphics.print(display, x, y)
end

function DarkEquipMenu:drawAbilityPreview(index, x, y, abilities, compare)
    local name = abilities[index] and abilities[index].name or nil
    local comp_name = compare[index] and compare[index].name or nil
    if abilities[index] and abilities[index].icon then
        local yoff = self.state == "ITEMS" and -6 or 2
        local texture = Assets.getTexture(abilities[index].icon)
        if texture then
            Draw.setColor(abilities[index].color)
            Draw.draw(texture, x, y + yoff, 0, 2, 2)
        end
    end
    if name ~= comp_name then
        if name ~= nil then
            Draw.setColor(1, 1, 0)
        else
            Draw.setColor(1, 0, 0)
        end
    else
        if (name and self.state ~= "ITEMS") or (self.state == "ITEMS" and self.selected_slot == index and self:canEquipSelected()) then
            Draw.setColor(1, 1, 1)
        else
            Draw.setColor(0.25, 0.25, 0.25)
        end
    end
    love.graphics.print(name or "(No ability.)", x + 26, y - 6)
end

return DarkEquipMenu
