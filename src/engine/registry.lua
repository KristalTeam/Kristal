local Registry = {}
local self = Registry

Registry.new_globals = {}
Registry.last_globals = {}

Registry.paths = {
    ["actors"]           = "data/actors",
    ["globals"]          = "globals",
    ["hooks"]            = "hooks",
    ["objects"]          = "objects",
    ["drawfx"]           = "drawfx",
    ["items"]            = "data/items",
    ["spells"]           = "data/spells",
    ["party_members"]    = "data/party",
    ["encounters"]       = "battle/encounters",
    ["enemies"]          = "battle/enemies",
    ["waves"]            = "battle/waves",
    ["bullets"]          = "battle/bullets",
    ["world_bullets"]    = "world/bullets",
    ["world_cutscenes"]  = "world/cutscenes",
    ["battle_cutscenes"] = "battle/cutscenes",
    ["event_scripts"]    = "world/scripts",
    ["tilesets"]         = "world/tilesets",
    ["maps"]             = "world/maps",
    ["events"]           = "world/events",
    ["controllers"]      = "world/controllers",
    ["shops"]            = "shops"
}

function Registry.initialize(preload)
    if not self.preload then
        self.base_scripts = {}

        local chapter = Kristal.getModOption("chapter") or 2
        Game.chapter = chapter

        for _,path in ipairs(Utils.getFilesRecursive("data", ".lua")) do
            local chunk = love.filesystem.load("data/"..path..".lua")
            self.base_scripts["data/"..path] = chunk
        end

        Registry.initActors()
    end
    if not preload then
        Registry.initGlobals()
        Registry.initObjects()
        Registry.initDrawFX()
        Registry.initItems()
        Registry.initSpells()
        Registry.initPartyMembers()
        Registry.initEncounters()
        Registry.initEnemies()
        Registry.initWaves()
        Registry.initBullets()
        Registry.initCutscenes()
        Registry.initEventScripts()
        Registry.initTilesets()
        Registry.initMaps()
        Registry.initEvents()
        Registry.initControllers()
        Registry.initShops()

        Kristal.callEvent("onRegistered")
    end

    self.preload = preload

    Hotswapper.updateFiles("registry")
end

function Registry.restoreOverridenGlobals()
    for id,_ in pairs(self.new_globals) do
        _G[id] = self.last_globals[id]
    end
    self.new_globals = {}
    self.last_globals = {}
end

-- Getter Functions --

function Registry.getObject(id)
    return self.objects[id]
end

function Registry.createObject(id, ...)
    if self.objects[id] then
        return self.objects[id](...)
    else
        error("Attempt to create non existent object \"" .. tostring(id) .. "\"")
    end
end

function Registry.getDrawFX(id)
    return self.draw_fx[id]
end

function Registry.createDrawFX(id, ...)
    if self.draw_fx[id] then
        return self.draw_fx[id](...)
    else
        error("Attempt to create non existent DrawFX \"" .. tostring(id) .. "\"")
    end
end

function Registry.getActor(id)
    return self.actors[id]
end

function Registry.createActor(id, ...)
    if self.actors[id] then
        return self.actors[id](...)
    else
        error("Attempt to create non existent actor \"" .. tostring(id) .. "\"")
    end
end

function Registry.getItem(id)
    return self.items[id]
end

function Registry.createItem(id, ...)
    if self.items[id] then
        return self.items[id](...)
    else
        error("Attempt to create non existent item \"" .. tostring(id) .. "\"")
    end
end

function Registry.getSpell(id)
    return self.spells[id]
end

function Registry.createSpell(id, ...)
    if self.spells[id] then
        return self.spells[id](...)
    else
        error("Attempt to create non existent spell \"" .. tostring(id) .. "\"")
    end
end

function Registry.getPartyMember(id)
    return self.party_members[id]
end

function Registry.createPartyMember(id, ...)
    if self.party_members[id] then
        return self.party_members[id](...)
    else
        error("Attempt to create non existent party member \"" .. tostring(id) .. "\"")
    end
end

function Registry.getEncounter(id)
    return self.encounters[id]
end

function Registry.createEncounter(id, ...)
    if self.encounters[id] then
        return self.encounters[id](...)
    else
        error("Attempt to create non existent encounter \"" .. tostring(id) .. "\"")
    end
end

function Registry.getEnemy(id)
    return self.enemies[id]
end

function Registry.createEnemy(id, ...)
    if self.enemies[id] then
        return self.enemies[id](...)
    else
        error("Attempt to create non existent enemy \"" .. tostring(id) .. "\"")
    end
end

function Registry.getWave(id)
    return self.waves[id]
end

function Registry.createWave(id, ...)
    if self.waves[id] then
        return self.waves[id](...)
    else
        error("Attempt to create non existent wave \"" .. tostring(id) .. "\"")
    end
end

function Registry.getBullet(id)
    return self.bullets[id]
end

function Registry.createBullet(id, ...)
    if self.bullets[id] then
        return self.bullets[id](...)
    else
        error("Attempt to create non existent bullet \"" .. tostring(id) .. "\"")
    end
end

function Registry.getWorldBullet(id)
    return self.world_bullets[id]
end

function Registry.createWorldBullet(id, ...)
    if self.world_bullets[id] then
        return self.world_bullets[id](...)
    else
        error("Attempt to create non existent world bullet \"" .. tostring(id) .. "\"")
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

function Registry.getEventScript(group, id)
    if not id then
        local args = Utils.split(group, ".")
        group = args[1]
        id = args[2]
    end
    local script = self.event_scripts[group]
    if type(script) == "table" then
        return script[id], true
    elseif type(script) == "function" then
        return script, false
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
        error("Attempt to create non existent map \"" .. tostring(id) .. "\"")
    end
end

function Registry.getMapData(id)
    return self.map_data[id]
end

function Registry.getEvent(id)
    return self.events[id]
end

function Registry.createEvent(id, ...)
    if self.events[id] then
        return self.events[id](...)
    else
        error("Attempt to create non existent event \"" .. tostring(id) .. "\"")
    end
end

function Registry.getController(id)
    return self.controllers[id]
end

function Registry.createController(id, ...)
    if self.controllers[id] then
        return self.controllers[id](...)
    else
        error("Attempt to create non existent controller \"" .. tostring(id) .. "\"")
    end
end

function Registry.getShop(id)
    return self.shops[id]
end

function Registry.createShop(id, ...)
    if self.shops[id] then
        return self.shops[id](...)
    else
        error("Attempt to create non existent shop \"" .. tostring(id) .. "\"")
    end
end

-- Register Functions --

function Registry.registerGlobal(id, value)
    if _G[id] then
        print("WARNING: Global '"..tostring(id).."' already exists, replacing")
        if not self.last_globals[id] and not self.new_globals[id] then
            self.last_globals[id] = _G[id]
        end
    end

    self.new_globals[id] = value

    _G[id] = value
end

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

function Registry.registerEventScript(id, script)
    self.event_scripts[id] = script
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

function Registry.registerEvent(id, class)
    self.events[id] = class
end

function Registry.registerController(id, class)
    self.controllers[id] = class
end

function Registry.registerShop(id, class)
    self.shops[id] = class
end

-- Internal Functions --

function Registry.initGlobals()
    for _,path,global in self.iterScripts(Registry.paths["globals"], true) do
        local id = type(global) == "table" and global.id or path

        self.registerGlobal(id, global)
    end

    Kristal.callEvent("onRegisterGlobals")
end

function Registry.initObjects()
    self.objects = {}

    for _,path,object in self.iterScripts(Registry.paths["hooks"], true) do
        assert(object ~= nil, '"hooks/'..path..'.lua" does not return value')
        local id = object.id or path

        self.objects[id] = object
        self.registerGlobal(id, object)
    end

    for _,path,object in self.iterScripts(Registry.paths["objects"], true) do
        assert(object ~= nil, '"objects/'..path..'.lua" does not return value')
        local id = object.id or path

        self.objects[id] = object
        self.registerGlobal(id, object)
    end

    Kristal.callEvent("onRegisterObjects")
end

function Registry.initDrawFX()
    self.draw_fx = {}

    for _,path,draw_fx in self.iterScripts(Registry.paths["drawfx"], true) do
        assert(draw_fx ~= nil, '"drawfx/'..path..'.lua" does not return value')
        local id = draw_fx.id or path

        self.draw_fx[id] = draw_fx
        self.registerGlobal(id, draw_fx)
    end

    Kristal.callEvent("onRegisterDrawFX")
end

function Registry.initActors()
    self.actors = {}

    for _,path,actor in self.iterScripts(Registry.paths["actors"]) do
        assert(actor ~= nil, '"actors/'..path..'.lua" does not return value')
        actor.id = actor.id or path
        self.registerActor(actor.id, actor)
    end

    Kristal.callEvent("onRegisterActors")
end

function Registry.initPartyMembers()
    self.party_members = {}

    for _,path,char in self.iterScripts(Registry.paths["party_members"]) do
        assert(char ~= nil, '"party/'..path..'.lua" does not return value')
        char.id = char.id or path
        self.registerPartyMember(char.id, char)
    end

    Kristal.callEvent("onRegisterPartyMembers")
end

function Registry.initItems()
    self.items = {}

    for _,path,item in self.iterScripts(Registry.paths["items"]) do
        assert(item ~= nil, '"items/'..path..'.lua" does not return value')
        item.id = item.id or path
        self.registerItem(item.id, item)
    end

    Kristal.callEvent("onRegisterItems")
end

function Registry.initSpells()
    self.spells = {}

    for _,path,spell in self.iterScripts(Registry.paths["spells"]) do
        assert(spell ~= nil, '"spells/'..path..'.lua" does not return value')
        spell.id = spell.id or path
        self.registerSpell(spell.id, spell)
    end

    Kristal.callEvent("onRegisterSpells")
end

function Registry.initEncounters()
    self.encounters = {}

    for _,path,encounter in self.iterScripts(Registry.paths["encounters"]) do
        assert(encounter ~= nil, '"encounters/'..path..'.lua" does not return value')
        encounter.id = encounter.id or path
        self.registerEncounter(encounter.id, encounter)
    end

    Kristal.callEvent("onRegisterEncounters")
end

function Registry.initEnemies()
    self.enemies = {}

    for _,path,enemy in self.iterScripts(Registry.paths["enemies"]) do
        assert(enemy ~= nil, '"enemies/'..path..'.lua" does not return value')
        enemy.id = enemy.id or path
        self.registerEnemy(enemy.id, enemy)
    end

    Kristal.callEvent("onRegisterEnemies")
end

function Registry.initWaves()
    self.waves = {}

    for _,path,wave in self.iterScripts(Registry.paths["waves"]) do
        assert(wave ~= nil, '"waves/'..path..'.lua" does not return value')
        wave.id = wave.id or path
        self.registerWave(wave.id, wave)
    end

    Kristal.callEvent("onRegisterWaves")
end

function Registry.initBullets()
    self.bullets = {}
    self.world_bullets = {}

    for _,path,bullet in self.iterScripts(Registry.paths["bullets"]) do
        assert(bullet ~= nil, '"battle/bullets/'..path..'.lua" does not return value')
        bullet.id = bullet.id or path
        self.registerBullet(bullet.id, bullet)
    end

    for _,path,bullet in self.iterScripts(Registry.paths["world_bullets"]) do
        assert(bullet ~= nil, '"world/bullets/'..path..'.lua" does not return value')
        bullet.id = bullet.id or path
        self.registerWorldBullet(bullet.id, bullet)
    end

    Kristal.callEvent("onRegisterBullets")
end

function Registry.initCutscenes()
    self.world_cutscenes = {}
    self.battle_cutscenes = {}

    for _,path,cutscene in self.iterScripts(Registry.paths["world_cutscenes"]) do
        assert(cutscene ~= nil, '"world/cutscenes/'..path..'.lua" does not return value')
        self.registerWorldCutscene(path, cutscene)
    end
    for _,path,cutscene in self.iterScripts(Registry.paths["battle_cutscenes"]) do
        assert(cutscene ~= nil, '"battle/cutscenes/'..path..'.lua" does not return value')
        self.registerBattleCutscene(path, cutscene)
    end

    Kristal.callEvent("onRegisterCutscenes")
end

function Registry.initEventScripts()
    self.event_scripts = {}

    for _,path,script in self.iterScripts(Registry.paths["event_scripts"]) do
        assert(script ~= nil, '"scripts/'..path..'.lua" does not return value')
        self.registerEventScript(path, script)
    end

    Kristal.callEvent("onRegisterEventScripts")
end

function Registry.initTilesets()
    self.tilesets = {}

    for full_path,path,data in self.iterScripts(Registry.paths["tilesets"]) do
        data.full_path = full_path
        data.id = path
        self.registerTileset(path, Tileset(data, full_path))
    end

    Kristal.callEvent("onRegisterTilesets")
end

function Registry.initMaps()
    self.maps = {}
    self.map_data = {}

    for full_path,path,data in self.iterScripts(Registry.paths["maps"]) do
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

function Registry.initEvents()
    self.events = {}

    for _,path,event in self.iterScripts(Registry.paths["events"]) do
        assert(event ~= nil, '"events/'..path..'.lua" does not return value')
        event.id = event.id or path
        self.registerEvent(event.id, event)
    end

    Kristal.callEvent("onRegisterEvents")
end

function Registry.initControllers()
    self.controllers = {}

    for _,path,controller in self.iterScripts(Registry.paths["controllers"]) do
        assert(controller ~= nil, '"controllers/'..path..'.lua" does not return value')
        controller.id = controller.id or path
        self.registerController(controller.id, controller)
    end

    Kristal.callEvent("onRegisterControllers")
end

function Registry.initShops()
    self.shops = {}

    for _,path,shop in self.iterScripts(Registry.paths["shops"]) do
        assert(shop ~= nil, '"shops/'..path..'.lua" does not return value')
        shop.id = shop.id or path
        self.registerShop(shop.id, shop)
    end

    Kristal.callEvent("onRegisterShops")
end

function Registry.iterScripts(base_path, exclude_folder)
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
            local result_path = file
            if exclude_folder then
                local split_path = Utils.split(file, "/", true)
                result_path = split_path[#split_path]
            end
            local id = type(a) == "table" and a.id or result_path
            table.insert(result, {out = {a,b,c,d,e,f}, path = result_path, id = id, full_path = full_path})
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
                local failed = {}
                for _,v in ipairs(last_queued) do
                    table.insert(failed, v[3])
                end
                error("Couldn't find dependency in " .. path .. " for " .. table.concat(failed, ", "))
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

return Registry