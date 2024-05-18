---@class Kristal.Mods
---
---@field loaded boolean
---@field list table[]
---@field data table<string, table>
---@field named table<string, string>
---@field failed_mods table[]
---
local Mods = {}
local self = Mods

-- TODO: Document mod data

function Mods.clear()
    self.loaded = false
    self.list = {}
    self.data = {}
    self.named = {}
    self.failed_mods = {}
end

---@param data table
---@param failed_mods table[]
function Mods.loadData(data, failed_mods)
    self.failed_mods = failed_mods or {}
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
        if mod_data.icon_data then
            mod_data.icon = {}
            for _,img_data in ipairs(mod_data.icon_data) do
                table.insert(mod_data.icon, love.graphics.newImage(img_data))
            end
        end
        if mod_data.logo_data then
            mod_data.logo = love.graphics.newImage(mod_data.logo_data)
        end

        mod_data.script_chunks = {}

        mod_data.libs = mod_data.libs or {}
        for _,lib_data in pairs(mod_data.libs) do
            lib_data.script_chunks = {}
        end

        if not mod_data.lib_order then
            mod_data.lib_order = self.sortLibraries(mod_data)
        end

        mod_data.loaded_scripts = false

        self.data[mod_id] = mod_data
        if mod_data.name then
            self.named[mod_data.name] = mod_id
        end
        table.insert(self.list, self.data[mod_id])
    end

    Input:loadBinds()
end

function Mods.sortLibraries(mod)
    local sorted = {}

    local unsorted = {}
    local sorted_lookup = {}

    for lib_id,_ in pairs(mod.libs) do
        table.insert(unsorted, lib_id)
    end

    while #unsorted > 0 do
        local new_unsorted = {}

        for _,lib_id in ipairs(unsorted) do
            local lib_data = mod.libs[lib_id]

            local failed = false

            for _,dependency in ipairs(lib_data["dependencies"] or {}) do
                if not sorted_lookup[dependency] then
                    failed = true
                    break
                end
            end

            for _,dependency in ipairs(lib_data["optionalDependencies"] or {}) do
                if mod.libs[dependency] and not sorted_lookup[dependency] then
                    failed = true
                    break
                end
            end

            if failed then
                table.insert(new_unsorted, lib_id)
            else
                table.insert(sorted, lib_id)
                sorted_lookup[lib_id] = true
            end
        end

        if #new_unsorted == #unsorted then
            for _,lib_id in ipairs(new_unsorted) do
                Kristal.Console:warn("Issue loading mod '" .. mod.id .. "' - Dependencies for library '" .. lib_id .. "' failed to load, likely circular dependency")

                table.insert(sorted, lib_id)
            end
            break
        end

        unsorted = new_unsorted
    end

    return sorted
end

---@return table[]
function Mods.getMods()
    return self.list or {}
end

---@param id string
---@return table
function Mods.getMod(id)
    return self.data[id] or (self.named[id] and self.data[self.named[id]])
end

---@param id string
---@return table
function Mods.getAndLoadMod(id)
    local mod = self.getMod(id)

    if not mod.loaded_scripts then
        for _,path in ipairs(Utils.getFilesRecursive(mod.path, ".lua")) do
            mod.script_chunks[path] = love.filesystem.load(mod.path.."/"..path..".lua")
        end

        for _,lib in pairs(mod.libs) do
            for _,path in ipairs(Utils.getFilesRecursive(lib.path, ".lua")) do
                lib.script_chunks[path] = love.filesystem.load(lib.path.."/"..path..".lua")
            end
        end

        mod.loaded_scripts = true
    end

    return mod
end

---@param id string
---@return string
function Mods.getName(id)
    return self.data[id].name or id
end

return Mods