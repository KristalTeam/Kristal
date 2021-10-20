local Registry = {}
local self = Registry

function Registry.clear()
    self.preloaded_mod = false
    self.characters = {}
end

function Registry.getCharacter(id)
    return self.characters[id]
end

function Registry.registerCharacter(id, tbl)
    if type(id) == "table" then
        tbl = id
        id = tbl.id
    end
    self.characters[id] = tbl
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
            Registry.registerCharacter(tbl.id or path, tbl)
        end
    end
    if pre then
        self.preloaded_mod = true
    end
end

return Registry