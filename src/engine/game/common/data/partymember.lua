---@class PartyMember : Class
---@overload fun(...) : PartyMember
local PartyMember = Class()

function PartyMember:init()
    -- Display name
    self.name = "Player"

    -- Actor (handles overworld/battle sprites)
    self.actor = nil
    -- Light World Actor (handles overworld/battle sprites in light world maps) (optional)
    self.lw_actor = nil
    -- Dark Transition Actor (handles sprites during the dark world transition) (optional)
    self.dark_transition_actor = nil

    -- Default title / class (saved to the save file)
    self.title = "Player"
    -- Display level (saved to the save file)
    self.level = 1

    -- Light world LV (saved to the save file)
    self.lw_lv = 1
    -- Light world EXP (saved to the save file)
    self.lw_exp = 0

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
    -- Current light world health (saved to the save file)
    self.lw_health = 20

    -- Base stats (saved to the save file)
    self.stats = {
        health = 100,
        attack = 10,
        defense = 2,
        magic = 0
    }
    -- Max stats from level-ups
    self.max_stats = {}

    -- Light world stats (saved to the save file)
    self.lw_stats = {
        health = 20,
        attack = 10,
        defense = 10
    }

    -- Weapon icon in equip menu
    self.weapon_icon = "ui/menu/equip/sword"

    -- Equipment (saved to the save file)
    self.equipped = {
        weapon = nil,
        armor = {}
    }

    -- Default light world equipment item IDs (saves current equipment)
    self.lw_weapon_default = "light/pencil"
    self.lw_armor_default = "light/bandage"

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
    -- Name sprite (optional)
    self.name_sprite = nil

    -- Effect shown above enemy after attacking it
    self.attack_sprite = "effects/attack/cut"
    -- Sound played when this character attacks
    self.attack_sound = "laz_c"
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

    -- Temporary stat buffs in battles
    self.stat_buffs = {}

    -- Light world EXP requirements
    self.lw_exp_needed = {
        [ 1] = 0,
        [ 2] = 10,
        [ 3] = 30,
        [ 4] = 70,
        [ 5] = 120,
        [ 6] = 200,
        [ 7] = 300,
        [ 8] = 500,
        [ 9] = 800,
        [10] = 1200,
        [11] = 1700,
        [12] = 2500,
        [13] = 3500,
        [14] = 5000,
        [15] = 7000,
        [16] = 10000,
        [17] = 15000,
        [18] = 25000,
        [19] = 50000,
        [20] = 99999
    }
end

-- Callbacks

function PartyMember:onAttackHit(enemy, damage) end

function PartyMember:onTurnStart(battler) end
function PartyMember:onActionSelect(battler, undo) end

function PartyMember:onLevelUp(level) end

function PartyMember:onPowerSelect(menu) end
function PartyMember:onPowerDeselect(menu) end

function PartyMember:drawPowerStat(index, x, y, menu) end

function PartyMember:onSave(data) end
function PartyMember:onLoad(data) end

function PartyMember:onEquip(item, item2) return true end
function PartyMember:onUnequip(item, item2) return true end

function PartyMember:onActionBox(box, overworld) end

-- Getters

function PartyMember:getName() return self.name end
function PartyMember:getTitle() return "LV"..self:getLevel().." "..self.title end
function PartyMember:getLevel() return self.level end

function PartyMember:getLightLV() return self.lw_lv end
function PartyMember:getLightEXP() return self.lw_exp end
function PartyMember:getLightEXPNeeded(lv) return self.lw_exp_needed[lv] or 0 end

function PartyMember:getSoulPriority() return self.soul_priority end
function PartyMember:getSoulColor() return Utils.unpackColor(self.soul_color or {1, 0, 0}) end

function PartyMember:hasAct() return self.has_act end
function PartyMember:hasSpells() return self.has_spells end
function PartyMember:hasXAct() return self.has_xact end

function PartyMember:getXActName() return self.xact_name end

function PartyMember:getWeaponIcon() return self.weapon_icon end

function PartyMember:getHealth() return Game:isLight() and self.lw_health or self.health end
function PartyMember:getBaseStats(light)
    if light or (light == nil and Game:isLight()) then
        return self.lw_stats
    else
        return self.stats
    end
end

function PartyMember:getMaxStats() return self.max_stats end
function PartyMember:getMaxStat(stat)
    local max_stats = self:getMaxStats()
    return max_stats[stat]
end

function PartyMember:getStatBuffs() return self.stat_buffs end
function PartyMember:getStatBuff(stat)
    return self:getStatBuffs()[stat] or 0
end

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
        Assets.stopAndPlaySound("power")
    end
    self:setHealth(math.min(self:getStat("health"), self:getHealth() + amount))
    return self:getStat("health") == self:getHealth()
end

function PartyMember:setHealth(health)
    if Game:isLight() then
        self.lw_health = health
    else
        self.health = health
    end
end

function PartyMember:increaseStat(stat, amount, max)
    local base_stats = self:getBaseStats()
    base_stats[stat] = (base_stats[stat] or 0) + amount
    max = max or self:getMaxStat(stat)
    if max and base_stats[stat] > max then
        base_stats[stat] = max
    end
    if stat == "health" then
        self:setHealth(math.min(self:getHealth() + amount, base_stats[stat]))
    end
end

function PartyMember:addStatBuff(stat, amount, max)
    local buffs = self:getStatBuffs()
    buffs[stat] = (buffs[stat] or 0) + amount
    if max and buffs[stat] > max then
        buffs[stat] = max
    end
    self.stat_buffs = buffs
end

function PartyMember:setStatBuff(stat, amount)
    self.stat_buffs[stat] = amount
end

function PartyMember:resetBuff(stat)
    if self.stat_buffs[stat] then
        self.stat_buffs[stat] = nil
    end
end

function PartyMember:resetBuffs()
    self.stat_buffs = {}
end

function PartyMember:getReaction(item, user)
    if item then
        return item:getReaction(user.id, self.id)
    end
end

function PartyMember:getActor(light)
    if light == nil then
        light = Game.light
    end
    if light then
        return self.lw_actor or self.actor
    else
        return self.actor
    end
end

function PartyMember:getDarkTransitionActor()
    return self.dark_transition_actor
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

function PartyMember:setDarkTransitionActor(actor)
    if type(actor) == "string" then
        actor = Registry.createActor(actor)
    end
    self.dark_transition_actor = actor
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

function PartyMember:hasSpell(spell)
    for i,v in ipairs(self.spells) do
        if v == spell or (type(spell) == "string" and v.id == spell) then
            return true
        end
    end
    return false
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

function PartyMember:checkWeapon(id)
    return self:getWeapon() and self:getWeapon().id == id or false
end

function PartyMember:checkArmor(id)
    local result, count = false, 0
    for i = 1, 2 do
        if self:getArmor(i) and self:getArmor(i).id == id then
            result = true
            count = count + 1
        end
    end
    return result, count
end

function PartyMember:canEquip(item, slot_type, slot_index)
    if item then
        return item:canEquip(self, slot_type, slot_index)
    else
        return slot_type ~= "weapon"
    end
end

function PartyMember:canAutoHeal()
    return true
end

function PartyMember:autoHealAmount()
    -- TODO: Is this round or ceil? Both were used before this function was added.
    return Utils.round(self:getStat("health") / 8)
end

function PartyMember:getEquipmentBonus(stat)
    local total = 0
    for _,item in ipairs(self:getEquipment()) do
        total = total + item:getStatBonus(stat)
    end
    return total
end

function PartyMember:getStats(light)
    local stats = Utils.copy(self:getBaseStats(light))
    for _,item in ipairs(self:getEquipment()) do
        for stat, amount in pairs(item:getStatBonuses()) do
            if stats[stat] then
                stats[stat] = stats[stat] + amount
            else
                stats[stat] = amount
            end
        end
    end
    return stats
end

function PartyMember:getStat(name, default, light)
    return (self:getBaseStats(light)[name] or (default or 0)) + self:getEquipmentBonus(name) + self:getStatBuff(name)
end

function PartyMember:getBaseStat(name, default, light)
    return (self:getBaseStats(light)[name] or (default or 0))
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
    return self.flags[name]
end

function PartyMember:convertToLight()
    local last_weapon = self:getWeapon()
    local last_armors = {self:getArmor(1), self:getArmor(2)}

    self.equipped = {weapon = nil, armor = {}}

    if last_weapon then
        local result = last_weapon:convertToLightEquip(self)
        if result then
            if type(result) == "string" then
                result = Registry.createItem(result)
            end
            if isClass(result) then
                self.equipped.weapon = result
            end
        end
    end
    for i = 1, 2 do
        if last_armors[i] then
            local result = last_armors[i]:convertToLightEquip(self)
            if result then
                if type(result) == "string" then
                    result = Registry.createItem(result)
                end
                if isClass(result) then
                    self.equipped.armor[1] = result
                end
                break
            end
        end
    end

    if not self.equipped.weapon then
        self.equipped.weapon = Registry.createItem(self.lw_weapon_default)
    end
    if not self.equipped.armor[1] then
        self.equipped.armor[1] = Registry.createItem(self.lw_armor_default)
    end

    self.equipped.weapon.dark_item = last_weapon
    self.equipped.armor[1]:setFlag("dark_armors", {
        ["1"] = last_armors[1] and last_armors[1]:save(),
        ["2"] = last_armors[2] and last_armors[2]:save()
    })

    -- For deltarune accuracy, you heal here, bc health conversion code is broken
    self.lw_health = self:getStat("health")
end

function PartyMember:convertToDark()
    local last_weapon = self:getWeapon()
    local last_armor = self:getArmor(1)

    self.equipped = {weapon = nil, armor = {}}

    if last_weapon then
        local result = last_weapon:convertToDarkEquip(self)
        if result then
            if type(result) == "string" then
                result = Registry.createItem(result)
            end
            if isClass(result) then
                self.equipped.weapon = result
            end
        end
    end
    if last_armor then
        local result = last_armor:convertToDarkEquip(self)
        if result then
            if type(result) == "string" then
                result = Registry.createItem(result)
            end
            if isClass(result) then
                self.equipped.armor[1] = result
            end
        end
    end
end

-- Saving & Loading

function PartyMember:saveEquipment()
    local result = {weapon = nil, armor = {}}
    if self.equipped.weapon then
        result.weapon = self.equipped.weapon:save()
    end
    for i = 1, 2 do
        if self.equipped.armor[i] then
            result.armor[tostring(i)] = self.equipped.armor[i]:save()
        end
    end
    return result
end

function PartyMember:loadEquipment(data)
    if type(data.weapon) == "table" then
        if Registry.getItem(data.weapon.id) then
            local weapon = Registry.createItem(data.weapon.id)
            weapon:load(data.weapon)
            self:setWeapon(weapon)
        else
            Kristal.Console:error("Could not load weapon \""..data.weapon.id.."\"")
        end
    else
        if Registry.getItem(data.weapon) then
            self:setWeapon(data.weapon)
        else
            Kristal.Console:error("Could not load weapon \""..data.weapon.."\"")
        end
    end
    for i = 1, 2 do
        self:setArmor(i, nil)
    end
    if data.armor then
        for k,v in pairs(data.armor) do
            if type(v) == "table" then
                if Registry.getItem(v.id) then
                    local armor = Registry.createItem(v.id)
                    armor:load(v)
                    self:setArmor(tonumber(k), armor)
                else
                    Kristal.Console:error("Could not load armor \""..v.id.."\"")
                end
            else
                if Registry.getItem(v) then
                    self:setArmor(tonumber(k), v)
                else
                    Kristal.Console:error("Could not load armor \""..v.."\"")
                end
            end
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
        title = self.title,
        level = self.level,
        health = self.health,
        stats = self.stats,
        lw_lv = self.lw_lv,
        lw_exp = self.lw_exp,
        lw_health = self.lw_health,
        lw_stats = self.lw_stats,
        spells = self:saveSpells(),
        equipped = self:saveEquipment(),
        flags = self.flags
    }
    self:onSave(data)
    return data
end

function PartyMember:load(data)
    self.title = data.title or self.title
    self.level = data.level or self.level
    self.stats = data.stats or self.stats
    self.lw_lv = data.lw_lv or self.lw_lv
    self.lw_exp = data.lw_exp or self.lw_exp
    self.lw_stats = data.lw_stats or self.lw_stats
    if data.spells then
        self:loadSpells(data.spells)
    end
    if data.equipped then
        self:loadEquipment(data.equipped)
    end
    self.flags = data.flags or self.flags
    self.health = data.health or self:getStat("health", 0, false)
    self.lw_health = data.lw_health or self:getStat("health", 0, true)

    self:onLoad(data)
end

function PartyMember:canDeepCopy()
    return false
end

return PartyMember