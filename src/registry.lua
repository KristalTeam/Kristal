local Registry = {}
local self = Registry

function Registry.clear()
    self.preloaded_mod = false

    self.characters = {}
    self.encounters = {}
    self.enemies = {}
end

function Registry.getCharacter(id)
    return self.characters[id]
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

function Registry.registerCharacter(id, tbl)
    self.characters[id] = tbl
end

function Registry.registerEncounter(id, class)
    self.encounters[id] = class
end

function Registry.registerEnemy(id, class)
    self.enemies[id] = class
end

function Registry.registerDefaults()
    self.registerCharacter("kris", require("src.party.kris"))
    self.registerCharacter("ralsei", require("src.party.ralsei"))
    self.registerCharacter("susie", require("src.party.susie"))
end

function Registry.registerMod(mod, pre)
    for full_path,chunk in pairs(mod.script_chunks) do
        local split_path = Utils.split(full_path, "/")

        local dir = split_path[1]
        local path = Utils.join(split_path, "/", 2)
        
        if dir == "characters" and not self.preloaded_mod then
            local tbl = setfenv(chunk, mod.env)()
            self.registerCharacter(tbl.id or path, tbl)
        elseif dir == "battles" and not pre then
            local subdir = split_path[2]
            path = Utils.join(split_path, "/", 3)

            if subdir == "encounters" then
                local class = setfenv(chunk, mod.env)()
                class.id = class.id or path
                self.registerEncounter(class.id, class)
            elseif subdir == "enemies" then
                local class = setfenv(chunk, mod.env)()
                class.id = class.id or path
                self.registerEnemy(class.id, class)
            end
        end
    end
    if pre then
        self.preloaded_mod = true
    end
end

return Registry