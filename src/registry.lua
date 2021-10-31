local Registry = {}
local self = Registry

function Registry.initialize(preload)
    if not self.preload then
        self.base_scripts = {}
        for _,path in ipairs(Utils.getFilesRecursive("data", ".lua")) do
            local chunk = love.filesystem.load("data/"..path..".lua")
            self.base_scripts[path] = chunk
        end

        Registry.initActors()
    end
    if not preload then
        Registry.initItems()
        Registry.initSpells()
        Registry.initPartyMembers()
        Registry.initEncounters()
        Registry.initEnemies()
        Registry.initWaves()

        Kristal.modCall("onRegistered")
    end

    self.preload = preload
end

-- Getter Functions --

function Registry.getActor(id)
    return self.actors[id]
end

function Registry.getItem(id)
    return self.items[id]
end

function Registry.getSpell(id)
    return self.spells[id]
end

function Registry.getPartyMember(id)
    return self.party_members[id]
end

function Registry.getEncounter(id)
    return self.encounters[id]
end

function Registry.getEnemy(id)
    return self.enemies[id]
end

function Registry.createEnemy(id, ...)
    if self.enemies[id] then
        return self.enemies[id](...)
    else
        error("Attempt to create non existent enemy \"" .. id .. "\"")
    end
end

function Registry.getWave(id)
    return self.waves[id]
end

function Registry.createWave(id, ...)
    if self.waves[id] then
        return self.waves[id](...)
    else
        error("Attempt to create non existent wave \"" .. id .. "\"")
    end
end

-- Register Functions --

function Registry.registerActor(id, tbl)
    self.actors[id] = tbl
end

function Registry.registerPartyMember(id, tbl)
    self.party_members[id] = tbl
end

function Registry.registerItem(id, tbl)
    self.items[id] = tbl
end

function Registry.registerSpell(id, tbl)
    self.spells[id] = tbl
end

function Registry.registerEncounter(id, class)
    self.encounters[id] = class
end

function Registry.registerEnemy(id, class)
    self.enemies[id] = class
end

function Registry.registerWave(id, class)
    self.waves[id] = class
end

-- Internal Functions --

function Registry.initActors()
    self.actors = {}

    for path,actor in self.iterScripts("actors") do
        actor.id = actor.id or path
        self.registerActor(actor.id, actor)
    end

    Kristal.modCall("onRegisterActors")
end

function Registry.initPartyMembers()
    self.party_members = {}

    for path,char in self.iterScripts("party") do
        char.id = char.id or path
        self.registerPartyMember(char.id, char)
    end
end

function Registry.initItems()
    self.items = {}

    for path,item in self.iterScripts("item") do
        item.id = item.id or path
        self.registerItem(item.id, item)
    end

    Kristal.modCall("onRegisterItems")
end

function Registry.initSpells()
    self.spells = {}

    for path,spell in self.iterScripts("spells") do
        spell.id = spell.id or path
        self.registerSpell(spell.id, spell)
    end

    Kristal.modCall("onRegisterSpells")
end

function Registry.initEncounters()
    self.encounters = {}

    for path,encounter in self.iterScripts("battles/encounters") do
        encounter.id = encounter.id or path
        self.registerEncounter(encounter.id, encounter)
    end

    Kristal.modCall("onRegisterEncounters")
end

function Registry.initEnemies()
    self.enemies = {}

    for path,enemy in self.iterScripts("battles/enemies") do
        enemy.id = enemy.id or path
        self.registerEnemy(enemy.id, enemy)
    end

    Kristal.modCall("onRegisterEnemies")
end

function Registry.initWaves()
    self.waves = {}

    for path,wave in self.iterScripts("battles/waves") do
        wave.id = wave.id or path
        self.registerWave(wave.id, wave)
    end

    Kristal.modCall("onRegisterWaves")
end

function Registry.iterScripts(path)
    local result = {}
    local function parse(chunks)
        for full_path,chunk in pairs(chunks) do
            if full_path:sub(1, #path) == path then
                local id = full_path:sub(#path + 1)
                if id:sub(1, 1) == "/" then
                    id = id:sub(2)
                end
                local out = {chunk()}
                table.insert(result, {out = out, path = id})
            end
        end
    end
    parse(self.base_scripts)
    if Mod then
        parse(Mod.info.script_chunks)
    end
    local i = 0
---@diagnostic disable-next-line: undefined-field
    local n = table.getn(result)
    return function()
        i = i + 1
        if i <= n then
            return result[i].path, unpack(result[i].out)
        end
    end
end

return Registry