local PartyMember = Class()

function PartyMember:init(o)
    o = o or {}

    -- Party member ID (optional, defaults to path)
    self.id = nil
    -- Display name
    self.name = "Player"

    -- Actor ID (handles overworld/battle sprites)
    self.actor = "kris"
    -- Light World Actor ID (handles overworld/battle sprites in light world maps) (optional)
    self.lw_actor = nil

    -- Display level (saved to the save file)
    self.level = 1
    -- Default title / class (saved to the save file)
    self.title = "Player"

    -- Whether the party member can act / use spells
    self.has_act = true
    self.has_spells = false

    -- X-Action name (displayed in this character's spell menu)
    self.xact_name = "?-Action"

    -- Spells by id
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
        weapon = "wood_blade",
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

    -- Load the table
    for k,v in pairs(o) do
        self[k] = v
    end
end

function PartyMember:getTitle()
    return "LV"..self.level.." "..self.title
end

function PartyMember:onAttackHit(enemy, damage) end

function PartyMember:onLevelUp(level) end

function PartyMember:onPowerSelect(menu) end
function PartyMember:onPowerDeselect(menu) end

function PartyMember:drawPowerStat(index, x, y, menu) end

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

function PartyMember:getEquipment()
    local result = {}
    if self.equipped.weapon then
        table.insert(result, Registry.getItem(self.equipped.weapon))
    end
    for i = 1, 2 do
        if self.equipped.armor[i] then
            table.insert(result, Registry.getItem(self.equipped.armor[i]))
        end
    end
    return result
end

function PartyMember:getWeapon()
    if self.equipped.weapon then
        return Registry.getItem(self.equipped.weapon)
    end
end

function PartyMember:getArmor(i)
    if self.equipped.armor[i] then
        return Registry.getItem(self.equipped.armor[i])
    end
end

function PartyMember:getEquipmentBonus(stat)
    local total = 0
    for _,item in ipairs(self:getEquipment()) do
        if item.bonuses[stat] then
            total = total + item.bonuses[stat]
        end
    end
    return total
end

function PartyMember:getStats()
    local stats = Utils.copy(self.stats)
    for _,item in ipairs(self:getEquipment()) do
        for stat,amount in pairs(item.bonuses) do
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
    return self.flags[name] or default
end

function PartyMember:setFlag(name, value)
    self.flags[name] = value
end

function PartyMember:addFlag(name, amount)
    self.flags[name] = (self.flags[name] or 0) + (amount or 1)
end

function PartyMember:save()
    local data = {
        id = self.id,
        spells = self.spells,
        health = self.health,
        stats = self.stats,
        equipped = self.equipped,
        flags = self.flags
    }
    if self.onSave then
        self:onSave(data)
    end
    return data
end

function PartyMember:load(data)
    self.spells = data.spells or self.spells
    self.stats = data.stats or self.stats
    self.equipped = data.equipped or self.equipped
    self.flags = data.flags or self.flags
    self.health = data.health or self:getStat("health")

    if self.onLoad then
        self:onLoad(data)
    end
end

return PartyMember