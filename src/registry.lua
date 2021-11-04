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
        Registry.initObjects()
        Registry.initItems()
        Registry.initSpells()
        Registry.initPartyMembers()
        Registry.initEncounters()
        Registry.initEnemies()
        Registry.initWaves()
        Registry.initBullets()

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

function Registry.getBullet(id)
    return self.bullets[id]
end

function Registry.createBullet(id, ...)
    if self.bullets[id] then
        return self.bullets[id](...)
    else
        error("Attempt to create non existent bullet \"" .. id .. "\"")
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

function Registry.registerBullet(id, class)
    self.bullets[id] = class
end

-- Internal Functions --

function Registry.initObjects()
    for path,object in self.iterScripts("objects") do
        local id = object.id or path
        if _G[id] then
            error("Registered existing object: "..id)
        else
            _G[id] = object
        end
    end

    Kristal.modCall("onRegisterObjects")
end

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

function Registry.initBullets()
    self.bullets = {}

    for path,bullet in self.iterScripts("battles/bullets") do
        bullet.id = bullet.id or path
        self.registerBullet(bullet.id, bullet)
    end

    Kristal.modCall("onRegisterBullets")
end

function Registry.iterScripts(path)
    local result = {}

    CLASS_NAME_GETTER = function(k)
        for _,v in ipairs(result) do
            if v.path == k then
                return v.out[1]
            end
        end
        return DEFAULT_CLASS_NAME_GETTER(k)
    end

    local chunks = nil
    local parsed = {}
    local addChunk, requireChunk, parse

    addChunk = function(chunk, id)
        local success,a,b,c,d,e,f = pcall(chunk)
        if not success then
            if type(a) == "table" and a.included then
                requireChunk(a.included)
                success,a,b,c,d,e,f = pcall(chunk)
                if not success then
                    error(type(a) == "table" and a.msg or a)
                end
                table.insert(result, {out = {a,b,c,d,e,f}, path = id})
            else
                error(a)
            end
        else
            table.insert(result, {out = {a,b,c,d,e,f}, path = id})
            return a
        end
    end
    requireChunk = function(req_id)
        for full_path,chunk in pairs(chunks) do
            if not parsed[full_path] and full_path:sub(1, #path) == path then
                local id = full_path:sub(#path + 1)
                if id:sub(1, 1) == "/" then
                    id = id:sub(2)
                end
                if id == req_id then
                    parsed[full_path] = true
                    addChunk(chunk, id)
                end
            end
        end
    end
    parse = function(_chunks)
        chunks = _chunks
        parsed = {}
        for full_path,chunk in pairs(chunks) do
            if not parsed[full_path] and full_path:sub(1, #path) == path then
                local id = full_path:sub(#path + 1)
                if id:sub(1, 1) == "/" then
                    id = id:sub(2)
                end
                parsed[full_path] = true
                addChunk(chunk, id)
            end
        end
    end

    parse(self.base_scripts)
    if Mod then
        parse(Mod.info.script_chunks)
    end

    CLASS_NAME_GETTER = DEFAULT_CLASS_NAME_GETTER

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