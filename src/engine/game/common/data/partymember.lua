local PartyMember = Class()

function PartyMember:init()
    -- Display name
    self.name = "Player"

    -- Actor (handles overworld/battle sprites)
    self.actor = nil
    -- Light World Actor (handles overworld/battle sprites in light world maps) (optional)
    self.lw_actor = nil

    -- Display level (saved to the save file)
    self.level = 1
    -- Default title / class (saved to the save file)
    self.title = "Player"

    -- Determines which character the soul comes from (higher number = higher priority)
    self.soul_priority = 2
    -- The color of this character's soul (optional, defaults to red)
    self.soul_color = {1, 0, 0}

    -- Whether the party member can act / use spells
    self.has_act = true
    self.has_spells = false

    -- Whether the party member can use their X-Action
    self.has_xact = true
    -- X-Action name (displayed in this character's spell menu)
    self.xact_name = "?-Action"

    -- Spells
    self.spells = {}

    -- Current health (saved to the save file)
    self.health = 100

    -- Base stats (saved to the save file)
    self.stats = {
        health = 100,
        attack = 10,
        defense = 2,
        magic = 0
    }

    -- Weapon icon in equip menu
    self.weapon_icon = "ui/menu/equip/sword"

    -- Equipment (saved to the save file)
    self.equipped = {
        weapon = nil,
        armor = {}
    }

    -- Character color (for action box outline and hp bar)
    self.color = {1, 1, 1}
    -- Damage color (for the number when attacking enemies) (defaults to the main color)
    self.dmg_color = nil
    -- Attack bar color (for the target bar used in attack mode) (defaults to the main color)
    self.attack_bar_color = nil
    -- Attack box color (for the attack area in attack mode) (defaults to darkened main color)
    self.attack_box_color = nil
    -- X-Action color (for the color of X-Action menu items) (defaults to the main color)
    self.xact_color = nil

    -- Head icon in the equip / power menu
    self.menu_icon = "party/kris/head"
    -- Path to head icons used in battle
    self.head_icons = "party/kris/icon"
    -- Name sprite (TODO: optional)
    self.name_sprite = "party/kris/name"

    -- Effect shown above enemy after attacking it
    self.attack_sprite = "effects/attack/cut"
    -- Sound played when this character attacks
    self.attack_sound = "snd_laz_c"
    -- Pitch of the attack sound
    self.attack_pitch = 1

    -- Battle position offset (optional)
    self.battle_offset = nil
    -- Head icon position offset (optional)
    self.head_icon_offset = nil
    -- Menu icon position offset (optional)
    self.menu_icon_offset = nil

    -- Message shown on gameover (optional)
    self.gameover_message = nil

    -- Character flags (saved to the save file)
    self.flags = {}
end

-- Callbacks

function PartyMember:onAttackHit(enemy, damage) end

function PartyMember:onLevelUp(level) end

function PartyMember:onPowerSelect(menu) end
function PartyMember:onPowerDeselect(menu) end

function PartyMember:drawPowerStat(index, x, y, menu) end

function PartyMember:onSave(data) end
function PartyMember:onLoad(data) end

-- Getters

function PartyMember:getName() return self.name end
function PartyMember:getTitle() return "LV"..self.level.." "..self.title end

function PartyMember:getSoulPriority() return self.soul_priority end
function PartyMember:getSoulColor() return Utils.unpackColor(self.soul_color or {1, 0, 0}) end

function PartyMember:hasAct() return self.has_act end
function PartyMember:hasSpells() return self.has_spells end
function PartyMember:hasXAct() return self.has_xact end

function PartyMember:getXActName() return self.xact_name end

function PartyMember:getWeaponIcon() return self.weapon_icon end

function PartyMember:getColor() return Utils.unpackColor(self.color) end
function PartyMember:getDamageColor()
    if self.dmg_color then
        return Utils.unpackColor(self.dmg_color)
    else
        return self:getColor()
    end
end
function PartyMember:getAttackBarColor()
    if self.attack_bar_color then
        return Utils.unpackColor(self.attack_bar_color)
    else
        return self:getColor()
    end
end
function PartyMember:getAttackBoxColor()
    if self.attack_box_color then
        return Utils.unpackColor(self.attack_box_color)
    else
        local r, g, b, a = self:getColor()
        return r * 0.5, g * 0.5, b * 0.5, a
    end
end
function PartyMember:getXActColor()
    if self.xact_color then
        return Utils.unpackColor(self.xact_color)
    else
        return self:getColor()
    end
end

function PartyMember:getMenuIcon() return self.menu_icon end
function PartyMember:getHeadIcons() return self.head_icons end
function PartyMember:getNameSprite() return self.name_sprite end

function PartyMember:getAttackSprite() return self.attack_sprite end
function PartyMember:getAttackSound() return self.attack_sound end
function PartyMember:getAttackPitch() return self.attack_pitch end

function PartyMember:getBattleOffset() return unpack(self.battle_offset or {0, 0}) end
function PartyMember:getHeadIconOffset() return unpack(self.head_icon_offset or {0, 0}) end
function PartyMember:getMenuIconOffset() return unpack(self.menu_icon_offset or {0, 0}) end

function PartyMember:getGameOverMessage() return self.gameover_message end

-- Functions / Getters & Setters

function PartyMember:heal(amount, playsound)
    if playsound == nil or playsound then
        Assets.playSound("snd_power")
    end
    self.health = math.min(self:getStat("health"), self.health + amount)
end

function PartyMember:increaseStat(stat, amount, max)
    self.stats[stat] = (self.stats[stat] or 0) + amount
    if max and self.stats[stat] > max then
        self.stats[stat] = max
    end
    if stat == "health" then
        self.health = math.min(self.health + amount, self.stats[stat])
    end
end

function PartyMember:getReaction(item, user)
    if item then
        return item:getReaction(user.id, self.id)
    end
end

function PartyMember:getActor(light)
    if light == nil then
        light = Game and Game.world and Game.world.light
    end
    if light then
        return self.lw_actor or self.actor
    else
        return self.actor
    end
end

function PartyMember:setActor(actor)
    if type(actor) == "string" then
        actor = Registry.createActor(actor)
    end
    self.actor = actor
end

function PartyMember:setLightActor(actor)
    if type(actor) == "string" then
        actor = Registry.createActor(actor)
    end
    self.lw_actor = actor
end

function PartyMember:getSpells()
    return self.spells
end

function PartyMember:addSpell(spell)
    if type(spell) == "string" then
        spell = Registry.createSpell(spell)
    end
    table.insert(self.spells, spell)
end

function PartyMember:removeSpell(spell)
    for i,v in ipairs(self.spells) do
        if v == spell or (type(spell) == "string" and v.id == spell) then
            table.remove(self.spells, i)
            return
        end
    end
end

function PartyMember:getEquipment()
    local result = {}
    if self.equipped.weapon then
        table.insert(result, self.equipped.weapon)
    end
    for i = 1, 2 do
        if self.equipped.armor[i] then
            table.insert(result, self.equipped.armor[i])
        end
    end
    return result
end

function PartyMember:getWeapon()
    return self.equipped.weapon
end

function PartyMember:getArmor(i)
    return self.equipped.armor[i]
end

function PartyMember:setWeapon(item)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    self.equipped.weapon = item
end

function PartyMember:setArmor(i, item)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    self.equipped.armor[i] = item
end

function PartyMember:canEquip(item, slot_type, slot_index)
    if item then
        return item:canEquip(self, slot_type, slot_index)
    else
        return slot_type ~= "weapon"
    end
end

function PartyMember:getEquipmentBonus(stat)
    local total = 0
    for _,item in ipairs(self:getEquipment()) do
        total = total + item:getStatBonus(stat)
    end
    return total
end

function PartyMember:getStats()
    local stats = Utils.copy(self.stats)
    for _,item in ipairs(self:getEquipment()) do
        for stat,amount in pairs(item:getStatBonuses()) do
            if stats[stat] then
                stats[stat] = stats[stat] + amount
            else
                stats[stat] = amount
            end
        end
    end
    return stats
end

function PartyMember:getStat(name, default)
    return (self.stats[name] or (default or 0)) + self:getEquipmentBonus(name)
end

function PartyMember:getFlag(name, default)
    local result = self.flags[name]
    if result == nil then
        return default
    else
        return result
    end
end

function PartyMember:setFlag(name, value)
    self.flags[name] = value
end

function PartyMember:addFlag(name, amount)
    self.flags[name] = (self.flags[name] or 0) + (amount or 1)
end

-- Saving & Loading

function PartyMember:saveEquipment()
    local result = {weapon = nil, armor = {}}
    if self.equipped.weapon then
        result.weapon = self.equipped.weapon.id
    end
    for i = 1, 2 do
        if self.equipped.armor[i] then
            result.armor[tostring(i)] = self.equipped.armor[i].id
        end
    end
    return result
end

function PartyMember:loadEquipment(data)
    self:setWeapon(data.weapon)
    for i = 1, 2 do
        self:setArmor(i, nil)
    end
    if data.armor then
        for k,v in pairs(data.armor) do
            self:setArmor(tonumber(k), v)
        end
    end
end

function PartyMember:saveSpells()
    local result = {}
    for _,v in pairs(self.spells) do
        table.insert(result, v.id)
    end
    return result
end

function PartyMember:loadSpells(data)
    self.spells = {}
    for _,v in ipairs(data) do
        self:addSpell(v)
    end
end

function PartyMember:save()
    local data = {
        id = self.id,
        health = self.health,
        stats = self.stats,
        spells = self:saveSpells(),
        equipped = self:saveEquipment(),
        flags = self.flags
    }
    self:onSave(data)
    return data
end

function PartyMember:load(data)
    self.stats = data.stats or self.stats
    if data.spells then
        self:loadSpells(data.spells)
    end
    if data.equipped then
        self:loadEquipment(data.equipped)
    end
    self.flags = data.flags or self.flags
    self.health = data.health or self:getStat("health")

    self:onLoad(data)
end

return PartyMember