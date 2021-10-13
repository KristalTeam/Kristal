local Mods = {}
local self = Mods

function Mods.clear()
    self.loaded = false
    self.list = {}
    self.data = {}
    self.named = {}
end

function Mods.loadData(data)
    for mod_id,mod_data in pairs(data) do
        if self.data[mod_id] then
            local old_mod = self.data[mod_id]
            if old_mod.name then
                self.named[old_mod.name] = nil
            end
            Utils.removeFromTable(self.list, old_mod)
        end

        -- convert image data into images
        if mod_data.preview_data then
            mod_data.preview = {}
            for _,img_data in ipairs(mod_data.preview_data) do
                table.insert(mod_data.preview, love.graphics.newImage(img_data))
            end
        end

        mod_data.script_chunks = {}
        for _,path in ipairs(Utils.getFilesRecursive(mod_data.path, ".lua")) do
            mod_data.script_chunks[path] = love.filesystem.load(mod_data.path.."/"..path..".lua")
        end

        self.data[mod_id] = mod_data
        if mod_data.name then
            self.named[mod_data.name] = mod_id
        end
        table.insert(self.list, self.data[mod_id])
    end
end

function Mods.getMods()
    return self.list
end

function Mods.getMod(id)
    return self.data[id] or (self.named[id] and self.data[self.named[id]])
end

function Mods.getName(id)
    return self.data[id].name or id
end

return Mods