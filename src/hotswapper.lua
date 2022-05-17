local Hotswapper = {}

local enabled = true

local dir = love.filesystem.getDirectoryItems
local time = love.timer.getTime

Hotswapper.files = {
    required = {},
    registry = {}
}

function Hotswapper.updateFiles(file_type)
    if not enabled then return end
    if file_type == "required" then
        print("Updating file information for requried packages...")
        -- Loop through loaded packages
        for key, value in pairs(package.loaded) do
            local path = package.searchpath(key, package.path)
            if path then
                Hotswapper.files.required[key] = {
                    modified = Hotswapper.getLastModified(path),
                    path = path
                }
            end
        end
        print("Done")
    elseif file_type == "registry" then
        -- Loop through registry
        --[[local hotswappable = {
            "actors",
            "party_members",
            "items",
            "spells",
            "encounters",
            "enemies",
            "waves",
            "bullets",
            "world_bullets",
            "world_cutscenes",
            "battle_cutscenes",
            "map_data",
            "shops"
        }
        for _, hotswappable_type in ipairs(hotswappable) do
            print("LOOPING THROUGH REGISTRY: " .. hotswappable_type)
            for key, value in pairs(Registry[hotswappable_type]) do
                print(key)
                Hotswapper.files.registry[key] = {
                    modified = Hotswapper.getLastModified(Registry.paths[key])
                }
            end
        end]]--
    end
end

function Hotswapper.scan()
    if not enabled then return end
    --Hotswapper.updateFiles()
    for key, value in pairs(Hotswapper.files.required) do
        if Hotswapper.getLastModified(value.path) == false then return end
        if value.modified ~= Hotswapper.getLastModified(value.path) then
            value.modified = Hotswapper.getLastModified(value.path)
            print("Attempting to hotswap " .. key)
            --print(value.path)
            local updated_module, error_text = Hotswapper.hotswap(key)
            if not updated_module then
                print(error_text)
            end
        end
    end
end

function Hotswapper.parseModuleName(name)
    return (name:gsub("%.lua$", ""):gsub("[/\\]", "."))
end

function Hotswapper.getLastModified(path)
    if not path then return end
    path = path:gsub("^.\\", ""):gsub("\\", "/")
    local info = love.filesystem.getInfo(path, "file")
    if not info then
        print("Info is nil, disabling hotswapper...")
        return false
    end
    return info.modtime
end

function Hotswapper.hotswap(module_name)
    -- Grab the old _G
    local old_global_table = Utils.copy(_G)
    local updated = {}
    local function update(old, new)
        -- Prevent infinite recursion...
        if updated[old] then return end
        updated[old] = true

        -- Grab the old and new metatables
        local old_metatable = getmetatable(old)
        local new_metatable = getmetatable(new)
        -- If both metatables exist, update them as well
        if old_metatable and new_metatable then
            update(old_metatable, new_metatable)
        end
        -- Loop through the new table...
        for k, v in pairs(new) do
            if type(v) == "table" then
                -- If this value is a table, try to update it
                update(old[k], v)
            else
                -- This value isn't a table, so let's swap it
                old[k] = v
            end
        end
    end
    local err = nil
    local function onerror(e)
        for k in pairs(_G) do _G[k] = old_global_table[k] end
        err = e
    end
    local ok, old_module = pcall(require, module_name)
    old_module = ok and old_module or nil
    xpcall(function()
        -- Unload library
        package.loaded[module_name] = nil
        -- Require new version
        local new_module = require(module_name)
        -- If the new version is a table, then run update()
        if type(old_module) == "table" then update(old_module, new_module) end
        -- Loop through the old global table...
        for k, v in pairs(old_global_table) do
            -- If this value isn't the same as the current one, and it's a table...
            if v ~= _G[k] and type(v) == "table" then
                -- Update the old global table with the current values
                update(v, _G[k])
                -- And save it to the current global table
                _G[k] = v
            end
        end
    end, onerror)
    package.loaded[module_name] = old_module
    if err then return nil, err end
    return old_module
end

return Hotswapper