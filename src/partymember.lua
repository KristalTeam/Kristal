local PartyMember = Class()

function PartyMember:init(o)
    o = o or {}

    -- Generic variables table (saved to the save file)
    self.vars = {}

    -- Load the table
    for k,v in pairs(o) do
        self[k] = v
    end
end

function PartyMember:getEquipment()
    local result = {}
    if self.equipped.weapon then
        table.insert(result, Registry.getItem(self.equipped.weapon))
    end
    for _,armor in ipairs(self.equipped.armor) do
        table.insert(result, Registry.getItem(armor))
    end
    return result
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

function PartyMember:save()
    local data = {
        id = self.id,
        health = self.health,
        stats = self.stats,
        equipped = self.equipped,
        vars = self.vars
    }
    if self.onSave then
        self:onSave(data)
    end
    return data
end

function PartyMember:load(data)
    self.stats = data.stats or self.stats
    self.health = data.health or self.stats.health
    self.equipped = data.equipped or self.equipped
    self.vars = data.vars or self.vars

    if self.onLoad then
        self:onLoad(data)
    end
end

return PartyMember