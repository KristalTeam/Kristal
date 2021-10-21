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