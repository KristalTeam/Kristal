local Registry = {}
local self = Registry

Registry.new_objects = {}
Registry.last_objects = {}

function Registry.initialize(preload)
    if not self.preload then
        self.base_scripts = {}
        local chapter = Kristal.getModOption("chapter") or 2
        Game.chapter = chapter
        for _,path in ipairs(Utils.getFilesRecursive("data/common", ".lua")) do
            local chunk = love.filesystem.load("data/common/"..path..".lua")
            self.base_scripts["data/"..path] = chunk
        end
        for _,path in ipairs(Utils.getFilesRecursive("data/chapter_"..tostring(chapter), ".lua")) do
            local chunk = love.filesystem.load("data/chapter_"..tostring(chapter).."/"..path..".lua")
            self.base_scripts["data/"..path] = chunk
        end
        for _,path in ipairs(Utils.getFilesRecursive("datamod/chapter_"..tostring(chapter), ".lua")) do
            local chunk = love.filesystem.load("datamod/chapter_"..tostring(chapter).."/"..path..".lua")
            self.base_scripts["datamod/"..path] = chunk
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
        Registry.initCutscenes()
        Registry.initTilesets()
        Registry.initMaps()

        Kristal.callEvent("onRegistered")
    end

    self.preload = preload
end

function Registry.restoreOverridenObjects()
    for id,_ in pairs(self.new_objects) do
        _G[id] = self.last_objects[id]
    end
    self.new_objects = {}
    self.last_objects = {}
end

-- Getter Functions --

function Registry.getActor(id)
    return self.actors[id]
end

function Registry.getItem(id)
    return self.items[id]
end

function Registry.createItem(id, ...)
    if self.items[id] then
        return self.items[id](...)
    else
        error("Attempt to create non existent item \"" .. id .. "\"")
    end
end

function Registry.getSpell(id)
    return self.spells[id]
end

function Registry.getPartyMember(id)
    return self.party_members[id]
end

function Registry.createPartyMember(id, ...)
    if self.party_members[id] then
        return self.party_members[id](...)
    else
        error("Attempt to create non existent party member \"" .. id .. "\"")
    end
end

function Registry.getEncounter(id)
    return self.encounters[id]
end

function Registry.createEncounter(id, ...)
    if self.encounters[id] then
        return self.encounters[id](...)
    else
        error("Attempt to create non existent encounter \"" .. id .. "\"")
    end
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

function Registry.getWorldBullet(id)
    return self.world_bullets[id]
end

function Registry.createWorldBullet(id, ...)
    if self.world_bullets[id] then
        return self.world_bullets[id](...)
    else
        error("Attempt to create non existent world bullet \"" .. id .. "\"")
    end
end

function Registry.getWorldCutscene(group, id)
    local cutscene = self.world_cutscenes[group]
    if type(cutscene) == "table" then
        return cutscene[id], true
    elseif type(cutscene) == "function" then
        return cutscene, false
    end
end

function Registry.getBattleCutscene(group, id)
    local cutscene = self.battle_cutscenes[group]
    if type(cutscene) == "table" then
        return cutscene[id], true
    elseif type(cutscene) == "function" then
        return cutscene, false
    end
end

function Registry.getTileset(id)
    return self.tilesets[id]
end

function Registry.getMap(id)
    return self.maps[id]
end

function Registry.createMap(id, world, ...)
    if self.maps[id] then
        local map = self.maps[id](world, self.map_data[id], ...)
        map.id = id
        return map
    elseif self.map_data[id] then
        local map = Map(world, self.map_data[id], ...)
        map.id = id
        return map
    else
        error("Attempt to create non existent map \"" .. id .. "\"")
    end
end

function Registry.getMapData(id)
    return self.map_data[id]
end

-- Register Functions --

function Registry.registerActor(id, tbl)
    self.actors[id] = tbl
    tbl.animations = tbl.animations or {}
    tbl.offsets = tbl.offsets or {}
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

function Registry.registerWorldBullet(id, class)
    self.world_bullets[id] = class
end

function Registry.registerWorldCutscene(id, cutscene)
    self.world_cutscenes[id] = cutscene
end

function Registry.registerBattleCutscene(id, cutscene)
    self.battle_cutscenes[id] = cutscene
end

function Registry.registerTileset(id, class)
    self.tilesets[id] = class
end

function Registry.registerMapData(id, data)
    self.map_data[id] = data
end

function Registry.registerMap(id, class)
    self.maps[id] = class
end

-- Internal Functions --

function Registry.initObjects()
    for _,path,object in self.iterScripts("objects") do
        local path_tbl = Utils.split(path, "/")
        local new_path = path_tbl[#path_tbl]

        local id = object.id or new_path

        if id:lower() == id then
            print("WARNING: Object '"..id.."' registered in lowercase!")
        end

        if _G[id] then
            print("WARNING: Object '"..id.."' already exists, replacing")
            if not self.last_objects[id] then
                self.last_objects[id] = _G[id]
            end
        end

        self.new_objects[id] = object

        _G[id] = object
    end

    Kristal.callEvent("onRegisterObjects")
end

function Registry.initActors()
    self.actors = {}

    for _,path,actor in self.iterScripts("data/actors") do
        actor.id = actor.id or path
        self.registerActor(actor.id, actor)
    end
    for id,mod in self.iterMods("datamod/actors") do
        mod(self.actors[id])
    end

    Kristal.callEvent("onRegisterActors")
end

function Registry.initPartyMembers()
    self.party_members = {}

    for _,path,char in self.iterScripts("data/party") do
        char.id = char.id or path
        self.registerPartyMember(char.id, char)
    end

    Kristal.callEvent("onRegisterPartyMembers")
end

function Registry.initItems()
    self.items = {}

    for _,path,item in self.iterScripts("data/items") do
        item.id = item.id or path
        self.registerItem(item.id, item)
    end

    Kristal.callEvent("onRegisterItems")
end

function Registry.initSpells()
    self.spells = {}

    for _,path,spell in self.iterScripts("data/spells") do
        spell.id = spell.id or path
        self.registerSpell(spell.id, spell)
    end
    for id,mod in self.iterMods("datamod/spells") do
        mod(self.spells[id])
    end

    Kristal.callEvent("onRegisterSpells")
end

function Registry.initEncounters()
    self.encounters = {}

    for _,path,encounter in self.iterScripts("battle/encounters") do
        encounter.id = encounter.id or path
        self.registerEncounter(encounter.id, encounter)
    end

    Kristal.callEvent("onRegisterEncounters")
end

function Registry.initEnemies()
    self.enemies = {}

    for _,path,enemy in self.iterScripts("battle/enemies") do
        enemy.id = enemy.id or path
        self.registerEnemy(enemy.id, enemy)
    end

    Kristal.callEvent("onRegisterEnemies")
end

function Registry.initWaves()
    self.waves = {}

    for _,path,wave in self.iterScripts("battle/waves") do
        wave.id = wave.id or path
        self.registerWave(wave.id, wave)
    end

    Kristal.callEvent("onRegisterWaves")
end

function Registry.initBullets()
    self.bullets = {}
    self.world_bullets = {}

    for _,path,bullet in self.iterScripts("battle/bullets") do
        bullet.id = bullet.id or path
        self.registerBullet(bullet.id, bullet)
    end

    for _,path,bullet in self.iterScripts("world/bullets") do
        bullet.id = bullet.id or path
        self.registerWorldBullet(bullet.id, bullet)
    end

    Kristal.callEvent("onRegisterBullets")
end

function Registry.initCutscenes()
    self.world_cutscenes = {}
    self.battle_cutscenes = {}

    for _,path,cutscene in self.iterScripts("world/cutscenes") do
        self.registerWorldCutscene(path, cutscene)
    end
    for _,path,cutscene in self.iterScripts("battle/cutscenes") do
        self.registerBattleCutscene(path, cutscene)
    end

    Kristal.callEvent("onRegisterCutscenes")
end

function Registry.initTilesets()
    self.tilesets = {}

    for full_path,path,data in self.iterScripts("world/tilesets") do
        data.full_path = full_path
        data.id = path
        self.registerTileset(path, Tileset(data, full_path))
    end

    Kristal.callEvent("onRegisterTilesets")
end

function Registry.initMaps()
    self.maps = {}
    self.map_data = {}

    for full_path,path,data in self.iterScripts("world/maps") do
        local split_path = Utils.split(path, "/", true)
        if isClass(data) then
            if split_path[#split_path] == "map" then
                self.registerMap(table.concat(split_path, "/", 1, #split_path-1), data)
            else
                self.registerMap(path, data)
            end
        else
            data.full_path = full_path
            if split_path[#split_path] == "data" then
                data.id = table.concat(split_path, "/", 1, #split_path-1)
                self.registerMapData(data.id, data)
            else
                data.id = path
                self.registerMapData(path, data)
            end
        end
    end

    Kristal.callEvent("onRegisterMaps")
end

function Registry.iterScripts(base_path)
    local result = {}

    CLASS_NAME_GETTER = function(k)
        for _,v in ipairs(result) do
            if v.id == k then
                return v.out[1]
            end
        end
        return DEFAULT_CLASS_NAME_GETTER(k)
    end

    local chunks = nil
    local parsed = {}
    local queued_parse = {}
    local addChunk, parse

    addChunk = function(path, chunk, file, full_path)
        local success,a,b,c,d,e,f = pcall(chunk)
        if not success then
            if type(a) == "table" and a.included then
                table.insert(queued_parse, {path, chunk, file, full_path})
                return false
            else
                error(a)
            end
        else
            local id = type(a) == "table" and a.id or file
            table.insert(result, {out = {a,b,c,d,e,f}, path = file, id = id, full_path = full_path})
            return true
        end
    end
    parse = function(path, _chunks)
        chunks = _chunks
        parsed = {}
        queued_parse = {}
        for full_path,chunk in pairs(chunks) do
            if not parsed[full_path] and full_path:sub(1, #path) == path then
                local file = full_path:sub(#path + 1)
                if file:sub(1, 1) == "/" then
                    file = file:sub(2)
                end
                parsed[full_path] = true
                addChunk(path, chunk, file, full_path)
            end
        end
        while #queued_parse > 0 do
            local last_queued = queued_parse
            queued_parse = {}
            for _,v in ipairs(last_queued) do
                addChunk(v[1], v[2], v[3], v[4])
            end
            if #queued_parse == #last_queued then
                error("Couldn't find dependency in " .. path)
            end
        end
    end

    parse(base_path, self.base_scripts)
    if Mod then
        for _,lib in pairs(Mod.libs) do
            parse("scripts/"..base_path, lib.info.script_chunks)
        end
        parse("scripts/"..base_path, Mod.info.script_chunks)
    end

    CLASS_NAME_GETTER = DEFAULT_CLASS_NAME_GETTER

    local i = 0
---@diagnostic disable-next-line: undefined-field
    local n = table.getn(result)
    return function()
        i = i + 1
        if i <= n then
            local full_path = result[i].full_path
            if Mod then
                full_path = Mod.info.path.."/"..full_path
            end
            return full_path, result[i].path, unpack(result[i].out)
        end
    end
end

function Registry.iterMods(base_path)
    local result = {}

    local function parse(path, chunks)
        for full_path,chunk in pairs(chunks) do
            if full_path:sub(1, #path) == path then
                local id = full_path:sub(#path + 1)
                if id:sub(1, 1) == "/" then
                    id = id:sub(2)
                end
                local a, b = chunk()
                local func = a
                if type(a) == "string" then
                    id = a
                    func = b
                end
                table.insert(result, {id = id, func = func})
            end
        end
    end

    parse(base_path, self.base_scripts)
    if Mod then
        for _,lib in pairs(Mod.libs) do
            parse("scripts/"..base_path, lib.info.script_chunks)
        end
        parse("scripts/"..base_path, Mod.info.script_chunks)
    end

    local i = 0
---@diagnostic disable-next-line: undefined-field
    local n = table.getn(result)
    return function()
        i = i + 1
        if i <= n then
            return result[i].id, result[i].func
        end
    end
end

return Registry